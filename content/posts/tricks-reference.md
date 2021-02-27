---
title: "小技巧速查手册"
date: 2021-02-25T10:04:48+08:00
draft: false
categories:
tags:
keywords:
---

这里收录一些偶尔会用到但又记不住的命令或配置

以前的做法是收藏网址书签，但是可能会失效，所以还是自己记一下

## Linux 快速删除大文件夹

一般情况下删文件夹用命令 `rm -rf target_dir`

但是对拥有大量子目录嵌套的大文件夹(例如timeshift)来说这个命令会卡住，几小时都不会有结果

这时候要用下面的方法

```bash
mkdir empty_dir
rsync -a --delete empty_dir target_dir
```

## Linux sudo 无密码配置

```bash
visudo
myuser ALL=(ALL) NOPASSWD:ALL
```

## Linux 查看硬盘 uuid

挂载新硬盘时先查看 uuid

```bash
blkid
```

编辑 `/etc/fstab`, 添加

```bash
UUID=xxxxx-xxxx-xxxx-xxxx /target_dir ext4 defaults
```

重启系统

## Ubuntu 重启图形化界面

Linux 桌面环境，众所周知，偶尔会卡死

先按 `Ctrl + Alt + F2`(或F3-F6) 切换到其他 tty , 登录并执行:

```bash
sudo systemctl restart display-manager
```

按 `Alt + F1` 回到 tty1

## Linux 重命名分区标签

ext2/3/4 文件系统

```
sudo e2label /dev/sdaX <label>
```

## Linux 查看硬盘信息

```
sudo lshw -class disk
```

## Linux 格式化分区

```
sudo mkfs -t ext4 /dev/sdXX
lsblk -f
```

## Git 设置代理

```
git config --global http.proxy http://127.0.0.1:7890
git config --global --unset http.proxy
```