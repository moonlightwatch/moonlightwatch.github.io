---
layout: post
title: 在Docker容器中启动sshd服务
tags: [sshd,docker,容器]
category: [运维笔记,]
excerpt: 在Docker容器中启动sshd服务
---

一般情况下我们并不需要在docker中启动sshd服务，但是会有一些情况必须使用。  

此文记录一下sshd服务的启动过程。

## 实验环境

使用 centos 作为基础镜像，其他镜像大同小异。

启动实验环境：

```
docker run -itd -p 6022:22 --name=sshd centos bash
```

需要注意两点：

1. 映射容器的22端口到宿主的6022，以便稍后连接测试。
2. 使bash作为启动进程，以避免容器停止。

## 安装sshd

使用 `docker exec` 进入容器：

```
docker exec -it sshd bash
```

在容器中安装 `openssh-server`：

```
yum install openssh-server -y
```

## 启动sshd

安装完成后，可以直接启动：

```
/usr/sbin/sshd
```

需要注意的是，这里必须使用绝对路径。

直接启动的话，会报如下错误：

```
[root@3f011b4d3e77 /]# /usr/sbin/sshd
Unable to load host key: /etc/ssh/ssh_host_rsa_key
Unable to load host key: /etc/ssh/ssh_host_ecdsa_key
Unable to load host key: /etc/ssh/ssh_host_ed25519_key
sshd: no hostkeys available -- exiting.
```

需要先生成各种key：

```
ssh-keygen -A
```

然后再通过命令 `/usr/sbin/sshd` 启动即可。

这个命令不会返回数据，也不会占用终端。通过 `ps` 命令即可观察到 `sshd` 服务已经启动。

```
[root@3f011b4d3e77 /]# ssh-keygen -A
ssh-keygen: generating new host keys: RSA DSA ECDSA ED25519
[root@3f011b4d3e77 /]# /usr/sbin/sshd
[root@3f011b4d3e77 /]# ps -aux
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.0  0.0  12024  3240 pts/0    Ss+  08:07   0:00 bash
root        15  0.0  0.0  12128  3292 pts/1    Ss   08:07   0:00 bash
root       104  0.0  0.0  76496  3156 ?        Ss   08:12   0:00 /usr/sbin/sshd
root       105  0.0  0.0  47544  3524 pts/1    R+   08:12   0:00 ps -aux
```

进程列表中，1号进程，就是docker容器的启动进程，我们使用的是bash。其中 第二个 bash 进程是我们使用 `docker exec` 启动的当前正在操作的 bash。第三个便是我们启动的 `sshd` 服务。


## 登录

在登录前，需要先修改root密码。

先安装 `passwd` 工具，centos 容器里面并没有默认携带。

```
yum install passwd -y
```

然后修改root密码：

```
passwd root
(输入两遍密码)
passwd: all authentication tokens updated successfully.
```

使用宿主机的shell，开始尝试登录，按照正常的ssh登录流程：

```
$ ssh -p 6022 root@127.0.0.1
The authenticity of host '[127.0.0.1]:6022 ([127.0.0.1]:6022)' can't be established.
ECDSA key fingerprint is SHA256:gSv124z+lq26VuVwHnOIF/O/IirycePlcuKJEe0WcSw.
Are you sure you want to continue connecting (yes/no/[fingerprint])? yes
Warning: Permanently added '[127.0.0.1]:6022' (ECDSA) to the list of known hosts.
root@127.0.0.1's password:
"System is booting up. Unprivileged users are not permitted to log in yet. Please come back later. For technical details, see pam_nologin(8)."
[root@3f011b4d3e77 ~]# ps -aux
USER       PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root         1  0.0  0.0  12024  3240 pts/0    Ss+  08:07   0:00 bash
root        15  0.0  0.0  12128  3292 pts/1    Ss+  08:07   0:00 bash
root       104  0.0  0.0  76496  3156 ?        Ss   08:12   0:00 /usr/sbin/sshd
root       116  0.1  0.0 124128  9124 ?        Ss   08:17   0:00 sshd: root [priv]
root       118  0.0  0.0 124128  5648 ?        R    08:18   0:00 sshd: root@pts/2
root       119  0.0  0.0  12024  3248 pts/2    Ss   08:18   0:00 -bash
root       132  0.0  0.0  47544  3516 pts/2    R+   08:18   0:00 ps -aux
```
即可看到，我们已经登录成功。
