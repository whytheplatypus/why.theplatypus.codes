---
title: "Switchboard"
project_url: https://github.com/artistedev/switchboard
date: 2020-02-17T14:58:43-05:00
categories:
- Weekend Knitting
tags:
- go
- raspberrypi
- reverse proxy
- mDNS
madlibs:
- Some
- weekend knitting
- involving
---

## The problem
Sometimes I build little things that have a web componant.
It might be a webiste or an API, the usual suspects.
As much as it scares me sometimes I also think that these things should run for real and be treated as real, if small, products in order to take them serisiously myself.
The final piece to the puzzle is my own laziness.
The cloud is a fine place to host things.
AWS, Google Cloud, Linnode make it easy.
Terraform makes it even easier.
But I'm very lazy,
I have a perfectly good internet connection,
I own a few domains,
and I have an abundance of rasperry pis that I have no idea what to do with.

## The plan

Build a system (I called it `switchboard`) that I can point web traffic to from my home router that will then forward it on to my little projects.
Again I'm lazy, so once it's running I never want to touch `switchboard`. 
Since it's for my local home network mDNS works fine and can be leveraged by the little projects to tell the `switchboard` what to send their way.

I'm going to use `go` for three reasons:

1. It's standard library. In this particular case the ability to make a reverse proxy in one clear line of code: [`NewSingleHostReverseProxy`](https://golang.org/pkg/net/http/httputil/#NewSingleHostReverseProxy)
2. Building for the raspberry pi is easy: `env GOOS=linux GOARCH=arm GOARM=5 go build`
3. There's an mDNS library that I trust [hashicorp/mdns](https://github.com/hashicorp/mdns)

## Nuts and Bolts

### Broadcasting to mDNS
```
func Hookup(pattern string, port int) *mdns.Server {
```
This is going to let the world know that requests matching `pattern` should be send to _this_ box on `port`.
```
	// Setup our service export
	host, _ := os.Hostname()
	info := []string{pattern}
	service, _ := mdns.NewMDNSService(
		host,
		fmt.Sprintf("%s", config.ServiceName),
		"",
		"",
		port,
		nil,
		info,
	)

	// Create the mDNS server, defer shutdown
	server, _ := mdns.NewServer(&mdns.Config{Zone: service})
	return server
}
```
Yup, that's it... sort of, see the repo for handling shutdown (basically you just tell it to shutdown).

### Listening to mDNS
```
func Listen(ctx context.Context) {
	ticker := time.NewTicker(5 * time.Second)
	defer ticker.Stop()
```
This `ticker` sends a message across it's channel, `ticker.C`, every 5 seconds.
```
	// Make a channel for results and start listening
	entries := make(chan *mdns.ServiceEntry, 5)
```
A channel `entries` is created to act as a queue of mdns service entries that `switchboard` has seen that might require it's attention.
```

	// Start the lookup
	go func(entries chan *mdns.ServiceEntry) {
```
A thread handles watching the network for service entries.
```
		defer close(entries)
		defer fmt.Println("Done listening")
		for {
			select {
			case <-ctx.Done():
				return
```
That thread ends if the context is closed.
```
			case <-ticker.C:
				mdns.Lookup(fmt.Sprintf("%s", config.ServiceName), entries)
```
`switchboard` checks in with the local network regularly to see if anyone is publishing a mDNS record that it should pay attention to.
```
			}
		}
	}(entries)
	for entry := range entries {
		fmt.Printf("Got new entry: %+v\n", entry)
		Connect(entry)
	}
```
Anything on the queue is looked at to see if it should be registered for forwarding.
```
}
```

### Updating patterns on a ServMux
```
func Connect(entry *mdns.ServiceEntry) {
	if existing, ok := registry[entry.InfoFields[0]]; ok {
		if existing.AddrV4.Equal(entry.AddrV4) && existing.Port == entry.Port {
			return
		}
		*Phonebook = http.ServeMux{}
		delete(registry, entry.InfoFields[0])
		for _, ent := range registry {
			register(ent)
		}
```
In order for `switchboard` to update it's routes while continuing to use the deafult `ServeMux`
it was nessisary to swap out the `ServeMux` entirely.
```
	}
	register(entry)
}
```

### Registering patterns with a ServMux
```
func register(entry *mdns.ServiceEntry) {
	if !strings.Contains(entry.Name, config.ServiceName) {
		fmt.Println("unknown entry")
		return
	}
```
Some entries were coming through from other devices in the house.
`switchboard` could probably be more picky in it's lookup,
but "trust but verify" is a good rule to live by anyway.
So if the entry doesn't look familiar, drop it.
```
	if _, ok := registry[entry.InfoFields[0]]; ok {
		return
	}
```
`switchboard` keeps track of the patterns it's seen because the [`http`](https://golang.org/pkg/net/http/) default `ServeMux` panics if you try and tell it what to do with a pattern more than once. 
```
	u, _ := url.Parse(fmt.Sprintf("http://%s:%d", entry.AddrV4, entry.Port))
	rp := httputil.NewSingleHostReverseProxy(u)
	Phonebook.Handle(entry.InfoFields[0], rp)
	registry[entry.InfoFields[0]] = entry
}
```

### Handling tls
```
func (s *server) serve(ctx context.Context) error {

	srv := &http.Server{
		Addr:    s.Addr,
		Handler: s.Handler,
	}

	if s.CertDir != "" && len(s.Domains) > 0 {
		m := &autocert.Manager{
			Prompt: autocert.AcceptTOS,
		}

		m.HostPolicy = autocert.HostWhitelist(s.Domains...)

		if err := os.MkdirAll(s.CertDir, os.ModePerm); err != nil {
			return err
		}
		m.Cache = autocert.DirCache(s.CertDir)
		srv.Handler = m.HTTPHandler(nil)
```
Replaces the origional servers handler with one that helps manage tls.
```

		crtSrv := &http.Server{
			Handler: s.Handler,
		}
```
This is a tls server, and the one that should be handling traffic.
```
		//TODO return errors
		go crtSrv.Serve(m.Listener())
		defer crtSrv.Shutdown(context.Background())
	}

	//TODO return errors
	go srv.ListenAndServe()
	<-ctx.Done()
	//TODO return errors
	srv.Shutdown(context.Background())
	return nil
}
```

