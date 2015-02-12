
Background
==========
create very simple and fast btrfs subvolume snapshot boot environments

Dependencies
============
* Linux (Debian)
   * machine with btrfs
   * need lvm (logical volume) name "-system"
   * dialog

Features
========
* create root subvolume snapshot and grub entry

Platform
========
* Linux (Debian 8/jessie)

Usage
=====
```
    WARNING: subvolboot is highly experimental and its not ready for production. Do it at your own risk.

    # usage: ./subvolboot.sh { create | delete }
```

Diagram
=======
![plitc_debian8_luks_lvm_boot_btrfs_subvol](/content/plitc_debian8_luks_lvm_boot_btrfs_subvol.jpg)

Screencast
==========
[![plitc deb8 btrfs luks lvm setup](https://img.youtube.com/vi/uRvd0H_m7pY/0.jpg)](https://www.youtube.com/watch?v=uRvd0H_m7pY)

Errata
======
* 11.02.2015 - parsing error after minute swap

