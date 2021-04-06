---
title: "Linux 系统 Clash 服务管理"
date: 2020-11-06T20:45:17+08:00
draft: false
---

Clash 是一款支持多种协议的代理客户端，在 Windows 以及 MacOS 上均有图形化版本，然而 Linux 上没有。

好在 Clash 提供了用于管理服务的 RESTful API ，并且作者开发了配套的 Web 版管理面板，其他人也可以根据 API 开发自己的管理面板。

本文记录了如何在 Linux 系统上丝滑地使用 Clash 服务。

(本文内容包含的脚本相对粗糙，是为了降低复杂度说清原理而简化的原始版本，完全版已上传至 Github 仓库 [clash-for-linux](https://github.com/dodowhat/clash-for-linux) ，功能更完善)

## 准备工作
 
访问 [Clash Github Releases](https://github.com/Dreamacro/clash/releases)，找到适合自己硬件架构的版本，一般为 clash-linux-amd64。

命令行操作：

```bash
# 创建一个工作目录
$ mkdir clash-linux-management-tools
$ cd clash-linux-management-tools
# 下载
$ wget https://github.com/Dreamacro/clash/releases/download/v1.2.0/clash-linux-amd64-v1.2.0.gz
# 解压
$ gzip -d clash-linux-amd64-v1.2.0.gz
# 解压出来程序的文件名带有平台、版本等信息，重命名为 clash 方便执行
$ mv clash-linux-amd64-v1.2.0 clash
# 赋予程序可执行权限
$ chmod u+x clash
```

## 后台运行

Clash 本身不提供后台服务运行的功能，需要用户自己想办法，大致有三种实现方式：

* Systemd (官方 Gihub Wiki 有具体教程)

> 通过创建 Systemd 配置文件将 Clash 纳入系统进程管理

* 第三方进程管理工具

> 常见的有：[pm2](https://pm2.keymetrics.io/) [nodemon](https://nodemon.io/)

* Shell 命令

> 利用 nohup 命令以及其它进程管理命令实现后台运行

个人不喜欢前两种方式，所以选择第三种方式。

启动服务脚本 start.sh

```bash
#!/bin/bash

# 检测并结束正在运行的 Clash 服务，下面会讲到
./stop.sh

# 启动服务
nohup ./clash -d . > /dev/null 2>&1 &
```

启动命令有三部分，简单说明一下
 
* nohup

> 这个命令可以让你执行的程序忽略“挂起”信号。
也就是说假如你通过它运行了某个程序，然后关掉了终端窗口，这个程序依旧会在系统里运行。
使用方法为在你执行的命令最前面加上 nohup 就可以了。

* ./clash -d .

> 这是普通方式启动 Clash 的命令。
-d 参数可以指定配置文件所在的目录，这里我指定为当前所在目录，所以写一个 . 就可以了。
特别说明一下配置文件名称必须为 config.yaml，否则程序不会识别。

或者也可以用 -f 参数指定配置文件，文件名无要求。

*  \> /dev/null 2>&1 &

> 这部分用一句话概括就是“保持静默地在后台运行”，在搜索 nohup 相关资料时应该会有提及，这里就不赘述了。

结束服务脚本 stop.sh

```bash
#!/bin/bash

# 查找 clash 服务的进程ID
PID=$(pidof clash)

if [ ! -z "$PID" ]; then
    # 根据进程ID结束进程
    kill -9 $PID
fi
```

好了，现在就可以通过脚来启动或结束服务了。

接下来看如何管理“机场”订阅的配置文件。

## 订阅配置管理

如今网络上有很多提供代理服务的商家 (俗称“机场”)，订阅之后会向你提供一个链接用来下载配置文件。

图形化版本的 Clash 可以很方便地通过鼠标点点点来管理这些订阅配置，那么如何通过命令行来做到这些呢？

首先我们创建一个目录，用来存放下载后的订阅配置文件

```bash
$ mkdir configs
```

接着创建订阅配置管理脚本，假如某“机场”名叫 "abc" ，创建 abc.sh (名字可以随便起)

```bash
#!/bin/bash

# 这里填你的订阅链接
URL="https://abc.xyz/user123/clash"

FILENAME=configs/$(basename $0 .sh).yaml

curl -L ${URL} > ${FILENAME}

if [ $? -eq 0 ]; then
    cp ${FILENAME} config.yaml
fi;
```

执行这个脚本后会在 configs 目录下生成 abc.yaml (与脚本名称自动保持一致) 并且覆盖到 config.yaml 作为默认配置。

如果你还有其它的订阅链接，将这份脚本复制一份，改个文件名 (比如 def.sh)，再修改里面的 URL 就可以使用了。

## 半场总结

现在我们回顾一下当前工作目录的文件结构

    |clash-linux-management-tools
        |---- clash          解压并重命名的 clash 本体
        |---- config.yaml    默认配置文件
        |---- start.sh       启动/重启脚本
        |---- stop.sh        结束运行脚本
        |---- abc.sh         abc订阅更新脚本
        |---- def.sh         def订阅更新脚本
        |==== configs        订阅配置下载目录
            |---- abc.yaml   下载的abc订阅配置
            |---- def.yaml   下载的def订阅配置

接下来部署 Web 管理面板。

## 部署 Web 管理面板

Web 管理面板有两个版本

* [clash-dashboard](https://github.com/Dreamacro/clash-dashboard) 由 Clash 作者开发

* [yacd](https://github.com/haishanh/yacd) 由第三方作者开发

两个项目的 gh-pages 分支均为编译好的成品，可直接部署使用。

以 yacd 为例

```bash
# 下载
$ curl -L https://github.com/haishanh/yacd/archive/gh-pages.zip --output yacd-gh-pages.zip

# 解压并重命名
unzip yacd-gh-pages.zip
mv yacd-gh-pages ui
```

然后修改 start.sh
```bash
# 启动服务
nohup ./clash -d . -ext-ctl 127.0.0.1:9090 -ext-ui ui > /dev/null 2>&1 &
```

然后就可以访问 http://127.0.0.1:9090/ui 使用了