---
title: "部署 GOST HTTPS 代理"
date: 2020-03-18T21:38:50+08:00
draft: false
---

目前 HTTPS 是比较稳一种协议。

GOST 是一个GO语言实现的代理工具，官网有详细介绍，链接在文章底部。

本文主要记录用 GOST 部署 HTTPS 代理服务的过程。

---

VPS 初始化以及 Docker 安装参考这篇文章 [Ubuntu VPS 初始化设置 + Docker安装](/posts/ubuntu-server-initiation-and-docker-installation)

## 解析域名到 VPS

你需要有一个域名，并且将它解析到你的 VPS 上。

## 使用 certbot 签发 Let's Encrypt 证书

安装 certbot:

    $ sudo apt-get update
    $ sudo apt-get install software-properties-common
    $ sudo add-apt-repository universe
    $ sudo add-apt-repository ppa:certbot/certbot
    $ sudo apt-get update
    $ sudo apt-get install certbot

签发证书:

    $ sudo certbot certonly --standalone

根据提示输入域名和邮箱

证书默认生成在`/etc/letsencrypt/live/<YOUR.DOMAIN.COM/>`目录下

## 部署 Gost Docker 镜像

创建启动脚本 gost.sh:

    #!/bin/bash

    ## 下面的四个参数需要改成你的
    domain="example.com"
    username="username"
    password="password"
    port=443

    bind_ip=0.0.0.0
    cert_dir=/etc/letsencrypt/${domain}
    cert_file=${cert_dir}/fullchain.pem
    key_file=${cert_dir}/privkey.pem
    sudo docker run -d --name gost \
        -v ${cert_dir}:${cert_dir}:ro \
        --net=host ginuerzh/gost \
        -L "http2://${username}:${password}@${bind_ip}:${port}?cert=${cert_file}&key=${key_file}"

启动服务:

    $ chmod +x gost.sh
    $ ./gost.sh

## 证书自动更新

证书会在90天后过期，我们建立一个cron job来自动更新证书:

    $ sudo crontab -e

写入如下内容:

    0 0 1 * * /usr/bin/certbot renew --force-renewal
    5 0 1 * * /usr/bin/docker restart gost

crontab格式说明:

    分[0-59] 时[0-23] 日[1-31] 月[1-12] 星期[0-7] 要执行的命令

## 客户端

PC: Clash for Windows，下载地址:

*  [Github Release](https://github.com/Fndroid/clash_for_windows_pkg/releases)

Android:

Clash for Android，下载地址:

* [Github Release](https://github.com/Kr328/ClashForAndroid/releases)

* [Google Play](https://play.google.com/store/apps/details?id=com.github.kr328.clash)

Surfboard，兼容 Surge 配置文件，下载地址：

* [APK](https://apkpure.com/surfboard/com.getsurfboard)

* [Google Play](https://play.google.com/store/apps/details?id=com.getsurfboard)

iOS: ShadowRocket / Surge ，ShadowRocket 兼容 Surge 配置文件:

* 美区 Apple Store 搜索

## 分流规则

自动生成配置文件 (Surge / Clash)，适用于以上全部客户端

项目地址: [https://github.com/dodowhat/gfwrules](https://github.com/dodowhat/gfwrules)

## 参考资料

[科学上网-左耳朵](https://haoel.github.io/)

[Gost 官方文档](https://docs.ginuerzh.xyz/gost/tls/)

[Clash Manual](https://github.com/Dreamacro/clash)

[Surge Manual](https://manual.nssurge.com/)

[Surfbloard 官网](https://manual.getsurfboard.com/)
