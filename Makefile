# Config Variables
TARGET_ARCH			= x86
LINUX_DIR		= linux
CFG_DIR			= $(BASE)/configs
LINUX_CFG		= $(CFG_DIR)/linux.config
BUSYBOX_DIR		= busybox
BUSYBOX_CFG		= $(CFG_DIR)/busybox.config
SYSLINUX_CFG	= $(CFG_DIR)/syslinux.cfg
MOUNT_POINT		= $(BASE)/disk
FS_DIR			= $(BASE)/filesystem
OVERLAY_DIR		= $(CFG_DIR)/overlay
TOOLCHAIN_NAME	= i486-linux-musl

# Generated Files
ROOTFS			= rootfs.cpio.xz
FSIMAGE			= floppinux.img

# Detected Variables
CORES := $(shell nproc)
BASE := $(shell pwd)
ARCH := $(shell uname -p)

# GIT Urls
#LINUX_GIT		= https://mirrors.tuna.tsinghua.edu.cn/git/linux.git
LINUX_GIT		= https://github.com/torvalds/linux.git
#BUSYBOX_GIT		= https://gitee.com/Steve3184/busybox.git
BUSYBOX_GIT		= https://github.com/mirror/busybox.git
CHECK_UPDATE	= no

.SLIENT: get_toolchain
.PHONY: all rebuild clean reset size

all: get_sources get_toolchain compile_linux compile_busybox rootfs floppy_image
rebuild: clean_filesystem clean_busybox compile_linux compile_busybox rootfs floppy_image
clean: clean_linux clean_busybox clean_filesystem

clean_linux:
	$(MAKE) -C $(LINUX_DIR) clean
	rm -f $(KERNEL)

clean_busybox:
	$(MAKE) -C $(BUSYBOX_DIR) clean

clean_filesystem:
	sudo rm -rf filesystem
	rm $(FSIMAGE) $(ROOTFS)

reset: clean_filesystem
	sudo rm -rf $(LINUX_DIR) $(BUSYBOX_DIR) $(TOOLCHAIN_DIR)

get_sources:
ifneq ($(wildcard $(LINUX_DIR)),)
ifeq ($(CHECK_UPDATE),"yes")
	@echo "Linux directory found, pulling latest changes..."
	cd $(LINUX_DIR) && git pull
else
	@echo "Linux directory found, skipping pull latest changes..."
endif
else
	@echo "Linux directory not found, cloning repo..."
	git clone --depth=1 $(LINUX_GIT) $(LINUX_DIR)
endif
ifneq ($(wildcard $(BUSYBOX_DIR)),)
ifeq ($(CHECK_UPDATE),"yes")
	@echo "Busybox directory found, pulling latest changes..."
	cd $(BUSYBOX_DIR) && git pull
else
	@echo "Busybox directory found, skipping pull latest changes..."
endif
else
	@echo "Busybox directory not found, cloning repo..."
	git clone $(BUSYBOX_GIT) $(BUSYBOX_DIR)
endif

get_toolchain:
ifeq ($(ARCH),x86_64)
	if [ ! -d $(BASE)/$(TOOLCHAIN_NAME)-cross ]; then \
	echo "Downloading musl toolchain..."; \
	wget https://musl.cc/$(TOOLCHAIN_NAME)-cross.tgz; \
	tar xf $(TOOLCHAIN_NAME)-cross.tgz; \
	fi
else
	echo "Compiling on i386, toolchain not needed"
endif

compile_linux:
	@-cp $(LINUX_CFG) $(LINUX_DIR)/.config
ifeq ($(ARCH),x86_64)
	PATH="$$PATH:$(BASE)/$(TOOLCHAIN_NAME)-cross/bin" $(MAKE) ARCH=x86 CROSS_COMPILE=$(TOOLCHAIN_NAME)- -C $(LINUX_DIR) -j$(CORES) bzImage
else
	$(MAKE) ARCH=x86 -C $(LINUX_DIR) -j$(CORES) bzImage
endif
	@echo Kernel size:
	ls -lh $(LINUX_DIR)/arch/$(TARGET_ARCH)/boot/bzImage
	cp $(LINUX_DIR)/arch/$(TARGET_ARCH)/boot/bzImage .

compile_busybox:
	@-cp $(BUSYBOX_CFG) $(BUSYBOX_DIR)/.config
ifeq ($(ARCH),x86_64)
	@sed -i "s|.*CONFIG_CROSS_COMPILER_PREFIX.*|CONFIG_CROSS_COMPILER_PREFIX="\"$(BASE)"/$(TOOLCHAIN_NAME)-cross/bin/i486-linux-musl-\"|" $(BUSYBOX_DIR)/.config
	@sed -i "s|.*CONFIG_SYSROOT.*|CONFIG_SYSROOT=\""$(BASE)"/$(TOOLCHAIN_NAME)-cross\"|" $(BUSYBOX_DIR)/.config
	@sed -i "s|.*CONFIG_EXTRA_CFLAGS.*|CONFIG_EXTRA_CFLAGS=\"-I"$(BASE)"/$(TOOLCHAIN_NAME)-cross/include\"|" $(BUSYBOX_DIR)/.config
	@sed -i "s|.*CONFIG_EXTRA_LDFLAGS.*|CONFIG_EXTRA_LDFLAGS=\"-L"$(BASE)"/$(TOOLCHAIN_NAME)-cross/lib\"|" $(BUSYBOX_DIR)/.config
	PATH="$$PATH:$(BASE)/$(TOOLCHAIN_NAME)-cross/bin" $(MAKE) ARCH=x86 CROSS_COMPILE=i486-linux-musl- -C $(BUSYBOX_DIR) -j$(CORES)
endif
	$(MAKE) ARCH=x86 -C $(BUSYBOX_DIR) -j$(CORES)
	$(MAKE) ARCH=x86 -C $(BUSYBOX_DIR) install

rootfs:
	sudo mkdir -p $(FS_DIR)/{dev/pts,proc,etc/init.d,sys,tmp,boot}
	sudo cp -dpRf $(BUSYBOX_DIR)/_install/* $(FS_DIR)/
	sudo mv -f $(FS_DIR)/linuxrc $(FS_DIR)/init
	-sudo mknod $(FS_DIR)/dev/console c 5 1
	-sudo mknod $(FS_DIR)/dev/null c 1 3
	sudo cp -dpRf $(OVERLAY_DIR)/* $(FS_DIR)/
	chmod +x $(FS_DIR)/etc/init.d/rc
	sudo chown -R root:root $(FS_DIR)/
	cd $(FS_DIR); find . | cpio -H newc -o | xz -7e --check=crc32 > ../$(ROOTFS)
	ls -lh $(ROOTFS)

floppy_image:
	@command -v mkdosfs >/dev/null 2>&1 || { echo >&2 "dosfstools is not installed. Aborting."; exit 1; }
	@command -v syslinux >/dev/null 2>&1 || { echo >&2 "syslinux is not installed. Aborting."; exit 1; }
	dd if=/dev/zero of=$(FSIMAGE) bs=1k count=1440
	mkdosfs $(FSIMAGE)
	syslinux --install $(FSIMAGE)
	sudo mkdir -p $(MOUNT_POINT)
	@-sudo umount $(MOUNT_POINT)
	sudo mount -o loop $(FSIMAGE) $(MOUNT_POINT)
	sudo cp bzImage $(ROOTFS) $(SYSLINUX_CFG) $(MOUNT_POINT)/
	@ls -lh $(MOUNT_POINT)
	sync
	sudo umount $(MOUNT_POINT)
	@sudo chmod 777 $(FSIMAGE)

test_rootfs:
	@command -v qemu-system-i386 >/dev/null 2>&1 || { echo >&2 "qemu-system-i386 is not installed. Aborting."; exit 1; }
	qemu-system-i386 -kernel bzImage -initrd $(ROOTFS) -m 32

test_floppy_image:
	@command -v qemu-system-i386 >/dev/null 2>&1 || { echo >&2 "qemu-system-i386 is not installed. Aborting."; exit 1; }
	qemu-system-i386 -fda $(FSIMAGE) -m 32

size:
	@-sudo umount $(MOUNT_POINT)
	@sudo mount -o loop $(FSIMAGE) $(MOUNT_POINT)
	@df -h $(MOUNT_POINT)
	@ls -lh $(MOUNT_POINT)
	@sleep 1
	@sudo umount $(MOUNT_POINT)
