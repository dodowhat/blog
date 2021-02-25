---
title: 在Windows下编码，Linux下运行——解决方案
layout: post
updated_at: 2019-04-21
---

## 2019-04-21更新

来到9102年，我重新折腾了一下开发环境，有了更好的选择，请参考我的新文章：

[通过设置NAT网络为Hyper-V虚拟机配置静态IP](/2019/04/18/how-to-setup-static-ip-for-hyper-v-virtual-machine-via-nat.html)

以下为原文

---

## 需求背景
多数情况下人们自家的电脑都是Windows系统，主娱乐。
而在Windows平台下某些编程语言的开发体验并不理想（例如：Ruby）。
有时却又难免会遇到一些紧急情况，比如项目出了点问题需要立即解决等等。
为了能兼顾娱乐与开发，如何在以Windows为主系统的前提下，实现：
在Windows系统上编码，平滑地转到Linux系统下运行测试，本文便是关于解决方案的探讨。

## 方案概述
利用虚拟机软件创建Linux系统虚拟机，并与Windows主机共享文件夹，实现在Windows下编码，Linux下运行。

## 开始前准备
  * 本机系统环境： Windows 10 64位
  * Linux系统镜像：[Ubuntu Server](https://www.ubuntu.com/download/server)
  * 虚拟机软件：[VirtualBox](https://www.virtualbox.org/wiki/Downloads)

## 一、安装VirtualBox
傻瓜式安装。

## 二、创建、配置虚拟机
点击`新建`，为虚拟机起一个名称，选择系统类型及版本，连续点击`下一步`直到完成创建；

选中创建好的虚拟机，点击`设置`，选择`存储`，选中`控制器IDE`下面的光盘图标，
在右侧的窗口点击光盘图标，选择文件，加载下载好的Linux系统镜像。

> 创建虚拟机时，如果`版本选择`列表里没有64位选项，只有32位选项，
> 是因为主板BIOS的`虚拟化技术`选项没有开启。开启方法：重启电脑进入BIOS，
> 找到`Virtualization Technology`选项，设置为`enable`，保存重启。

## 三、启动虚拟机，安装Linux系统
网上相关教程有很多，不赘述。

## 四、配置Linux系统

### 本机与虚拟机文件夹共享
实现这个需求有两种方案：

#### 方案一（推荐）
在虚拟机Linux系统中运行Samba文件共享服务，在本机Windows系统中映射虚拟机共享的目录到本地磁盘。

#### 方案一实现
首先，安装samba服务

    sudo apt-get install samba

编辑samba配置文件

    sudo vim /etc/samba/smb.conf

因为是给自己用，所以简单一点直接把家目录共享出来

    [homes] # 找到这一行，修改以下配置
      comment = Home Directories
      browseable = no
      read only = no
      create mask = 0700
      directory mask = 0700
      valid users = your-username # 这里改成你的linux登录用户名

保存退出。接着为samba添加用户，samba有自己用户管理系统，添加的用户必须是已存在于linux的用户，
这里我们就把上一步里的valid users也就是你的linux登录用户添加进来

    sudo smbpasswd -a your-username

重启服务

    sudo service smbd restart

回到Windows，打开文件管理器，点击`此电脑`，在上方菜单里点击`计算机-映射网络磁盘`，输入路径

    \\192.168.0.200\your-username # 你的虚拟机ip和用户名

完成。

#### 方案二
在虚拟机Linux上安装VirtualBox Guest Additions工具，然后在VirtualBox管理界面设置好
Windows系统要共享的文件夹，接着回到虚拟机Linux系统上挂载设置好的共享文件夹。

#### 方案二缺点
共享的文件夹实际是Windows文件系统的文件夹，在某些情况下会表现异常，下面来举个实例，也是我之所以换到方案一的原因。

本文以Markdown格式撰写，由Jekyll生成。在写作过程中，可以通过执行`jekyll serve`命令运行
一个本地服务实时地检测文档内容变化并生成最新的预览网页，这个过程在正常的Linux文件系统下是没有
问题的，运行命令开启服务后你就可以安心写作，保存文件然后在浏览器窗口刷新页面就可以即时看到变化。
~~但在方案二下自动重新生成功能并不能正常工作，需要不断地手动执行命令去生成预览网页，极大地影响写作效率。~~
后来又查了查相关资料，这个问题在VirtualBox或Vagrant上普遍出现，
说是在服务启动时加上`--force_polling`参数就可以解决了，我没有去验证，因为现在用的方案一。
不过这也足以说明方案二这种共享方式存在一定的缺陷。

#### 方案二实现

在本机Windows系统VirtualBox安装目录找到
`C:\Program Files\Oracle\VirtualBox\VBoxGuestAdditions.iso`，
用Bitvise SSH Client自带的SFTP工具将ISO文件传到虚拟机Linux系统，然后挂载：

    sudo mount ~/VBoxGuestAdditions.iso /mnt

运行其中的`VBoxGuestAdditions.run`：

    sudo /mnt/VBoxGuestAdditions.run

稍等片刻会自动完成安装，接着重启虚拟机系统使之生效：

    sudo reboot

回到虚拟机管理界面，选中虚拟机，点击`设置`，选择`共享文件夹`，选择要共享的文件夹，为它起一个名称，
用来在虚拟机Linux系统内识别，假设名称设置为`win10share`，勾选`固定分配`，完成。

接着回到虚拟机Linux系统，执行：

    sudo mount -t vboxsf win10share ~/linux_share

至此，本机Windows系统与虚拟机Linux系统可以同时对共享文件夹内的文件进行操作，
“在Windows下编码，Linux下运行”这一需求已经实现。

## 五、优化配置，提升易用性
上文只是最基本地实现了需求，在易用性上欠佳。如果重启了虚拟机或者本机，会遇到两个问题：
* 虚拟机的IP可能发生变动，如果你是用SSH客户端连接的话那么配置就需要频繁修改。
* 如果共享方式是方案二，需要重新在虚拟机Linux系统内挂载共享文件夹

针对这两个问题，进行如下配置

### 为虚拟机Linux系统配置固定IP
首先回到VirtualBox管理界面，点击`设置`，选择`网络`，将`网卡1`的连接方式改为`桥接网卡`。

接着回到虚拟机Linux系统，编辑`/etc/network/interfaces`，找到：

    iface enp0s3 inet dhcp

替换为：

    iface enp0s3 inet static
    address 192.168.0.200 # 此虚拟电脑的固定IP，网段与本机Windows系统保持一致
    netmask 255.255.255.0 # 子网掩码，与本机Windows系统保持一致
    gateway 192.168.0.1 # 网关，与本机Windows系统保持一致
    dns-nameservers 192.168.0.1 # DNS服务器，填写网关地址即可

保存并重启系统`sudo reboot`使配置生效，然后把刚设置好的固定IP配置到SSH客户端，以后连接就不
需要每次先查看虚拟机的IP是多少了。

### 为共享文件方案二配置开机自动挂载Windows共享文件夹
编辑`/etc/fstab`，添加：

    win10share /home/yourusername/linux_share vboxsf noauto,comment=systemd.automount,rw,uid=1000,gid=1000 0 0

保存重启生效


### 启动无窗口虚拟机
每次连接虚拟机都需要保持它的窗口开着，有时候Alt-Tab切换窗口时不小心切换到虚拟机窗口
以后就切不出去了，因为在命令行界面Alt-Tab键就失效了，影响工作效率与心情。

VirtualBox自带命令行管理的方式，可以用命令来启动无窗口虚拟机。新建一个
空文件，写入以下命令（假设你的虚拟机名称为`ubuntu`）：

    C:\Program Files\Oracle\VirtualBox\VBoxManage.exe startvm ubuntu -type headless

将文件后缀保存为`.cmd`，以后只需要双击此文件，稍等片刻，虚拟机就会在后台启动，没有碍眼的窗口了。

如果想把.cmd文件放到开始菜单，在桌面空白处右击鼠标，选择*新建-快捷方式*，输入：

    cmd.exe /c "D:\start_ubuntu_vm.cmd"

单击`下一步`，为快捷方式取个名字，点击`完成`。接着对着新创建好的快捷方式右击鼠标，
选择`固定到开始菜单`，结束。

到此，就可以直接从开始菜单一键启动虚拟机，然后打开SSH客户端进行操作了。

完结撒花。

## 参考资料
* [https://wiki.debian.org/SambaServerSimple](https://wiki.debian.org/SambaServerSimple)
* [http://www.giannistsakiris.com/2008/04/09/virtualbox-access-windows-host-shared-folders-from-ubuntu-guest/](http://www.giannistsakiris.com/2008/04/09/virtualbox-access-windows-host-shared-folders-from-ubuntu-guest/)
* [https://superuser.com/questions/146763/my-virtualbox-fstab-will-not-auto-mount-on-reboot](https://superuser.com/questions/146763/my-virtualbox-fstab-will-not-auto-mount-on-reboot)
* [http://www.cnblogs.com/Aiziyou/p/3479283.html](http://www.cnblogs.com/Aiziyou/p/3479283.html)
* [http://winaero.com/blog/pin-a-batch-file-to-the-start-menu-or-taskbar-in-windows-10/](http://winaero.com/blog/pin-a-batch-file-to-the-start-menu-or-taskbar-in-windows-10/)
