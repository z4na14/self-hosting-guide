# Index

1. Introduction
2. Debian installation
    1. SSH
    2. RAID
        1. Differences between the RAID types
        2. Setting up RAID array
    3. Static IP
3. Docker
    1. Installation
        1. Docker CE
        2. Portainer
    2. Basics of Docker

&nbsp;

# 1. Introduction

Seeing all these people on the internet talk about their home labs, and how much they've learned, made me consider doing the investment into one for myself. I needed something into the small factor, a computer I could leave under the TV in my living room, that would not bother anyone at home. Then I found the Dell Wyse line of products, that had enough power to run everything I required, and without doing any noise, as it was fanless.

At the beginning I installed Proxmox, as it was the most straightforward option for a server, but taking into account that I didn't really need containers, nor virtual machines, due to still using docker in each container, I ended up installing plain Debian.

I'm writing this guide to pave the path for your first homelab, or at least giving you an idea of what I have done in mine.

&nbsp;

# 2. Debian installation

Just download the latest ISO from the [Debian site](https://www.debian.org/distrib/) (Download the complete version, as the net one might not work due to network drivers incompatibilities), burn it onto an empty USB, and select the drive from the BIOS. Multiple utilities can be used for flashing:

- [Caligula](https://github.com/ifd3f/caligula): Linux TUI imager.
- [ISO Image Writer](https://apps.kde.org/es/isoimagewriter/): Linux / Windows KDE imager.
- [Rufus](https://rufus.ie/): Windows imager.

After that, just follow the Calamares installation, and when you reach the packages to be installed **unselect the "Debian Desktop Environment"** or related. This will leave us a headless machine to work with. Finally, restart the computer, and log into it with the configured user.

&nbsp;

&nbsp;

## SSH

The first step before abandoning the server on a corner of the house, is setting up a way to connect to it remotely. Everything you need to know, will be listed in the Debian [documentation for SSH](https://wiki.debian.org/SSH), but for the sake of simplicity, the basic steps will be listed here.

First of all, if you didn't select the SSH option when installing Debian, you first need to run:

```bash
sudo apt install openssh-server
```

Then, check that the SSH daemon is running using:

```bash
systemctl status ssh
```

If it returns running, then everything is correct. Otherwise, just start it using:

```bash
sudo systemctl enable --now ssh
```

A good practice for an SSH server, is protecting the access using shared keys, but since the server will only be available inside our home network (More on how to access it from outside, in the WGEasy section), with the password protection will be more than enough.

While on Linux OpenSSH comes preisntalled with most machines, on Windows is not activated by default. Therefore, to be able to connect to the server, it must be installed from "System -> Optional features" section inside the Windows configuration. After that, the client machine should be ready to go. To connect to the server, just run:

```bash
ssh your_user@machine_ip
```

And enter your password in the next prompt.

Before continuing reading this guide, **install [fail2ban](https://github.com/fail2ban/fail2ban) in your machine**. It literally just needs to be installed for it to work:

```
apt install fail2ban
```

The whole documentation is available in their GitHub repo, but it boils down to banning IPs that try to brute force your password, or floods your server with log requests. It is "mandatory" for both password and certificate set-ups, so just install it in the machine before anything else.

&nbsp;

### Activating certificate log-in

On my own setup, I got my SSH keys stored inside my KeePassXC vault, so it's convenient and easier to manage, but those can also be kept locally on the computer. The problem with using keys is that, you will need them whenever you want to SSH into the server. If this is not a problem, and you want some peace of mind knowing no one can access your files, then there are a few steps to do.

First, generate the keys using:

```bash
ssh-keygen
```

Now you will have two new files:

- `keyname`
- `keyname.pub`

`keyname` (with no extension) is the private key, used to authenticate yourself to the server. Think of it like your home keys. Then, `keyname.pub` is the lock that is opened with the former file, with which the server checks that you are authorized to open a TTY on the server.

To add this identity to the server:

```bash
ssh-copy-id user@hostname
```

If the command is not available in your distribution, then:

```bash
scp keyname.pub user@hostname:.ssh/keyname.pub
```

Which just copies over SSH the key.

Your pair of keys must be stored in `~/.ssh`, so don't forget to move them there if you didn't do it already.

&nbsp;

&nbsp;

## Static IP

Setting up an static IP for my sever bugged me from the first day I began using it. After running a bunch of services using docker (pihole, jellyfin, etc.), the IP of those would change along with my server when there was a power outage, due to the routers DHCP.

Moreover, when I began using PiHole's DHCP, after restarting the server, my whole network would not have internet, as no device would be assigned an IP automatically.

Therefore, to assign the server an static IP, and to not rely on the router, we will edit `/etc/network/interfaces`, and add:

```bash
# This file describes the network interfaces available on your system
# and how to activate them. For more information, see interfaces(5).

source /etc/network/interfaces.d/*

# The loopback network interface
auto lo
iface lo inet loopback

# The primary network interface
# This is an autoconfigured IPv4 interface
allow-hotplug enp4s0
iface enp4s0 inet dhcp
fallback static
iface enp4s0 inet static
        address 192.168.1.15 # HERE YOUR STATIC IP
        netmask 255.255.255.0
        gateway 192.168.1.1 # ROUTER IP
        dns-nameservers 1.1.1.1 8.8.8.8 # FALLBACK DNS SERVERS
```

Now, whenever the server is restarted, the same IP will be assigned to it.

&nbsp;

&nbsp;

## RAID

RAID (Redundant Array of Independent Disks) is a storage technology that combines multiples drives into a single independent one. Most of the server setups out there use it to create disk arrays with all their data on it. There are multiple standard levels that you might be interested in, and everything is well documented in the [Arch Wiki](https://wiki.archlinux.org/title/RAID). If you just want to use a few old drives and ensemble them into a single storage medium, then you want RAID 0.

> [!WARNING]
> Disks could be different, but the usable size for all of them will reduce to the smallest one. For example, if you want to use a 350GB, 500GB and 1TB, the usable size for each one in the array will be 350GB. This is due to how RAID works. If you try to create multiple partitions on the bigger drives, it will impact performance significantly, as the disk driver will be the same, and it will have to answer to multiple read and writes at the same time.

RAID 0 does just that, combines multiple drives into a single one, adding their storage capacity. The problem with it, is that there is no redundancy between the disks, meaning that if one of them fails, data will be lost, so have backups of all important data ready. There is a simple rule for this, if you downloaded something from the internet, even if you loose it, you will be able to find it again somewhere, so don't sweat loosing those 2TB of movies that you downloaded.

&nbsp;

### Creating array

Anyways, to create a RAID 0 array, first you need to identify the disks that you are going to use:

```bash
lsblk
...
NAME   MAJ:MIN RM   SIZE RO TYPE  MOUNTPOINTS
sda      8:0    0  59,6G  0 disk
├─sda1   8:1    0   512M  0 part  /boot/efi
├─sda2   8:2    0  58,2G  0 part  /
└─sda3   8:3    0   977M  0 part  [SWAP]
sdb      8:16   0 894,3G  0 disk
└─md0    9:0    0   1,7T  0 raid0 /mnt/md0
sdc      8:32   0 894,3G  0 disk
└─md0    9:0    0   1,7T  0 raid0 /mnt/md0
```

As I already have my array created, you will see them formatted as `md0`, but the disks appear as `sdb` and `sdc`. Names might be different, but those are the ones that you will need.

To create the array:

```bash
sudo mdadm --create --verbose /dev/md0 --level=0 --raid-devices=2 /dev/sda /dev/sdb
```

- `/dev/md0`: Virtual device with the array.

Modify the command accordingly, and then check if the array was succesfuly created:

```bash
cat /proc/mdstat
...
Personalities : [raid0] [linear] [multipath] [raid1] [raid6] [raid5] [raid4] [raid10]
md0 : active raid0 sdc[1] sdb[0]
      1875120128 blocks super 1.2 512k chunks

unused devices: <none>
```

&nbsp;

### Creating filesystem

Finally, we will create a new filesystem on the device:

```bash
sudo mkfs.ext4 -F /dev/md0
```

Then create a mount point to attach the new filesystem:

```bash
sudo mkdir -p /mnt/md0
```

And attach the device to the mountpoint:

```bash
sudo mount /dev/md0 /mnt/md0
```

&nbsp;

### Mounting automatically at boot

To make the array configuration persisten, we will need to add it to `mdadm.conf`:

```bash
sudo mdadm --detail --scan --verbose | sudo tee -a /etc/mdadm/mdadm.conf
```

Without this, the array won't be available after a reboot. Finally, to mount the array automatically at boot, we will add it to `/etc/fstab`.

First check the UUID of the array:

```bash
sudo blkid
...
/dev/md0: UUID="d72765ee-e0c4-457a-9fe1-c6ddc01fa683" BLOCK_SIZE="4096" TYPE="ext4"
```

Then edit `/etc/fstab`, with for example, `sudo nano /etc/fstab`, and add to the end of the file a line like:

```
UUID="d72765ee-e0c4-457a-9fe1-c6ddc01fa683" /mnt/md0 ext4 defaults 0 0
```

After saving the file, the array will persist for reboots or updates.

&nbsp;

# 3. Docker

All the docker compose files that I use (at least most of them) will be available in the GitHub repo.

&nbsp;

&nbsp;

## Installation

&nbsp;

&nbsp;

## Basics of Docker
