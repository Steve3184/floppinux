# floppinux: An Embedded 🐧Linux on a Single 💾Floppy

## Introduction

Floppinux is a Linux distribution designed to run on a single floppy disk. It is characterized by its small size, flexibility, and support for `udf` and `msdos` file systems.

## Features

- Small footprint: Floppinux occupies only 1.4M of space, making it suitable for older computers.
- Flexible customization: Customizable rootfs and streamlined Busybox.
- Built-in tools: Includes `hush` and `vi`, meeting basic user needs in a command-line environment.
- Mounting support: Supports mounting CD/DVD in UDF format and floppy disks in FAT format.
- Strong compatibility: Minimum support for `486SX` processor.

## Compilation

1. Ensure the necessary packages for compilation are installed:
   - `dosfstools` `syslinux` `make` `qemu-system-i386` (required for testing)
   - On Debian/Ubuntu, use the following command to install:
     ```shell
     sudo apt install -y dosfstools syslinux make qemu-system-i386
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
| `bzImage`        | 885K   |
| `ldlinux.c32`    | 117K   |
| `ldlinux.sys`    | 59K    |
| `rootfs.cpio.xz` | 171K   |
| `syslinux.cfg`   | 126B   |


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