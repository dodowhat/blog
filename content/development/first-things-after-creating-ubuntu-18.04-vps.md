---
title: Ubuntu 18.04 VPS 创建后的初始化工作
date: 2019-05-31T20:45:17+08:00
---

前段时间阿里云搞活动，入了一年的轻量云服务器，在此记录一下创建VPS后的一系列初始化工作。

本文操作带有浓重个人色彩，仅供参考。

## 1. 升级系统

系统我选择了Ubuntu，阿里云最高只提供16.04版本镜像。

通过控制台面板远程连接，系统提示可以升级到18.04，所以第一件事就是升级系统：

    sudo su root
    do-release-upgrade

升级期间会有几次选项提示，是关于是否覆盖旧配置文件的，因为是新安装的系统，没有顾虑，统统输入Y并且回车。

## 2. 卸载安骑士(可选)

注意：执行此操作后会导致一些通过面板操作VPS的功能失效，比如重置密码。

参考 [卸载阿里云盾（安骑士）监控&屏蔽云盾IP](https://github.com/ssrpanel/SSRPanel/wiki/%E5%8D%B8%E8%BD%BD%E9%98%BF%E9%87%8C%E4%BA%91%E7%9B%BE%EF%BC%88%E5%AE%89%E9%AA%91%E5%A3%AB%EF%BC%89%E7%9B%91%E6%8E%A7&%E5%B1%8F%E8%94%BD%E4%BA%91%E7%9B%BEIP)


## 3. 创建新用户，配置SSH客户端密钥登录

服务器不建议直接通过root账户管理。

阿里云控制台面板的远程连接使用的是admin账户，建议不要直接使用这个用户，留着急救用就可以了。

通过命令创建新用户

    adduser YourUsername # 根据提示完成命令

为新建账户配置sudo。编辑`/etc/sudoers`，在末尾添加新行

    YourUsername ALL=(ALL) NOPASSWD:ALL

切换到新用户

    sudo su YourUsername

创建SSH密钥

    ssh-keygen
    cp ~/.ssh/id_rsa.pub ~/.ssh/authorized_keys

用SFTP工具下载`~/.ssh/id_rsa`私钥文件到本地，配置SSH客户端用私钥登录VPS

## 4. 个性化配置

配置Bash PS1。编辑`~/.bashrc`，末尾添加：

    echo 'export PS1="\[\033[38;5;11m\]\u\[$(tput sgr0)\]\[\033[38;5;15m\]@\h:\[$(tput sgr0)\]\[\033[38;5;6m\][\w]:\[$(tput sgr0)\]\[\033[38;5;15m\] \[$(tput sgr0)\]"' >> ~/.bashrc

此配置来自 [http://bashrcgenerator.com/](http://bashrcgenerator.com/)

配置Vim，参考 [https://github.com/dodowhat/vim_runtime](https://github.com/dodowhat/vim_runtime)
    
## 5. 安装Ruby环境

安装编译Ruby必要类库

    sudo apt-get install -y build-essential libssl-dev libreadline-dev zlib1g-dev

安装`rbenv` `rbenv-build`，参考 [https://github.com/rbenv/rbenv](https://github.com/rbenv/rbenv)

完毕。
