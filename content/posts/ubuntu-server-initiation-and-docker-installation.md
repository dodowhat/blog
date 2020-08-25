---
title: "Ubuntu Server 初始化设置 + Docker 安装"
date: 2020-03-17T21:14:08+08:00
draft: false
---

本文主要记录 Ubuntu Server 的一些初始化操作。

适用于本机、虚拟机、VPS 云主机等等创建后初次运行时参考，方便后续维护使用。

包括：新增普通权限用户、配置SSH密钥登录、Docker 安装。

关于普通权限用户，有些运营商的云主机创建后已自动配置好，不需要自己操作了，如 GCE(Google Compute Engine), EC2(Amazon EC2)等等。

有些运营商则只有 root 用户，如：阿里云。

---

下面以阿里云为例。

首先，登录root用户。

## 更新系统:

```cmd
# apt update && sudo apt upgrade -y
```

## 新增普通用户:

```cmd
# adduser user1
```

为新用户配置sudo:

```cmd
# update-alternatives --config editor # 变更默认文本编辑器(非必要步骤)
# visudo
```

添加新行:

```cmd
user1 ALL=(ALL) NOPASSWD: ALL
```

切换至新用户:

```cmd
# su - user1
```

导入SSH密钥:

```bash
$ mkdir ~/.ssh
$ vim ~/.ssh/authorized_keys  # 写入公钥，格式(单行)：ssh-rsa your_public_key
$ chmod 700 ~/.ssh
$ chmod 644 ~/.ssh/authorized_keys
```

更新SSH配置，禁用root远程登录以及密码登录:

```bash
$ sudo vim /etc/ssh/sshd_config
```

找到以下内容并在行首加#号注释掉:

```bash
PermitRootLogin yes  # 允许root远程登录
PasswordAuthentication yes  # 允许密码登录
```

重启SSH服务:

```bash
$ sudo systemctl restart ssh
```

## 配置Putty

Connection -> Seconds between keepalives 设为60，防止超时卡死。

退出登录时使用 `Ctrl-D` 或 `exit` 命令，不要直接点X关闭，否则连接进程会驻留，占用资源。

使用 `w` 命令查看当前登录用户。

踢掉某用户:

```bash
$ sudo pkill -kill -t pts/0  # pts/0是w命令输出的TTY列的值
```

## 安装 Docker

准备工作:

```bash
$ sudo apt-get update
$ sudo apt-get install -y \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg-agent \
    software-properties-common
```

添加软件源(二选一):

```bash
# 官方源
$ curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
$ sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"

# 国内源
$ curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
$ sudo add-apt-repository \
   "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
   $(lsb_release -cs) \
   stable"
```

安装:

```bash
$ sudo apt-get update
$ sudo apt-get install -y docker-ce
```

如果想要以普通用户使用 Docker，就将用户加入docker组:

```bash
$ sudo usermod -aG docker user1
```

安装 `docker-compose` :

```bash
$ sudo curl -L "https://github.com/docker/compose/releases/download/1.25.4/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
$ sudo chmod +x /usr/local/bin/docker-compose
```

参考资料:

[Docker 安装官方文档](https://docs.docker.com/install/linux/docker-ce/ubuntu/)

[Docker Compose 官方文档](https://docs.docker.com/compose/install/)

[Docker 从入门到实践](https://yeasy.gitbooks.io/docker_practice/content/install/ubuntu.html)
