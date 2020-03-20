---
layout: post
title: Virtualbox虚拟机配置静态IP
updated_at: 2019-06-01
---

## 2019-11-29更新

现在又用回WSL了，叹气。。。

以下为原文

## 背景

自前一篇文章[通过设置NAT网络为Hyper-V虚拟机配置静态IP](/2019/04/18/how-to-setup-static-ip-for-hyper-v-virtual-machine-via-nat.html)，开发环境换到Hyper-V以来，时隔一个月，它就出问题了。

起因是创建虚拟机时硬盘容量设置为10GB，使用过程中很快就满了，于是我不得不去找扩容的方法。方法找到了，正准备实施的时候，就发现Hyper-V出问题了，具体表现为不能通过自带的连接管理器连接虚拟机，如下图：

![hyper-v-cannot-connect-to-vm.png](/assets/post_images/hyper-v-cannot-connect-to-vm.png)

虚拟机是可以正常启动/关闭/运行的，因为平时都是使用SSH方式连接的，所以一直没发现这个问题，直到此时。

按照教程关闭并重新开启Hyper-V功能之后正常了，但是好景不长，没一会儿问题又出现了，不知道是什么操作引起的，Google了一圈基本无解，于是只能再折腾一番用回Virtualbox。

关于虚拟机硬盘扩容，本来也想把这波操作记录下来的，不过网上资料很多，就不重复造轮子了。关键词：`Virtualbox扩容` `Hyper-V扩容`等等。

## 正文

创建虚拟机以及安装系统的过程就不赘述了，系统用的是Ubuntu Server 18.04 LTS。

创建Host-only(仅主机)网络，如图：

![virtualbox-create-host-only-network.png](/assets/post_images/virtualbox-create-host-only-network.png)

接着进入虚拟机网络设置，如图：

![virtualbox-vm-network-settings.png](/assets/post_images/virtualbox-vm-network-settings.png)

Adapter 1(适配器)保持默认的NAT，Adapter 2设置为Host-only，Name(名称)选择我们上一步创建的网络。

接下来启动系统。编辑`/etc/netplan/99_config.yml`(更多说明请参考开头提到的前篇文章)：

    network:
      version: 2
      ethernets:
        enp0s3: # 这是Adapter 1
            dhcp4: true
        enp0s8: # 这是Adapter 2
          addresses:
            - 192.168.56.78/24 # 设置成我们想要的固定IP，这里的78可以是2~254之间任意的数字
          nameservers: # DNS服务器地址，如果不配置此项，将不能访问互联网，这里我用的是阿里云DNS
            addresses: [223.5.5.5, 223.6.6.6]

保存退出，接着执行`sudo netplan apply`使网络配置生效。之后就可以用SSH连接`192.168.56.78`访问虚拟机了。

过程比Hyper-V简单好多。

## 参考链接

[How to Disable Hyper-V in Windows 10?](https://ugetfix.com/ask/how-to-disable-hyper-v-in-windows-10/)

[How do i assign Ubuntu 18.04 a static ip, its in a virtual machine using VMware and host is Windows](https://unix.stackexchange.com/questions/457064/how-do-i-assign-ubuntu-18-04-a-static-ip-its-in-a-virtual-machine-using-vmware)

[Use GParted to increase disk size of a Linux native partition](https://www.rootusers.com/use-gparted-to-increase-disk-size-of-a-linux-native-partition/)
