---
layout: post
title: 关于 Windows10 中 python 命令会启动应用商店的解决方法
tags: [windows, python]
category: [应用实践,]
excerpt: Windows10 中 python 命令会启动应用商店的解决方法
---

网上看了一圈，都是要修改环境变量和注册表，实际上完全没必要。

## 原因

原因应该是 Windows10 的应用商店，上架了Python3，而应用商店自作主张地将命令 `python.exe` 和 `python3.exe` 重定向到了应用商店。

## 解决

按下述操作：

启动菜单 > Windows设置 > 应用 > 应用和功能 > 应用执行别名

在 “管理应用执行别名” 界面，关闭里面两个关于 python 的 “应用安装程序” 即可。
***
或者直接在 “Windows设置” 界面搜索：“管理应用执行别名”

![搜索应用执行别名](/assets/images/关于Windows10中python命令会启动应用商店的解决方法/633984886.png)

然后将下述两个圈出来的选项关掉。

![关闭应用执行别名](/assets/images/关于Windows10中python命令会启动应用商店的解决方法/740098904.jpg)

***

然后世界就和谐了。