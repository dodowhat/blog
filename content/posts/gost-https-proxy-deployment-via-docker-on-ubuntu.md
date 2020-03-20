---
title: "部署 GOST HTTPS 代理"
date: 2020-03-18T21:38:50+08:00
draft: false
---

随着墙一步步升级，识别能力愈加强大，各路翻墙工具变得步履维艰，自创协议逐渐势微。

绕了一大圈之后，现在又回到起点，开始在不被封的主流协议上做文章。

其中比较稳妥的一个就是 HTTPS 代理。

GOST 是一个GO语言实现的代理工具，官网有详细介绍，链接在文章底部。

本文主要记录用 GOST 部署 HTTPS 代理服务的过程。

---

VPS 初始化以及 Docker 安装参考这篇文章 [Ubuntu VPS 初始化设置 + Docker安装](/posts/ubuntu-server-initiation-and-docker-installation)

## 解析域名到 VPS

你需要有一个域名，并且将它解析到你的 VPS 上。

## 使用 acme.sh 签发 Let's Encrypt 证书

以 root 身份安装 acme.sh:

    $ sudo su -
    # apt install -y socat
    # curl https://get.acme.sh | sh
    # source ~/.bashrc

签发证书:

    # acme.sh --issue --standalone -d example.com
    # mkdir ~/example.com

安装证书:

    # acme.sh --install-cert -d example.com \
      --fullchain-file ~/example.com/fullchain.pem \
      --key-file ~/example.com/key.pem \
      --cert-file ~/example.com/cert.pem \
      --reloadcmd "docker restart gost"

证书会在每 60 天自动续签，并自动重启 gost 服务。

因为现在 gost 还没有启动，docker 会报错，不用理会。

## 部署 Gost Docker 镜像

执行 `exit` 返回普通用户。

创建启动脚本 gost.sh:

    #!/bin/bash

    ## 下面的四个参数需要改成你的
    DOMAIN="example.com"
    USER="username"
    PASS="password"
    PORT=443

    BIND_IP=0.0.0.0
    CERT_DIR=/root/${DOMAIN}
    CERT=${CERT_DIR}/fullchain.pem
    KEY=${CERT_DIR}/key.pem
    sudo docker run -d --name gost \
        -v ${CERT_DIR}:${CERT_DIR}:ro \
        --net=host ginuerzh/gost \
        -L "http2://${USER}:${PASS}@${BIND_IP}:${PORT}?cert=${CERT}&key=${KEY}"

启动服务:

    $ chmod +x gost.sh
    $ ./gost.sh

## 客户端

PC 推荐用 Clash for Windows，下载地址:

*  [Github Release](https://github.com/Fndroid/clash_for_windows_pkg/releases)

Android 推荐用 Clash for Android，下载地址:

* [Github Release](https://github.com/Kr328/ClashForAndroid/releases)

* [Google Play](https://play.google.com/store/apps/details?id=com.github.kr328.clash)

还可以用 Surfboard，兼容 Surge 配置文件，下载地址：

* [APK](https://apkpure.com/surfboard/com.getsurfboard)

* [Google Play](https://play.google.com/store/apps/details?id=com.getsurfboard)

iOS 推荐用 ShadowRocket / Surge ，ShadowRocket 兼容 Surge 配置文件:

* 美区 Apple Store 搜索

## 参考资料

[Acme.sh Documentation](https://github.com/acmesh-official/acme.sh)

[科学上网-左耳朵](https://haoel.github.io/)

[Gost 官方文档](https://docs.ginuerzh.xyz/gost/tls/)

[Clash Manual](https://github.com/Dreamacro/clash)

[Surge Manual](https://manual.nssurge.com/)

[Surfbloard 官网](https://manual.getsurfboard.com/)
