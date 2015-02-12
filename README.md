
Background
==========
* based on boot_btrfs_subvol (prototype 0.8)
* create very simple and fast btrfs subvolume snapshot boot environments

Benefits of Goal Setting
========================
* contrary to the linear rw snapshots under zfs (zfs clone), btrfs can create/delete nested snapshots (subvolume snapshots)

WARNING
=======
* dependents on the kernel version, btrfs-tools version, bugfixes and the use of serious functions such as balance, raid5, compression, etc. can delete the complex structures under some circumstances lead to data loss

Dependencies
============
* Linux (Debian)
   * machine with btrfs
   * dialog

Features
========
* create root subvolume snapshot and grub entry
* create nested subvolume snapshot environments
   * current support: 2 layer = 1 (ROOT/subvolume) + 1 (ROOT/subvolume/SUBROOT/subvolume)

Platform
========
* Linux (Debian 8/jessie)

Usage
=====
```
    WARNING: subvolboot2 is highly experimental and its not ready for production. Do it at your own risk.

    # usage: ./subvolboot2.sh { create | delete }
```

Diagram
=======
* boot_btrfs_subvol (prototype 0.8)
![plitc_debian8_luks_lvm_boot_btrfs_subvol](/content/plitc_debian8_luks_lvm_boot_btrfs_subvol.jpg)

* boot_btrfs_nested_subvol (prototype > 0.8)
![plitc_debian8_luks_lvm_boot_btrfs_nested_subvol](/content/plitc_debian8_luks_lvm_boot_btrfs_nested_subvol.jpg)

Screencast
==========
* btrfs / luks / lvm setup

[![plitc deb8 btrfs luks lvm setup](https://img.youtube.com/vi/uRvd0H_m7pY/0.jpg)](https://www.youtube.com/watch?v=uRvd0H_m7pY)

Errata
======
* 12.02.2015 - need lvm (logical volume) name "-system" (FIXED)
* 11.02.2015 - parsing error after minute swap (FIXED)

