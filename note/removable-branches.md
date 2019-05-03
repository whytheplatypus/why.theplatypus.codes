---
title: "Removable Branches"
date: 2019-05-02T16:09:11-04:00
draft: true
---

Single purpose (single responsibility, signle reason to change)
```go
func (w *World) sayHello() string {
	return "hello"
}
```

Single purpose with conditional
```go
func (w *World) sayHello() string {
	if w.hello != "" {
		return w.hello
	}
	return "hello"
}
```
> say hello unless you have something else to say.

Same functionality but dual purpose
```go
func (w *World) sayHello() string {
	if w.hello != "" {
		return w.hello
	} else {
		return "hello"
	}
	return ""
}
```
> if you have something else to say, say it, if you don't, say "hello"

adding more conditionals
```go
func (w *World) sayHello() string {
	if w.hello != "" {
		return w.hello
	}
	if w.comment != "" {
		return w.comment
	}
	return "hello"
}
```
This remains
> say hello unless you have something else to say.

Same functionality but dual purpose
```go
func (w *World) sayHello() string {
	if w.hello != "" {
		return w.hello
	} else if w.comment != "" {
		return w.comment
	} else {
		return "hello"
	}
	return ""
}
```

> if you have something else to say, say it, if you have a comment, say it, if you don't, say "hello"

These pieces of code are all functionally the same. The "bad" one's however have some interesting traits. There is an unreachable `return ""` which means that the functions default behavior is not to say hello, but to say nothing. Modifying the code is also more complex as the writer has to take into account the other conditionals present. In the correct version a change can be self contained.

```go
func (w *World) sayHello() string {
	var greeting = "hello"
	if w.custom_greeting != "" {
		greeting = w.custom_greeting
	} else if w.suffix != "" {
		greeting += w.sufffix
	}
	return greeting
}
```

modification is essentially the same code as the good version, but we had more pain getting there.
cognitive diff is major (change in branching structure), text dif is is minor but structurally significant.

```go
func (w *World) sayHello() string {
	var greeting = "hello"
	if w.custom_greeting != "" {
		greeting = w.custom_greeting
	}
    
    if w.suffix != "" {
		greeting += w.sufffix
	}
	return greeting
}
```

```go
func (w *World) sayHello() string {
	var greeting = "hello"
	
	if w.custom_greeting != "" {
		return w.custom_greeting
	}
	
	if w.suffix != "" {
		return greeting + w.sufffix
	}
	
	return greeting
}
```

minimal logical change, cognitive diff is minimal, text diff is several characters
```go
func (w *World) sayHello() string {
	var greeting = "hello"
	
	if w.custom_greeting != "" {
		greeting = w.custom_greeting
	}
	
	if w.suffix != "" {
		return greeting + w.sufffix
	}

	return greeting
}
```