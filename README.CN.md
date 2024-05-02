# floppinux: 一个嵌入式的 🐧Linux 在单张 💾软盘 上

## 介绍

Floppinux 是一个致力于在单张软盘上运行的 Linux 发行版,其特点是体积小巧,灵活可定制,并支持`udf`和`msdos`文件系统

## 特点

- 体积小巧： Floppinux 仅占用 1.4M 的空间,适合于较旧的计算机
- 灵活定制： 可自由修改的rootfs和精简的busybox
- 内置工具： 内置了 `hush` 和 `vi`,满足用户在命令行环境下的基本需求
- 挂载支持： 支持挂载 UDF 格式的 CD/DVD 和 FAT 格式的软盘
- 极强兼容： 最低支持`486SX`处理器

## 编译

1. 确保已经安装编译所需的软件包：
   - `dosfstools` `syslinux` `make` `qemu-system-i386`（测试时需要）
   - 在Debian/Ubuntu上,使用下面的命令来安装：
      ```shell
      sudo apt install -y dosfstools syslinux make qemu-system-i386
      ```
2. 克隆本仓库
   ```shell
   git clone https://github.com/Steve3184/floppinux
   cd floppinux
   ```
3. 使用 `make` 编译 Floppinux
   ```shell
   make all        #完整编译
   make rebuild    #删除已经编译过的busybox和rootfs重新编译
   make clean      #删除构建的bzImage,busybox和rootfs
   make reset      #重置(清除所有内容)
   make size       #在floppinux.img编译完成后获取大小
   ```
4. 对生成的镜像文件进行测试(默认保存在`floppinux.img`)
   - 如果你有软盘,使用dd进行写入:
      ```shell
      sudo dd if=floppinux.img of=/dev/fdX bs=1k count=1440
      ```
   - 如果你没有软盘或只想在qemu中测试,使用这个启动qemu:
      ```shell
      make test_floppy_image
      ```
5.可在`configs/overlay/`下添加覆盖rootfs的文件,修改后使用这个编译:
   ```shell
   make clean_filesystem rootfs
   ```

编译后体积：

| 文件              | 大小    | 
|------------------|--------|
| `bzImage`        | 885K   |
| `ldlinux.c32`    | 117K   |
| `ldlinux.sys`    | 59K    |
| `rootfs.cpio.xz` | 171K   |
| `syslinux.cfg`   | 126B   |


## 注意事项
如果你无法访问Github或速度较慢,请在Makefile中修改下载所使用的Url:
```Makefile
# GIT Urls
LINUX_GIT   = 修改为你所在地区的Kernel Git镜像,例如中国用户使用：
                 https://mirrors.tuna.tsinghua.edu.cn/git/linux.git
              默认为：
                 https://github.com/torvalds/linux.git
BUSYBOX_GIT = 修改为你所在地区的Busybox Git镜像,例如中国用户使用：
                https://gitee.com/Steve3184/busybox.git
              默认为：
                https://github.com/mirror/busybox.git
CHECK_UPDATE = 是否检查更新(yes/no),默认为no
```