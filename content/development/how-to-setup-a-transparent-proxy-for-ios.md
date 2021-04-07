---
title: 为iOS搭建可自动分流的透明代理——解决方案
date: 2017-07-11T20:45:17+08:00
tags: ["GFW"]
---

## 2019-04-21更新

实际上本文中的方案我没有使用太久，2018年我尝试用Squid搭建了一个HTTPS代理，搭配Surge3使用了一阵，效果也不尽如人意。

如今到了9102年，目前我的只是单纯使用Surge3或者ShadowRocket配合SS后端使用。
并且自己维护了一份基于[ipip.net](ipip.net)提供的国内IP列表转换而来的Surge3配置文件(ShadowRocket兼容Surge3配置，可直接导入使用)，使访问国内IP的请示走直联，其它请求走代理。

项目地址：[https://github.com/dodowhat/china-ip-rules](https://github.com/dodowhat/china-ip-rules)

虽然方案已经过时，文中的其它技术细节依旧有参考价值。

以下为原文

---

## 需求背景
最近，我想让我的iPhone实现自动分流科学上网。

关于自建科学上网服务，最广为人知的莫过于shadowsocks（以下简称SS）了。针对移动设备，安卓上有
shadowsocks for android，iOS上原本有shadowsocks for ios，但是已经废弃，虽然网络上流传着
其他可用的替代方案，比如：surge、potatso、wingy等等，但是我并不太愿意用。

(从9102年归来的自己前来打脸，hhh。。现在表示Surge/ShadowRocket/Surfboard等等真香。。)

总之就是想用自己目前所学的知识解决问题。

在网上搜索相关资料，有很多关于在openwrt上搭建SS服务配合dnsmasq与gfwlist实现分流的教程，这种方案
首先需要有一台可刷机的路由器，其次不能在3G/4G上使用，而我想在使用3G/4G时也能自如地实现
自动分流科学上网，于是想到了用一台墙内VPS充当上面提到的openwrt的角色，然后借鉴这些教程的其他
部分搭建自己的服务，结果不尽人意。
这些教程里用的都是公共DNS，在我这里并不能用；于是想到自建DNS Server

## 大致流程
* 一台墙外VPS：
  1. 搭建SS服务
  2. 搭建BIND DNS缓存服务，解决DNS污染问题
* 一台墙内VPS：
  1. 搭建SS中转服务（利用shadowsocks-libev的ss-redir程序实现）
  2. 搭建BIND DNS缓存服务，缓存上文中自建的境外DNS服务，依旧是为了解决DNS污染问题
  3. 从APNIC获取墙内IP段，结合ipset、iptables实现自动分流
  4. 搭建strongSwan VPN服务，作为终端的透明代理，iPhone需要靠它来连接到墙内VPS

## 正文
上文提到，需要准备两台VPS，一台墙内，一台墙外

### 墙外VPS（系统以Ubuntu为例）

#### 1. 搭建SS服务
网上有大量教程，不多说

#### 2. 搭建BIND DNS缓存服务
自建一个DNS服务，通过白名单机制只允许墙内VPS访问

安装BIND9

    sudo apt-get update
    sudo apt-get install bind9 bind9utils bind9-doc

编辑配置文件

    sudo vim /etc/bind/named.conf.options

改为

    # 设置白名单
    acl goodclients {
      1.1.1.1; # 此处替换为墙内VPS的IP
      localhost;
      localnets;
    };

    options {
      ... # 默认配置

      recursion yes; # 开启递归查询
      allow-query { goodclients; }; # 允许白名单访问
      listen-on port 6464 { any; }; # 监听非常规端口，默认53端口已被墙
    }

保存退出，通过BIND自带命令检查配置文件是否有语法错误

    sudo named-checkconf

重启BIND9服务，使配置生效

    sudo systemctl restart bind9

验证服务是否部署成功，登入墙内VPS，运行命令

    dig www.google.com @2.2.2.2(墙外VPS IP) -p 6464(上文配置的非常规端口)

查看返回的IP是否为有效IP

### 墙内VPS

#### 1. 安装shadowsocks-libev
参考官方README

#### 2. 搭建BIND DNS缓存服务，缓存境外VPS的自建DNS
其它步骤参考上文，重点说下配置文件

    # 设置白名单
    acl goodclients {
      10.10.10.0/24; # 后文搭建strongSwan VPN时分配的内网IP段
      localhost;
      localnets;
      1.1.1.1; # 墙内VPS自身的公网IP
    };

    options {
      ... # 默认配置

      recursion yes; # 开启递归查询
      allow-query { goodclients; }; # 允许白名单访问
      # 缓存自建的墙外DNS服务
      forwarders {
        2.2.2.2 port 6464; # 墙外VPS的IP与DNS非常规端口
      };
    }

保存重启服务

#### 3. 开启SS中转服务，获取墙内IP段导入ipset，添加iptables规则实现分流
这些操作全部写到`/etc/rc.local`，开机自动执行

    # 开启SS中转服务（SS的配置文件自己先改好）
    ss-redir -u -c /etc/shadowsocks-libev/config.json -f /var/run/ss-redir.pid -b 0.0.0.0

    ipset create chnroutes hash:net # 创建ipset，存储墙内IP段

    # 获取墙内IP段，导入建好的ipset里
    curl 'http://ftp.apnic.net/apnic/stats/apnic/delegated-apnic-latest' |\
    grep ipv4 | grep CN |\
    awk -F\| '{ printf("%s/%d\n", $4, 32-log($5)/log(2)) }' |\
    xargs -I ip ipset add chnroutes ip

    # 让VPS尽到代理的职责，处理VPN客户端的请求转发出去
    iptables -t nat -A POSTROUTING -s 10.10.10.0/24 -o eth0 -j MASQUERADE

    # 访问墙内的请求直接通过墙内VPS访问（配合ipset判断）
    iptables -t nat -A PREROUTING -s 10.10.10.0/24 -p tcp -m set \
    --match-set chnroutes dst -j RETURN

    # 剩余的请求（访问墙外地址的请求）转发到SS中转服务
    iptables -t nat -A PREROUTING -s 10.10.10.0/24 -p tcp -j \
    REDIRECT --to-ports 1080

开启流量转发功能

    sudo vim /etc/sysctl.conf

末尾添加新行

    net.ipv4.ip_forward=1

#### 4. 搭建strongSwan VPN服务，以供iPhone连接

安装strongSwan

    sudo apt-get -y install strongswan strongswan-plugin-openssl \
    strongswan-plugin-eap-mschapv2

编辑strongSwan配置文件

    sudo vim /etc/strongswan.conf

增加自定义DNS地址

    charon {
      load_modular = yes
      dns1 = 1.1.1.1 # 墙内VPS自身的IP
      plugins {
        include strongswan.d/charon/*.conf
      }
    }

编辑VPN配置

    sudo vim /etc/ipsec.conf

改为

    config setup
      strictcrlpolicy=no
      uniqueids = no

    conn %default
      mobike=yes
      dpdaction=clear
      dpddelay=35s
      dpdtimeout=200s
      fragmentation=yes

    conn iOS-IKEV2
      auto=add
      keyexchange=ikev2
      eap_identity=%any
      left=%any
      leftsubnet=0.0.0.0/0
      rightsubnet=10.10.10.0/24
      leftauth=psk
      leftid=%any
      right=%any
      rightsourceip=10.10.10.0/24
      rightauth=eap-mschapv2
      rightid=%any

设置VPN预共享密钥，用户名，密码

    sudo vim /etc/ipsec.secrets

改为

     : PSK "helloworld" # 预共享密钥，随意设置
    username : EAP "password" # 用户名密码，随意设置

保存，重启VPS让所有配置生效

    sudo reboot

到此，服务器配置完毕，还差最后一步

#### 为iPhone创建描述文件配置VPN连接

新建空白文件，写入以下内容，并把我用@@标记的部分替换成自己的配置

    <?xml version="1.0" encoding="UTF-8"?>
    <!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
    <plist version="1.0">
      <dict>
        <key>PayloadContent</key>
        <array>
          <dict>
            <key>IKEv2</key>
            <dict>
              <key>AuthName</key>
              <string>@@这里替换成你在/etc/ipsec.secrets中设置的用户名@@</string>
              <key>AuthPassword</key>
              <string>@@这里替换成你在/etc/ipsec.secrets中设置的密码@@</string>
              <key>AuthenticationMethod</key>
              <string>SharedSecret</string>
              <key>ChildSecurityAssociationParameters</key>
              <dict>
                <key>DiffieHellmanGroup</key>
                <integer>2</integer>
                <key>EncryptionAlgorithm</key>
                <string>3DES</string>
                <key>IntegrityAlgorithm</key>
                <string>SHA1-96</string>
                <key>LifeTimeInMinutes</key>
                <integer>1440</integer>
              </dict>
              <key>DeadPeerDetectionRate</key>
              <string>Medium</string>
              <key>DisableMOBIKE</key>
              <integer>0</integer>
              <key>DisableRedirect</key>
              <integer>0</integer>
              <key>EnableCertificateRevocationCheck</key>
              <integer>0</integer>
              <key>EnablePFS</key>
              <integer>0</integer>
              <key>ExtendedAuthEnabled</key>
              <true/>
              <key>IKESecurityAssociationParameters</key>
              <dict>
                <key>DiffieHellmanGroup</key>
                <integer>2</integer>
                <key>EncryptionAlgorithm</key>
                <string>3DES</string>
                <key>IntegrityAlgorithm</key>
                <string>SHA1-96</string>
                <key>LifeTimeInMinutes</key>
                <integer>1440</integer>
              </dict>
              <key>LocalIdentifier</key>
              <string>myserver.com.client</string>
              <key>RemoteAddress</key>
              <string>@@这里替换成你的墙内VPS的IP地址@@</string>
              <key>RemoteIdentifier</key>
              <string>myserver.com.server</string>
              <key>SharedSecret</key>
              <string>@@这里替换成你在/etc/ipsec.secrets中设置的预共享密钥@@</string>
              <key>UseConfigurationAttributeInternalIPSubnet</key>
              <integer>0</integer>
            </dict>
            <key>IPv4</key>
            <dict>
              <key>OverridePrimary</key>
              <integer>1</integer>
            </dict>
            <key>PayloadDescription</key>
            <string>Configures VPN settings for iphone</string>
            <key>PayloadDisplayName</key>
            <string>@@描述文件详情里显示的配置名称，随意起@@</string>
            <key>PayloadIdentifier</key>
            <string>com.apple.vpn.managed.@@这里替换成用uuidgen命令生成的唯一标识字符串@@</string>
            <key>PayloadType</key>
            <string>com.apple.vpn.managed</string>
            <key>PayloadUUID</key>
            <string>@@这里替换成用uuidgen命令生成的唯一标识字符串@@</string>
            <key>PayloadVersion</key>
            <real>1</real>
            <key>Proxies</key>
            <dict>
              <key>HTTPEnable</key>
              <integer>0</integer>
              <key>HTTPSEnable</key>
              <integer>0</integer>
              <key>ProxyAutoConfigEnable</key>
              <integer>0</integer>
              <key>ProxyAutoDiscoveryEnable</key>
              <integer>0</integer>
            </dict>
            <key>UserDefinedName</key>
            <string>@@为你的VPN配置起个名字，替换这里@@</string>
            <key>VPNType</key>
            <string>IKEv2</string>
            <key>VendorConfig</key>
            <dict/>
          </dict>
        </array>
        <key>PayloadDisplayName</key>
        <string>@@描述文件显示名称，随意起@@</string>
        <key>PayloadIdentifier</key>
        <string>@@这里替换成用uuidgen命令生成的唯一标识字符串@@</string>
        <key>PayloadRemovalDisallowed</key>
        <false/>
        <key>PayloadType</key>
        <string>Configuration</string>
        <key>PayloadUUID</key>
        <string>@@这里替换成用uuidgen命令生成的唯一标识字符串@@</string>
        <key>PayloadVersion</key>
        <integer>1</integer>
      </dict>
    </plist>


保存，文件命名以`.mobileconfig`结尾，假设保存在`~/myvpn.mobileconfig`

开启一个简单的HTTP服务

    cd ~
    phthon -m SimpleHTTPServer 8080

用iPhone打开Safari访问`http://1.1.1.1:8080/myvpn.mobileconfig`，
输入解锁密码，安装描述文件，成功后，进入VPN设置，列表里出现了你命名的VPN配置，
选中，连接，大功告成。

## 参考资料
* [https://www.digitalocean.com/community/tutorials/how-to-configure-bind-as-a-caching-or-forwarding-dns-server-on-ubuntu-16-04](https://www.digitalocean.com/community/tutorials/how-to-configure-bind-as-a-caching-or-forwarding-dns-server-on-ubuntu-16-04)
* [https://www.digitalocean.com/community/tutorials/how-to-set-up-an-ikev2-vpn-server-with-strongswan-on-ubuntu-16-04](https://www.digitalocean.com/community/tutorials/how-to-set-up-an-ikev2-vpn-server-with-strongswan-on-ubuntu-16-04)
* [https://www.proxyrack.com/blog/how-to-setup-ikev2-strongswan-vpn-server-on-ubuntu-for-ios-iphone/](https://www.proxyrack.com/blog/how-to-setup-ikev2-strongswan-vpn-server-on-ubuntu-for-ios-iphone/)
* [https://sosonemo.me/strongswan-to-shadowsocks.html](https://sosonemo.me/strongswan-to-shadowsocks.html)
* [http://ahhqlrg.blog.163.com/blog/static/105928805201561033936351/](http://ahhqlrg.blog.163.com/blog/static/105928805201561033936351/)
* [https://www.digitalocean.com/community/tutorials/how-the-iptables-firewall-works](https://www.digitalocean.com/community/tutorials/how-the-iptables-firewall-works)
* [https://www.digitalocean.com/community/tutorials/how-to-set-up-a-firewall-using-iptables-on-ubuntu-14-04](https://www.digitalocean.com/community/tutorials/how-to-set-up-a-firewall-using-iptables-on-ubuntu-14-04)
