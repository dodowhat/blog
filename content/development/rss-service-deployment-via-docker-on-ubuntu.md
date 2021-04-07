---
title: "自用 RSS 服务搭建 (Miniflux + RSSHub)"
date: 2020-03-19T00:00:31+08:00
draft: false
tags: ["RSS"]
---

RSSHub 是一个开源易用的 RSS 生成器，可以给任何奇奇怪怪的内容生成 RSS 订阅源，官网有详细介绍，链接在文章底部。

Miniflux 是一个网页版 RSS 阅读器，简洁干净。

本文主要记录 Miniflux + RSSHub 的搭建过程。

---

## 安装 Docker & Docker Compse

参考

- [https://docs.docker.com/engine/install/ubuntu/](https://docs.docker.com/engine/install/ubuntu/)

- [https://docs.docker.com/compose/install/](https://docs.docker.com/compose/install/)

## 部署 Miniflux

下载官方 Docker Compose 配置

```bash
curl https://raw.githubusercontent.com/miniflux/v2/master/contrib/docker-compose/basic.yml -o miniflux.yml
```

删除以下部分

```yaml
- RUN_MIGRATIONS=1
- CREATE_ADMIN=1
- ADMIN_USERNAME=admin
- ADMIN_PASSWORD=test123
```

编辑端口映射配置为 `8080:8080`

启动服务:

```bash
sudo docker-compose -f miniflux.yml up -d db
sudo docker-compose -f miniflux.yml up -d miniflux
```

初始化数据库

```bash
sudo docker-compose -f miniflux.yml exec miniflux /usr/bin/miniflux -migrate
```

创建用户，根据提示输入用户名及密码:

```bash
sudo docker-compose -f miniflux.yml exec miniflux /usr/bin/miniflux -create-admin
```

部署完成，现在可以访问 `http://your-vps-ip:8080` 使用了。

## 部署 RSSHub

下载官方 Docker Compose 配置

```bash
curl https://raw.githubusercontent.com/DIYgod/RSSHub/master/docker-compose.yml -o rsshub.yml
```

创建 volume 持久化 Redis 缓存:

```bash
sudo docker volume create redis-data
```

启动:

```bash
sudo docker-compose -f rsshub.yml up -d
```

部署完成，现在可以访问 `http://your-vps-ip:1200` 使用了。

## 配置 Nginx 端口转发，使用域名访问

解析域名到你的 VPS ，假设域名分别为:

    miniflux.example.com  # Miniflux
    rsshub.example.com  # RSSHub

安装 Nginx :

```bash
sudo apt install -y nginx
```

先简单修改下默认配置:

禁用 `IP` 直接访问，编辑 `/etc/nginx/site-available/default` ，在 `location {}` 上方写入:

```nginx
return 403;
```

隐藏错误页面版本号，编辑 `/etc/nginx/nginx.conf` ，在 `http {}` 中写入:

```nginx
server_tokens off;
```

配置端口转发及域名访问，新建配置文件 `/etc/nginx/site-available/rss.conf` :

```nginx
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
```

启用配置:

```bash
sudo ln -s /etc/nginx/site-available/rss.conf /etc/ngxin/site-enabled/
```

重启服务:

```bash
sudo nginx -s reload
```

现在可以用域名访问了。

## 配置 RSSHub 用户认证

现在这个建好的 RSSHub 服务是公开的，可以被别人直接访问使用。

我希望只给自己使用，不被白嫖，所以给它加上用户认证。

RSSHub 自带 HTTP 基础认证功能，但只给少部分路由开启，不符合我的需求。

这里我通过配置 Nginx 给所有路由加上 HTTP 基础认证。

使用 `htpasswd` 工具创建用户认证密码文件:

安装工具:

```bash
sudo apt install -y apache2-utils
```

创建用户:

```bash
sudo htpasswd -c /etc/nginx/htpasswd rsshub
```

`rsshub` 是你想要的用户名，随便取，根据提示设定密码。

`-c` 参数表示新建密码文件，如果文件已存在，去掉这个参数。

编辑 `/etc/nginx/site-available/rss.conf` ，找到 RSSHub 的 `location {}` 部分，修改为: 

```nginx
location / {
    proxy_pass http://127.0.0.1:1200;
    auth_basic "Restricted Content";
    auth_basic_user_file /etc/nginx/htpasswd;
}
```

重启 Nginx:

```bash
sudo nginx -s reload
```

RSSHub 用户认证配置好了。在 Miniflux 中新增订阅时，在 `高级选项` 中填写刚才的用户名密码就可以了。

## 使用 Certbot 签发 Let's Encrypt 证书

参考 [https://certbot.eff.org/](https://certbot.eff.org/)

证书默认生成在`/etc/letsencrypt/live/<YOUR.DOMAIN.COM/>`目录下

现在可以用 HTTPS 访问了。

PS: 配置过程中的一个小插曲，`ssl_certificate` 要用 `fullchain.pem` ，不要用 `cert.pem` ，否则访问可能出现下面的错误:

```bash
x509: certificate signed by unknown authority
```

## 移动端

Miniflux 是一个 PWA(Progressive web app) 应用，跨平台，响应式设计，在手机浏览器中也有很好的体验。

在iOS 的 Safari 和 Android 的 Chrome 上你可以手机主界面上创建快捷方式，方便直接访问。

也可以使用第三方客户端连接，前提是在 Miniflux 设置里开启 Fever API:

Android 推荐 FeedMe:

* [Google Play](https://play.google.com/store/apps/details?id=com.seazon.feedme)

iOS 推荐 Reeder:

* 在 Apple Store 中自行搜索

## 参考资料

[Docker docs](https://docs.docker.com/)

[Miniflux Manual](https://miniflux.app/docs/installation.html#docker)

[RSSHub 官方文档](https://docs.rsshub.app/install/#docker-compose-bu-shu)

[Certbot Documentation](https://certbot.eff.org/)

[Nginx Configuring HTTPS](http://nginx.org/en/docs/http/configuring_https_servers.html)

[Using Let's Encrypt with Nginx](https://www.nginx.com/blog/using-free-ssltls-certificates-from-lets-encrypt-with-nginx/)

[Nginx configuring HTTP Basic Authentication](https://docs.nginx.com/nginx/admin-guide/security-controls/configuring-http-basic-authentication/)

[x509: certificate signed by unknown authority](https://github.com/matrix-org/matrix-federation-tester/issues/59)
