---
menu: "main"
weight: 50
title: "命令速查"
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

## sudo 使用当前环境变量

```bash
sudo -E COMMAND
```

## PowerShell 设置代理

```bash
$env:https_proxy="127.0.0.1:7890"
```

等同于 Linux 下的 `export https_proxy=127.0.0.1:7890`

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

FAT32 文件系统 fatlabel
NTFS 文件系统 ntfslabel

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

## PowerShell Emacs Key Bindings

```PowerShell
Set-PSReadLineOption -EditMode Emacs
```

## RSA 公钥格式转换

```
# SSH2 => OpenSSH
ssh-keygen -i -f ssh2.pub > openssh.pub

# OpenSSH => SSH2
ssh-keygen -e -f openssh.pub > ssh2.pub
```

## IntelliJ IDEA & WSL 2 编译 connection time out 报错

任务栏 -> 右键 Windows Security 图标 -> View security dashboard -> Firewall & network protection -> Restore firewalls to default

重启 IDEA 并操作，在弹出的防火墙窗口允许 Private 和 Public 连接

## Mysql 8 Error: Access denied for user 'root'@'localhost'

Edit `/etc/mysql/mysql.conf.d/mysqld.cnf`

find and replace:

    bind-address = 0.0.0.0

then

    sudo mysql
    GRANT ALL PRIVILEGES ON *.* TO 'root'@'%';
    UPDATE mysql.user SET host='%' WHERE user='root';
    ALTER USER 'root'@'%' IDENTIFIED WITH mysql_native_password BY 'MyPassword';

## Mysql Disable Strict Mode

    mysql -u root -p -e "SET GLOBAL sql_mode = 'NO_ENGINE_SUBSTITUTION';"
    mysql -u root -p -e "SELECT @@GLOBAL.sql_mode;"

or edit `/etc/mysql/mysql.conf.d/mysqld.cnf`, under `[mysqld]`, look for `sql_mode`

    sql_mode=NO_ENGINE_SUBSTITUTION,STRICT_TRANS_TABLES
