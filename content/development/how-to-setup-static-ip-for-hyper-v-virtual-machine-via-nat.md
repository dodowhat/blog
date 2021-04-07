---
title: 通过设置NAT网络为Hyper-V虚拟机配置静态IP
date: 2019-04-18T20:45:17+08:00
tags: ["Virtual Machine"]
---

## 背景

在Windows10上搭建Linux开发环境。

## 方案

Hyper-V + Ubuntu Server 18.04

Hyper-V是Windows平台下的一款虚拟机软件，内置于Windows10专业版/企业版/教育版，类似于VMware/VirtualBox。

关于如何开启Hyper-V，创建虚拟机，以及安装系统，相关资料很多，就不赘述了。

## 本文重点

按照正常流程安装好虚拟机后，默认情况下，虚拟机每次启动时，Hyper-V默认的虚拟交换机(虚拟网卡)会动态分配IP给虚拟机，这个IP是变化的，每次不同，不利于我们通过SSH管理虚拟机。

我们希望的是：

* 虚拟机为固定IP

* 无论宿主机网络环境如何变化，虚拟机网络配置都无需变动

* 宿主机可以访问虚拟机(例如：SSH连接)

* 虚拟机可以访问互联网

## 正篇

为了实现上述目标，需要两步：

1. 在宿主机创建自定义虚拟网卡，设置NAT虚拟网络，指定网段，替换Hyper-V默认虚拟网卡。

2. 在虚拟机系统内部配置固定IP。

首先进行第一步。

### 1. 设置NAT虚拟网络

#### 1.1 新建虚拟交换机(虚拟网卡)

在开始菜单搜索hyper-v manager(Hyper-V管理器)并打开(示例为英文界面，该操作对中文界面同样适用，下同)。

![start-menu-hyper-v-manager](/assets/post_images/start-menu-hyper-v-manager.png)

找到Virtual Switch Manager(虚拟交换机管理器)并打开。

![open-virtual-switch-manager](/assets/post_images/open-virtual-switch-manager.png)

选择New virtual network switch(新建) --> Internal(内部) --> Create Virtual Switch(创建)。

![create-virtual-switch](/assets/post_images/create-virtual-switch.png)

这个虚拟网卡就是我们的NAT网关。

#### 1.2 配置NAT网关

打开Control Panel(控制面板) --> Network and Sharing Center(网络与共享中心) --> change adapter settings(更改适配器设置)

![network-and-sharing-center](/assets/post_images/network-and-sharing-center.png)

以vEthernet开头的是Hyper-V创建的虚拟网卡，左面的是开启Hyper-V时默认创建的，右面的是我们刚才自己创建的。

对着我们自己创建的虚拟网卡右键 --> Proerties(属性)。

选中Internet 协议版本 4 (TCP/IPv4)，点击Proerties(属性)。

![change-adapter-settings](/assets/post_images/change-adapter-settings.png)

按下图设置IP address(IP地址)与Subnet musk(子网掩码)。

一般我们家里的路由器网段都是`192.168.0.X` `192.168.1.X`等等，这里我们设定成一个和它们不冲突的网段，比如`192.168.79.X`。

![internet-protocol-v4-properties](/assets/post_images/internet-protocol-v4-properties.png)

这样，NAT网关就配置好了。

#### 1.3 设置NAT网络

右键开始菜单，以管理员身份运行PowerShell。

![start-menu-powershell](/assets/post_images/start-menu-powershell.png)

运行以下命令：

    New-NetNat -Name MyNATnetwork -InternalIPInterfaceAddressPrefix 192.168.79.0/24

![powershell-new-netnat](/assets/post_images/powershell-new-netnat.png)

这里的`192.168.79.0/24`是子网掩码的另一种表示方法，`/24`等同于`255.255.255.0`，具体请参考相关网络基础知识。

注：这样的NAT网络我们只能创建一个，但我们可以使多个虚拟机都连接到这个NAT网络，具体原因请参考微软官方文档。

如果忘记自己是否设置过NAT网络，可以先运行命令查看并删除：

    Get-NetNat | Remove-NetNat

#### 1.4 更改虚拟机网络适配器

最后将虚拟机的网络适配器改为我们自己创建的虚拟网卡。

右键虚拟机 --> Settings(设置)。

![open-virtual-michine-settings](/assets/post_images/open-virtual-michine-settings.png)

![change-network-adapter](/assets/post_images/change-network-adapter.png)

这样，NAT网络就设置好了，第一步完成。

### 2. 配置虚拟机固定IP

本文以Ubuntu Server 18.04 LTS为例，其它版本请参考相应的官方文档。

在开始配置IP之前，会遇到另一个问题，在启动虚拟机时，开机过程会卡在某一步上，并有如下提示：

    A start job is running for wait for network to be configured.

不用着急，耐心等待2分钟后就会继续开机过程，后文的配置会解决这个问题。

Ubuntu 18.04采用netplan来配置网络，不再使用`/etc/network/interfaces`。

通过向`/etc/netplan/`添加YAML文件来配置静态IP：

    sudo vim /etc/netplan/99_config.yaml

配置文件内容如下：

    network:
      version: 2
      ethernets:
        eth0:
          addresses:
            - 192.168.79.89/24 # 设置成我们想要的固定IP，这里的89可以是2~254之间任意的数字
          gateway4: 192.168.79.1 # 这里的地址是我们创建虚拟网卡时设置的地址
          nameservers: # DNS服务器地址，如果不配置此项，将不能访问互联网，这里我用的是阿里云DNS
            addresses: [223.5.5.5, 223.6.6.6]
          optional: true

其中`optional: true`就是解决前面说的开机等待2分钟问题的配置项。
原因简单来说就是默认情况下netplan在开机过程中会等待网卡自动配置好(DHCP)，
然而我们创建的NAT网络除了前面提到的只能创建这一个以外，还有一个问题就是不会自动分配地址给虚拟机。
所以netplan就一直等啊等直到超时，开启这个选项之后，netplan就不会等待这块网卡被自动配置了。

编辑完成后，执行命令使配置生效：

    sudo netplan apply

到此，第二步也完成了。现在可以愉快地用SSH客户端连接我们刚才配置好的固定IP来操作虚拟机了。

## 局域网内其它设备如何访问NAT网络下的虚拟机

假设我们正在开发一个手机版网页，需要在手机上即时浏览到显示效果，就需要让手机能访问到虚拟机。

正如本小节的标题所说，在目前的情况下，局域网内的其它设备想要访问`192.168.79.89`是行不通的。

如果虚拟机的虚拟网卡是桥接模式的，就不存在这种问题了，但那样的话又实现不了配置固定IP，所以还是要在当前情境下寻找解决办法。

一个临时解决方案就是在宿主机上配置端口转发。

右键开始菜单，以管理员身份运行PowerShell，执行：

    netsh interface portproxy add v4tov4 listenaddress=宿主机IP地址 listenport=宿主机端口 connectaddress=虚拟机IP地址 connectport=虚拟机端口

假设我们开发的应用运行在虚拟机`8080`端口上，那么就执行：

    netsh interface portproxy add v4tov4 listenaddress=0.0.0.0 listenport=8080 connectaddress=192.168.79.89 connectport=8080

这里的宿主机端口不一定要与虚拟机端口一致，可以任意指定其它端口，只要没有被占用就可以了。

接下来在手机浏览器上输入宿主机IP地址和我们刚才指定的端口就可以访问到应用了。

执行以上步骤请先确保已经在Windows10防火墙里开放了你要设置的端口。

如何关闭端口转发，执行命令：

    netsh interface portproxy delete v4tov4 listenaddress=0.0.0.0 listenport=8080

如果忘记了之前设置过的端口转发，可以通过命令查看：

    netsh interface portproxy show all

## 实现在Windows下编码，Linux下运行

系统环境搞好了，如何舒适地编码以及运行呢？答案是`X11 Forwarding`。

Linux下的视窗系统提供了一个通过SSH连接运行Linux下的GUI程序的功能，即`X11 Forwarding`。
通过这种方式打开的程序体验上如同我们在本机Windows系统上打开了一个其它软件窗口一样。
如果不是刻意区分，我们甚至意识不到这是实际上运行在远程Linux机器上的程序。
它和我们在Windows上打开的其它程序一样，可以用Alt + Tab切换，使用本机的剪贴板等等。

那么如何使用它呢？如果发生版选用的是Ubuntu Server 18.04 LTS，那么不用做任何特殊操作，仅仅把你想用的GUI程序安装好就可以了，比如这样：
    
    sudo apt install vim-gtk

然后在Windows上使用一款支持`X11 Forwarding`的SSH客户端开启这个功能并且像以前一样连接Linux就好了，比如`MobaXterm`，然后像平常一样执行命令打开程序：

    gvim

GVim就在Windows上打开了。你也可以安装并打开浏览器、文件管理器什么的，whatever。

客户端我使用的是[Putty](https://www.chiark.greenend.org.uk/~sgtatham/putty/) + [VcXsrv](https://sourceforge.net/projects/vcxsrv/)

## 解决中文输入问题

通过`X11 Forwarding`运行的程序虽然看起来像是运行在Windows上的普通程序，但是用不了Windows上的输入法，我们需要在虚拟机上安装输入法以及中文字体：

    sudo apt install xfonts-wqy
    sudo apt install fcitx

因为没有桌面环境，并且我们是通过远程登录的方式使用虚拟机的，fcitx并不会自动启动，需要做一些配置，编辑`~/.bashrc`，在末尾添加：

    fcitx > /dev/null 2>&1

为避免与Windows上的切换输入法快捷键冲突，运行`fcitx-configtool`将切换输入法快捷键改为`shift + space`，完毕。

## 2019-05-04更新

计划赶不上变化，刚折腾好这些没几天，VSCode编辑器就宣布支持远程开发了，支持物理机、虚拟机、容器以及WSL。不过目前还只限于Insiders版本，这一小段文章更新就是在VSCode Insiders远程开发扩展下完成的，体验挺好，估计正式版也不远了。

附文档链接：[https://code.visualstudio.com/docs/remote/remote-overview](https://code.visualstudio.com/docs/remote/remote-overview)

## 参考链接

[Hyper-V Set up a NAT network](https://docs.microsoft.com/en-us/virtualization/hyper-v-on-windows/user-guide/setup-nat-network)

[Ubuntu 18.04 Network Configuration](https://help.ubuntu.com/lts/serverguide/network-configuration.html.en)

[Netplan reference](https://netplan.io/reference)

[How Is Developing on a Linux VM in Windows?](https://news.ycombinator.com/item?id=13088755)

[使用Windows命令来实现端口转发](http://foreversong.cn/archives/1117)
