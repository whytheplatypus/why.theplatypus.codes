---
title: "How the Platypus Built an Arch"
date: 2017-12-26T12:28:00-04:00
draft: false
tags:
- Arch Linux
---

One evening the platypus was in his workshop tinkering with a new piece
of code. As the evening wore on and the code grew the platypus started
to think about the code's future. Who would use it? Where would it live?
He knew that only he would use the code, it was just a silly personal
project after all, but to his dismay he did not know where it could
live. The clouds were where most code lived, but the clouds were
expensive and far away, it didn't make sense for this code to live
there. "What if there was a small cloud," he thought, "close to home,
that was cheap ([like the
budgie](http://www.imdb.com/title/tt0120735/))?" Well, then the code
could live in a cloud.

The platypus knew that even his small cloud would have to be high up.
Looking around the workshop the platypus spotted an old tower, but the
tower didn't have any structure. There was nothing the platypus could
put the pieces of a cloud on.

"I will build an arch on the tower," the platypus thought, "then the
cloud can sit on the arch."

[Partitioning](https://wiki.archlinux.org/index.php/Installation_guide#Partition_the_disks)
-------------------------------------------------------------------------------------------

For this arch the platypus built two partitions one to boot, one to run.
Boot was
[small](https://wiki.archlinux.org/index.php/partitioning#.2Fboot), and
[fat](https://wiki.archlinux.org/index.php/syslinux). The one to run,
the Root, was big and
[extendable](https://wiki.archlinux.org/index.php/ext4).

    parted /dev/sdx
    mkpart primary fat32 1MiB 513MiB
    mkpart primary ext4 513MiB 100%

> It may also be necessary to explicitly [format the
> partitions](https://wiki.archlinux.org/index.php/Installation_guide#Format_the_partitions).
> `mkfs.vfat -F 32 /dev/sdxx` and `mkfs.ext4 /dev/sdxy` should do it.
> Installing `dosfstools` might be required for `mkfs.vfat`.

[Mounting](https://wiki.archlinux.org/index.php/Installation_guide#Mount_the_file_systems)
------------------------------------------------------------------------------------------

Starting work, the platypus placed the Root of the new arch on his
workbench. [Which was also an
arch](https://wiki.archlinux.org/index.php/Install_from_existing_Linux#From_a_host_running_Arch_Linux).

    sudo mount /dev/sdxx /mnt

The Boot was placed on top of the Root.

    sudo mkdir /mnt/boot
    sudo mount /dev/sdxy /mnt/boot

Construction
------------

Then the platypus got out all of his arch building tools.

    pacman -S arch-install-scripts

One tool, `pacstrap`, allowed the platypus to [put more
structure](https://wiki.archlinux.org/index.php/Installation_guide#Install_the_base_packages)
into the new arch. He put the `base` in.

    pacstrap /mnt base

He wanted to be able to write on the arch.

    pacstrap /mnt vim

And talk to it from afar.

    pacstrap /mnt openssh

He also wanted others to be able to find the arch.

    pacstrap /mnt avahi nss-mdns

Next the platypus put down some
[scaffolding](https://wiki.archlinux.org/index.php/Installation_guide#Fstab)
that the arch would need to support other things once it was done.

    sudo sh -c 'genfstab -U /mnt >> /mnt/etc/fstab'

Configure
---------

[Working
inside](https://wiki.archlinux.org/index.php/Installation_guide#Chroot)
the newly constructed arch

    arch-chroot /mnt

The platypus [set the
time](https://wiki.archlinux.org/index.php/Installation_guide#Time_zone),

    ln -sf /usr/share/zoneinfo/Region/City /etc/localtime
    hwclock --systohc

set the [local
language](https://wiki.archlinux.org/index.php/Installation_guide#Locale),

    # uncomment languages in `/etc/locale.gen`

    locale-gen

    echo LANG=en_US.UTF-8 >> /etc/locale.conf

[named](https://wiki.archlinux.org/index.php/Installation_guide#Hostname)
the arch,

    echo myhostname >> /etc/hostname

and set up some [minimal
fortifications](https://wiki.archlinux.org/index.php/Installation_guide#Root_password).

    passwd

Next, knowing that he wanted to be able to reach the new arch, he made
sure it was
[accessible](https://wiki.archlinux.org/index.php/Secure_Shell#Daemon_management)

    systemctl enable sshd.socket

> if you need to permit root login open `/etc/ssh/sshd_config`, comment
> out `PermitRootLogin without-password` to allow root login with a
> password, then add or uncomment the line `PermitRootLogin yes` to
> allow `root` to login at all.

and that he could [find it from a
distance](https://wiki.archlinux.org/index.php/avahi#Installation).

    systemctl enable avahi-daemon.service

[Booting](https://wiki.archlinux.org/index.php/Installation_guide#Boot_loader)
------------------------------------------------------------------------------

The new arch was almost ready. All that was left was to tell the new
arch
[how](https://wiki.archlinux.org/index.php/syslinux#Automatic_Install)
to get itself
[started](https://wiki.archlinux.org/index.php/Installing_Arch_Linux_on_a_USB_key#Syslinux).

    pacman -S syslinux gptfdisk mtools
    syslinux-install_update  -i -a -m

> If there are any problems finding the root device when booting check
> the order of the
> [hooks](https://superuser.com/questions/769047/unable-to-find-root-device-on-a-fresh-archlinux-install).
> The `HOOKS` in `/etc/mkinitcpio.conf` should looks something like
> `HOOKS="base udev block autodetect modconf filesystems keyboard fsck"`
> note `block` coming before `autodetect`. If you make any changes run
> `mkinitcpio -p linux` to make them stick.

The platypus stepped back from his workbench. The new arch was ready.
