---
layout: post
title: Traefik 自定义Service 开发纪要
tags: [golang,traefik]
category: [代码笔记,]
excerpt: 如何在Traefik中开发一个自定义Service
---


## Service 定义
[https://doc.traefik.io/traefik/routing/services/](https://doc.traefik.io/traefik/routing/services/)

The `Services` are responsible for configuring how to reach the actual services that will eventually handle the incoming requests.



## Service 特点


1. Service是Traefik流程中最后处理请求的位置（中间件在此之前处理请求）
2. Service可以控制请求直接到达源站（中间件做不到）
3. Service可以对请求进行修改（中间件也可以）



## Traefik 官方自带的 Service
官方自带了三个 Service：

1. 流量镜像
2. 负载均衡（同时实现了权重）



流量镜像的代码位于：/pkg/server/service/loadbalancer/mirror/mirror.go  

负载均衡代码位于：/pkg/server/service/loadbalancer/wrr/wrr.go



上述代码可以作为我们开发 Service 的参考。



## Service 开发要点


### 定义 Service 配置
Traefik 的配置解析，是直接映射（或者说反序列化）struct实现的，所有 Service 的配置都 属于 \`dynamic.Service\` 这个 struct 。这个 struct 位于：/pkg/config/dynamic/http\_config.go 

其定义如下：

```go
type Service struct {
	LoadBalancer *ServersLoadBalancer `json:"loadBalancer,omitempty" toml:"loadBalancer,omitempty" yaml:"loadBalancer,omitempty" export:"true"`
	Weighted     *WeightedRoundRobin  `json:"weighted,omitempty" toml:"weighted,omitempty" yaml:"weighted,omitempty" label:"-" export:"true"`
	Mirroring    *Mirroring           `json:"mirroring,omitempty" toml:"mirroring,omitempty" yaml:"mirroring,omitempty" label:"-" export:"true"`
}
```


按照 Traefik 已有的 Service 配置来看，我们自定义的 Service 所使用的配置也应该在 http\_config.go 文件中 

需要注意的是：

1. 自己新定义的配置，需要在 \`dynamic.Service\` 中新增一条属性。否则 配置不会被加载。
2. 定义的配置需要其他模块读取，应注意首字母大写，以保证可访问性
3. 需要正确填写tag，包括 json、yaml和toml三种序列化格式的名称，否则可能无法正确加载
4. 可以省略的参数，其定义应设置为指针类型，否则即是配置的必选项



举例，定义 白名单Service：

在 http\_config.go 中新增：

```go
type WhiteList struct {
	IPList      []string `json:"ipList,omitempty" toml:"ipList,omitempty" yaml:"ipList,omitempty"`
	Service     string   `json:"service,omitempty" toml:"service,omitempty" yaml:"service,omitempty" export:"true"`
	MaxBodySize *int64   `json:"maxBodySize,omitempty" toml:"maxBodySize,omitempty" yaml:"maxBodySize,omitempty" export:"true"`
}
```
在 http\_config.go 的 \`dynamic.Service\`  这个 struct 中添加 WhiteList：

```go
type Service struct {
	LoadBalancer *ServersLoadBalancer `json:"loadBalancer,omitempty" toml:"loadBalancer,omitempty" yaml:"loadBalancer,omitempty" export:"true"`
	Weighted     *WeightedRoundRobin  `json:"weighted,omitempty" toml:"weighted,omitempty" yaml:"weighted,omitempty" label:"-" export:"true"`
	Mirroring    *Mirroring           `json:"mirroring,omitempty" toml:"mirroring,omitempty" yaml:"mirroring,omitempty" label:"-" export:"true"`
	WhiteList    *WhiteList           `json:"whiteList,omitempty" toml:"whiteList,omitempty" yaml:"whiteList,omitempty" label:"-" export:"true"`
}

```
这个新增的 WhiteList 对应的配置（其中的maxBodySize可以不填）：

```yaml
http:
  services:
    my-whitelist:
      whiteList:
        iplist:
          - "127.0.0.1"
          - "192.168.0.0/24"
        maxBodySize: 2000
        service: example

    # Define how to reach an existing service on our infrastructure
    example:
      loadBalancer:
        servers:
        - url: "http://xxx.xxx.xxx.xxx:8888/"
```




### 定义 Service 的 Handler
接下来，需要定义 Service 的功能代码。按照 Traefik 已有的 Service 来看，其 Service 应定义在 /pkg/server/service/ 中。每个 Service 单独作为一个包存在。

欲新增 Service 则需要在 /pkg/server/service/ 下新建一个文件夹，并在其中新建文件。还是以 白名单 为例，结构如下（省略的其他无关部分）：

```Plain Text
├── pkg
│   └── server
│       └── service
│           └── whitelist
│               └── whitelist.go
```
创建好文件后，在其中添加代码，至少需要：

1. 规范包名
2. 包内有一个 New 函数，作为 Handler 的初始化函数。（当然可以使用其他名字，但是我们应该按照 Traefik 的规范来）
3. New 函数返回一个实现了 http.Handler 接口的对象。

大致如下（省略了所有功能，只保留代码结构）：

```go
package whitelist

import (
	"net"
	"net/http"

	"github.com/traefik/traefik/v2/pkg/config/dynamic"
)

// WhiteList is an http.Handler 用于实现白名单功能.
type WhiteList struct {
	......
}

// New returns a new instance of *WhiteList.
func New(config *dynamic.WhiteList) *WhiteList {
	return &WhiteList{}
}

func (w *WhiteList) ServeHTTP(rw http.ResponseWriter, req *http.Request) {
	w.handler.ServeHTTP(rw, req)
}
```
*注：*实现 http.Handler 接口，只需实现 `func ServeHTTP(http.ResponseWriter, *http.Request)` 即可



### 编写 Service 初始化代码
有了配置和代码实现，接下来就是在 Service 的初始化代码中，添加我们新增的 Service了。

核心代码位于：/pkg/server/service/service.go

需要关注 `func (m *Manager) BuildHTTP()` 这个方法，它由 Router 的初始化代码进行调用，用于初始化 Router 定义的 Service 。

我们需要在 `func (m *Manager) BuildHTTP()` 这个方法中实现对我们自定义 Service 的初始化。  



这个方法首先提取了 Service 的配置，然后通过其中的 switch 语句，对配置的存在性进行判断。通过后，开始构建 Service 实例。核心的代码如下：

```go
    switch {
	case conf.LoadBalancer != nil:
		var err error
		lb, err = m.getLoadBalancerServiceHandler(ctx, serviceName, conf.LoadBalancer)
		if err != nil {
			conf.AddError(err, true)
			return nil, err
		}
	case conf.Weighted != nil:
		var err error
		lb, err = m.getWRRServiceHandler(ctx, serviceName, conf.Weighted)
		if err != nil {
			conf.AddError(err, true)
			return nil, err
		}
	case conf.Mirroring != nil:
		var err error
		lb, err = m.getMirrorServiceHandler(ctx, conf.Mirroring)
		if err != nil {
			conf.AddError(err, true)
			return nil, err
		}
	default:
		sErr := fmt.Errorf("the service %q does not have any type defined", serviceName)
		conf.AddError(sErr, true)
		return nil, sErr
	}
```
可以看见，三种默认 Service，均定义了 `getxxxxxServiceHandler`  函数，用于初始化 Service 实例。我们也应该定义类似的方法，以保证上述代码简洁可读。

我们定义的函数如下：

```go
func (m *Manager) getIPWhiteListServiceHandler(ctx context.Context, config *dynamic.WhiteList) (http.Handler, error) {
	serviceHandler, err := m.BuildHTTP(config.Service)
	if err != nil {
		return nil, err
	}
	handler := whitelist.New(serviceHandler, config)
	return handler, nil
}
```
其中 `m.BuildHTTP(config.Service)` 这里是调用 BuildHTTP 方法，通过配置中传入的其他 Service 名称，创建其 Handler，以供我们的Service 调用。



到此我们的自定义 Service 已经开发完成。可以根据需求，对代码进行测试和修改