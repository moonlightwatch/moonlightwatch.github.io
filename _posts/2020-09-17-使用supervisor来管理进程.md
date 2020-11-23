---
layout: post
title: 使用 supervisor 来管理进程
tags: [linux, supervisor,]
category: [运维笔记,]
excerpt: Supervisor是一个进程管理工具，可以启动、关闭、重启和监视进程
---

[Supervisor: A Process Control System](http://www.supervisord.org/)

Supervisor是一个进程管理工具，可以启动、关闭、重启和监视进程。


## 安装

一般情况下，系统默认的软件源里就有：

```bash
sudo yum install supervisor
# 或者
sudo apt-get install supervisor
```

## 组成

安装完成后，`supervisor` 会有两部分组成：一个是后台运行的服务叫 `supervisord`，另一个是命令行工具叫 `supervisorctl`。

## 启动

通过下述命令

```bash
sudo systemctl start supervisord
# 或者
sudo service supervisord start
```

启动 `supervisor` 的后台服务。

## 配置

主配置文件在：`/etc/supervisor/supervisord.conf`  

这个配置文件一般不用管，其详细说明在这里：[http://www.supervisord.org/configuration.html](http://www.supervisord.org/configuration.html)

### Web管理界面

如果有需要，可以看看主配置文件的这部分：[inet_http_server](http://www.supervisord.org/configuration.html#inet-http-server-section-settings)，这部分配置提供了一个基于HTTP基础认证的Web管理界面，拥有基本的启动、停止、重启和观察日志的功能。官方举例如下：

```bash
[inet_http_server]
port = 127.0.0.1:9001
username = user
password = 123
```

### 程序配置

如果需要supervisor对一个进程进行管理，则需要这部分配置：[program:x](http://www.supervisord.org/configuration.html#program-x-section-settings)

配置项很多，我列举一些常用的配置：

```bash
[program:cat] 
command=/bin/cat 
directory=/tmp 
autostart=true 
autorestart=true 
environment=A="1",B="2"
stdout_logfile=/a/path 
stderr_logfile=/a/path  
```

逐行解释：

```bash
[program:cat]           ; 这行设置了程序名称为 cat，supervisor通过此名称对此进程进行管理
command=/bin/cat        ; 这行是此进程的主程序，可以直接带参数
directory=/tmp          ; 这行是此进程的工作目录，程序中的相对目录以此为起点
autostart=true          ; 这行指定程序是否随 supervisor 一起启动
autorestart=true        ; 这行指定程序退出后是否由 supervisor 自动重启
environment=A="1",B="2" ; 这行指定程序运行的环境变量，不影响已经存在的系统环境变量
stdout_logfile=/a/path  ; 指定程序从标准输出流输出的内容，应该存储于何处（文本文件）
stderr_logfile=/a/path  ; 指定程序从标准错误流输出的内容，应该存储于何处（文本文件）
```

### 子配置文件

在主配置文件的末尾，一般会有一个 `[include]`，这里指定了子配置文件的位置。CentOS系统一般是 `/etc/supervisord.d/*.ini`，Ubuntu系统一般是 `/etc/supervisord/conf.d/*.conf`。  

这个配置表示主配置文件讲包含指定目录下的指定后缀名的文件。

**一般实践**里，我们会将 “程序配置” 中讲的 `[program:x]` 部分，写在子配置文件中。每一个被管理的进程，分别写入一个配置文件，这样方便管理。


## 管理


### 基本管理

管理操作，主要通过 `supervisorctl` 命令来完成。其提供了如下命令：

```bash
supervisorctl status        //查看所有进程的状态
supervisorctl stop x        //停止x
supervisorctl start x       //启动x
supervisorctl restart x     //重启x
supervisorctl update        //配置文件修改后使用该命令加载新的配置
supervisorctl reload        //重新启动配置中的所有程序
```

上述 `start`、`stop`、`restart` 后跟的参数 `x` 指的是配置文件中 `[program:x]` 所指定的进程。或者也可以 `supervisorctl status` 来观察所有被管理进程的名称。  
`supervisorctl status` 将输出所有被管理进程的 “名称”、“状态”、“详细信息”。


**需要注意**的是，在*增加*或者*修改*了配置文件后，需要 `supervisorctl update` 来使配置文件生效。

### 交互式命令行

如果仅执行 `supervisorctl` 不加任何参数，则会进入 一个提示符为 `supervisor\u003e` 的交互式命令行。  

此交互式命令行中，可以不加 `supervisorctl` 前缀，直接执行 `start`、`stop`、`restart` 等操作。

### 日志

如果你在配置文件中指定了 `stdout_logfile` 那么就在这个参数指定的位置能看到程序输出的内容，或者执行 `supervisorctl tail -f x` 观察命名为 `x` 的程序的输出。这个操作当然也能在交互式命令行中使用。  
Ctrl+C 组合键退出观察。

## 使用场景

1. 需要一个程序长期运行
2. 需要一个程序长期运行，且在意外退出后还能再启动
3. 需要一个程序长期运行，且能随系统启动
4. 程序需要一个守护进程来管理