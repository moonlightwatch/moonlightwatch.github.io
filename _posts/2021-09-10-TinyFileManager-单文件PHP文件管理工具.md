---
layout: post
title: 【Tiny File Manager】 基于PHP的文件管理工具
tags: [FileManager,php,文件管理,单文件,]
category: [工具分享,]
excerpt: Tiny File Manager 基于PHP的文件管理工具
---


官网链接：[https://tinyfilemanager.github.io/](https://tinyfilemanager.github.io/)

## 介绍

> Web based File Manager in PHP, Manage your files efficiently and easily with Tiny File Manager and it is a simple, fast and small file manager with a single file.

用PHP实现的基于Web的文件管理器，您可以使用Tiny File Manager高效、轻松地管理您的文件。它是一个简单、快速的小型文件管理器，并且只需一个文件。


## 特点

1. 基于Web的文件管理器
2. 可以单文件部署
3. 拥有简单的用户和权限管理
4. 支持多语言
5. 比 nginx 的 autoindex 好看多了！！


## 使用

### 安装

从 [https://github.com/prasathmani/tinyfilemanager](https://github.com/prasathmani/tinyfilemanager) 下载文件，或者直接复制 `tinyfilemanager.php` 文件到Web应用文件夹。然后直接访问即可。

### 配置

配置文件在同级目录下的 `config.php` 文件里。核心配置如下：

```
$auth_users = array(
    'admin' => password_hash('666', PASSWORD_DEFAULT), 
    'user' => password_hash('pwd', PASSWORD_DEFAULT) 
);

//set application theme
//options - 'light' and 'dark'
$theme = 'dark';

// Readonly users
// e.g. array('users', 'guest', ...)
$readonly_users = array(
    'user'
);
```

通过 `$auth_users` 可以添加用户。  
通过 `$readonly_users` 控制用户权限，指定用户为：只读用户。  
通过 `$theme` 选择 `light` 或者 `dark` 模式。  



## 外观
![黑暗模式](/assets/images/TinyFileManager/TinyFileManager黑暗模式.png)



