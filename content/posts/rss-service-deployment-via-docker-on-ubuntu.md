---
title: "自用 RSS 服务搭建 (Miniflux + RSSHub)"
date: 2020-03-19T00:00:31+08:00
draft: false
---

互联网越来越分裂，巨头们各自圈地，糟糕的用户体验，漫天飞舞的广告，让人不堪忍受。

好在总有各路大神们来解决痛点，RSSHub 就是其中之一。

RSSHub 是一个开源易用的 RSS 生成器，可以给任何奇奇怪怪的内容生成 RSS 订阅源，官网有详细介绍，链接在文章底部。

Miniflux 是一个网页版 RSS 阅读器，简洁干净。

本文主要记录 Miniflux + RSSHub 的搭建过程。

---

VPS 初始化以及 Docker 安装参考这篇文章 [Ubuntu VPS 初始化设置 + Docker安装](/posts/ubuntu-server-initiation-and-docker-installation)

## 部署 Miniflux

新建 Docker Compose 配置文件，保存为 `docker-compose-miniflux.yml` :

    version: '3'
    services:
      miniflux:
        image: miniflux/miniflux:latest
        ports:
          - "8080:8080"
        depends_on:
          - db
        environment:
          - DATABASE_URL=postgres://miniflux:secret@db/miniflux?sslmode=disable
      db:
        image: postgres:latest
        environment:
          - POSTGRES_USER=miniflux
          - POSTGRES_PASSWORD=secret
        volumes:
          - miniflux-db:/var/lib/postgresql/data
    volumes:
      miniflux-db:

启动服务:

    $ sudo docker-compose -f docker-compose-miniflux.yml up -d db
    $ sudo docker-compose -f docker-compose-miniflux.yml up -d miniflux

初始化数据库:

    $ docker-compose -f docker-compose-miniflux.yml exec miniflux /usr/bin/miniflux -migrate

创建用户，根据提示输入用户名及密码:

    $ docker-compose -f docker-compose-miniflux.yml exec miniflux /usr/bin/miniflux -create-admin

部署完成，现在可以访问 `http://your-vps-ip:8080` 使用了。

## 部署 RSSHub

下载官方 Docker Compose 配置，保存为 `docker-compose-rsshub.yml` :

    $ wget https://raw.githubusercontent.com/DIYgod/RSSHub/master/docker-compose.yml -o docker-compose-rsshub.yml

创建 volume 持久化 Redis 缓存:

    $ docker volume create redis-data

启动:

    $ sudo docker-compose -f docker-compse-rsshub.yml up -d

部署完成，现在可以访问 `http://your-vps-ip:1200` 使用了。

## 配置 Nginx 端口转发，使用域名访问

解析域名到你的 VPS ，假设域名分别为:

    rss.example.com  # Miniflux
    rsshub.example.com  # RSSHub

安装 Nginx :

    $ sudo apt install -y nginx

先简单修改下默认配置:

禁用 `IP` 直接访问，编辑 `/etc/nginx/site-available/default` ，注释掉 `location {}` ，接着写入:

    return 404;

隐藏 `404` 页面版本号，编辑 `/etc/nginx/nginx.conf` ，在 `http {}` 中写入:

    server_tokens off;

配置端口转发及域名访问，新建配置文件 `/etc/nginx/site-available/rss.conf` :

    # Miniflux
    server {
        listen 80;
        server_name rss.example.com;
        index index.html;
        location / {
            proxy_pass http://127.0.0.1:8080;
        }
    }

    # RSSHub
    server {
        listen 80;
        server_name rsshub.example.com;
        index index.html;
        location / {
            proxy_pass http://127.0.0.1:1200;
        }
    }

启用配置:

    $ sudo ln -s /etc/nginx/site-available/rss.conf /etc/ngxin/site-enabled/

重启服务:

    $ sudo nginx -s reload

现在可以用域名访问了。

## 使用 acme.sh 签发 Let's Encrypt 证书

以 root 身份安装 acme.sh:

    $ sudo su -
    # apt install -y socat
    # curl https://get.acme.sh | sh
    # source ~/.bashrc

签发证书:

    # acme.sh --issue --nginx -d rss.example.com
    # mkdir ~/rss.example.com
    # acme.sh --install-cert -d rss.example.com \
      --fullchain-file ~/rss.example.com/fullchain.pem \
      --key-file ~/rss.example.com/key.pem
      --reloadcmd "service nginx force-reload"

    # acme.sh --issue --nginx -d rsshub.example.com
    # mkdir ~/rsshub.example.com
    # acme.sh --install-cert -d rsshub.example.com \
      --fullchain-file ~/rsshub.example.com/fullchain.pem \
      --key-file ~/rsshub.example.com/key.pem
      --reloadcmd "service nginx force-reload"

配置 Nginx HTTPS，编辑 `/etc/nginx/site-available/rss.conf` :

    # Miniflux
    server {
        listen 80;
        server_name rss.example.com;

        listen 443 ssl;

        ssl_certificate /root/rss.http-404.com/fullchain.pem;
        ssl_certificate_key /root/rss.http-404.com/key.pem;
        ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
        ssl_ciphers HIGH:!aNULL:!MD5;

        if ($scheme != "https") {
          return 301 https://$host$request_uri;
        }

        index index.html;
        location / {
            proxy_pass http://127.0.0.1:8080;
        }
    }

    # RSSHub
    server {
        listen 80;
        server_name rsshub.example.com;

        listen 443 ssl;

        ssl_certificate /root/rsshub.http-404.com/fullchain.pem;
        ssl_certificate_key /root/rsshub.http-404.com/key.pem;
        ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
        ssl_ciphers HIGH:!aNULL:!MD5;

        if ($scheme != "https") {
            return 301 https://$host$request_uri;
        }

        index index.html;
        location / {
            proxy_pass http://127.0.0.1:1200;
        }
    }

现在可以用 HTTPS 访问了。

PS: 配置过程中的一个小插曲，`ssl_certificate` 要用 `fullchain.pem` ，不要用 `cert.pem` ，否则访问可能出现下面的错误:

    x509: certificate signed by unknown authority

## 配置 RSSHub 用户认证

现在这个建好的 RSSHub 服务是公开的，可以被别人直接访问使用。

我希望只给自己使用，不被白嫖，所以给它加上用户认证。

RSSHub 自带 HTTP 基础认证功能，但只给少部分路由开启，不符合我的需求。

这里我通过配置 Nginx 给所有路由加上 HTTP 基础认证。

使用 `htpasswd` 工具创建用户认证密码文件:

安装工具:

    $ sudo apt install -y apache2-utils

创建用户:

    $ sudo htpasswd -c /etc/nginx/htpasswd user1

`user1` 是你想要的用户名，随便取，根据提示设定密码。

`-c` 参数表示新建密码文件，如果文件已存在，去掉这个参数。

编辑 `/etc/nginx/site-available/rss.conf` ，找到 RSSHub 的 `location {}` 部分，修改为: 

    location / {
        proxy_pass http://127.0.0.1:1200;
        auth_basic "Restricted Content";
        auth_basic_user_file /etc/nginx/htpasswd;
    }

重启 Nginx:

    sudo nginx -s reload

RSSHub 用户认证配置好了。在 Miniflux 中新增订阅时，在 `高级选项` 中填写刚才的用户名密码就可以了。

## 移动端

Miniflux 是一个 PWA(Progressive web app) 应用，跨平台，响应式设计，在手机浏览器中也有很好的体验。

在iOS 的 Safari 和 Android 的 Chrome 上你可以手机主界面上创建快捷方式，方便直接访问。

也可以使用第三方客户端连接，前提是在 Miniflux 设置里开启 Fever API:

Android 推荐 FeedMe:

* [Google Play](https://play.google.com/store/apps/details?id=com.seazon.feedme)

iOS 推荐 Reeder:

* 在 Apple Store 中自行搜索

## 参考资料

[Miniflux Manual](https://miniflux.app/docs/installation.html#docker)

[RSSHub 官方文档](https://docs.rsshub.app/install/#docker-compose-bu-shu)

[Acme.sh Documentation](https://github.com/acmesh-official/acme.sh)

[Nginx Configuring HTTPS](http://nginx.org/en/docs/http/configuring_https_servers.html)

[Using Let's Encrypt with Nginx](https://www.nginx.com/blog/using-free-ssltls-certificates-from-lets-encrypt-with-nginx/)

[Nginx configuring HTTP Basic Authentication](https://docs.nginx.com/nginx/admin-guide/security-controls/configuring-http-basic-authentication/)

[x509: certificate signed by unknown authority](https://github.com/matrix-org/matrix-federation-tester/issues/59)
