# floppinux: An Embedded 🐧Linux on a Single 💾Floppy

## Introduction

Floppinux is a Linux distribution designed to run on a single floppy disk. It is characterized by its small size, flexibility, and support for `udf` and `msdos` file systems.

## Features

- Small footprint: Floppinux occupies only 1.4M of space, making it suitable for older computers.
- Flexible customization: Customizable rootfs and streamlined Busybox.
- Built-in tools: Includes `hush` and `vi`, meeting basic user needs in a command-line environment.
- Mounting support: Supports mounting CD/DVD in UDF format and floppy disks in FAT format.
- Strong compatibility: Minimum support for `486SX` processor and `sb16` sound card.

## Supported Internet Cards

- 3c509/3c579 "EtherLink III"
- 3c515 ISA "Fast EtherLink"
- 3c590/3c900 series (592/595/597) "Vortex/Boomerang"
- 3cr990 series "Typhoon"
- AMD 8111 (new PCI LANCE)
- AMD LANCE and PCnet (AT1500 and NE2100)
- AMD PCnet32 PCI
- Intel(R) PRO/100+
- Intel(R) PRO/1000 Gigabit Ethernet
- Intel(R) PRO/1000 PCI-Express Gigabit Ethernet
- Novell NE1000/NE2000 compatible ISA cards
- RealTek RTL-8139 C+ PCI Fast Ethernet Adapter
- RealTek RTL-8129/8130/8139 PCI Fast Ethernet Adapter
- Realtek 8169/8168/8101/8125 ethernet

## Compilation

1. Ensure the necessary packages for compilation are installed:
   - `dosfstools` `syslinux` `make` `build-essential` `nasm` `libc6-dev-i386` `qemu-system-i386` (required for testing)
   - On Debian/Ubuntu, use the following command to install:
     ```shell
     sudo apt install -y dosfstools syslinux make build-essential nasm libc6-dev-i386 qemu-system-i386
     ```
2. Clone this repository:
   ```shell
   git clone https://github.com/Steve3184/floppinux
   cd floppinux
   ```
3. Compile Floppinux using `make`:
   ```shell
   make all        # Full compilation
   make rebuild    # Re-compile busybox and rootfs after deleting previously compiled ones
   make clean      # Delete built bzImage, busybox, and rootfs
   make reset      # Reset (clear all content)
   make size       # Get size after compilation of floppinux.img
   ```
4. Test the generated image file (default saved as `floppinux.img`):
   - If you have a floppy disk, write it using dd:
     ```shell
     sudo dd if=floppinux.img of=/dev/fdX bs=1k count=1440
     ```
   - If you do not have a floppy disk or want to test it in qemu, use this to start qemu:
     ```shell
     make test_floppy_image
     ```
5. You can add files to overlay the rootfs under `configs/overlay/`, and compile after modification:
   ```shell
   make clean_filesystem rootfs
   ```

Compiled sizes:

| File              | Size   | 
|------------------|--------|
| `bzImage`        | 1.3M   |
| `ldlinux.sys`    | 32K    |
| `rootfs.cpio.xz` | 118K   |
| `syslinux.cfg`   | 126B   |
| `mod.dat`        | 1.1M   |
| `box.dat`        | 523K   |

## Networking

```shell
umount /mnt # Make sure no disk mounted on /mnt
# Insert 'floppinux-box.img'
mount -o ro /dev/fd1 /mnt
cd /mnt
loadbusybox
exit
# Press Enter
# Insert 'floppinux-mod.img'
umount /mnt
mount -o ro /dev/fd1 /mnt
cd /mnt
loadmod
cd /root
umount /mnt

modprobe pcnet32  # Install driver for VritualBox
modprobe snd-sb16 # Enable Sound
modprobe vfat     # Enable FAT32 Support
#modprobe ne2k-pci

/etc/init.d/02network start
# or
exit
# Press Enter
ifconfig
```

## Notes
If you are unable to access Github or the speed is slow, modify the URLs used for downloading in the Makefile:
```Makefile
# GIT Urls
LINUX_GIT   = Change to the Kernel Git mirror in your region, for example, for Chinese users:
                https://mirrors.tuna.tsinghua.edu.cn/git/linux.git
              Default:
                https://github.com/torvalds/linux.git
BUSYBOX_GIT = Change to the Busybox Git mirror in your region, for example, for Chinese users:
                https://gitee.com/Steve3184/busybox.git
              Default:
                https://github.com/mirror/busybox.git
CHECK_UPDATE = Whether to check for updates (yes/no), default is no
```