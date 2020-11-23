---
layout: post
title: Golang JSON 反序列化数字的坑
tags: [golang,]
category: [代码笔记,]
excerpt: json反序列化数字时遇到的精度丢失问题以及解决方法
---

## 现象

当有下述JSON字符串，需要反序列化：

```json
{"userID":1,"config":{"pid":1234567890123456789,"target_type":1}}
```

（这里的pid字段有19位，是int64的最长位数）  
  
且反序列化为类型 `map[string]interface{}`  
  

是吧，很正常吧……  
  
我们使用下述方法进行反序列化测试：

```golang
func Unmarshal(jsonStr string) {
	var result map[string]interface{}
	json.Unmarshal([]byte(jsonStr), &result)
	fmt.Printf("反序列化后：\t%#v\n", result)
	pid := result["config"].(map[string]interface{})["pid"]
	fmt.Printf("PID类型：\t%T \nPID值：\t%f\n", pid, pid)
	fmt.Printf("Int64：%d", int64(pid.(float64)))
}
```

得到结果：

```
使用 json.Unmarshal 的情况：

反序列化后：    map[string]interface {}{"userID":1, "config":map[string]interface {}{"pid":1.2345678901234568e+18, "target_type":1}}
PID类型：       float64
PID值： 1234567890123456768.000000
Int64：1234567890123456768
```

惊不惊喜，意不意外？  
  
## 分析

重点在于 `json.Unmarshal` 这个方法.它的类型转换是这么搞的：

```
bool, for JSON booleans
float64, for JSON numbers
string, for JSON strings
[]interface{}, for JSON arrays
map[string]interface{}, for JSON objects
nil for JSON null
```

[摘自 https://golang.org/pkg/encoding/json](https://golang.org/pkg/encoding/json/#Unmarshal)  
  
并且由于float64类型所支持的精度问题，我们会损失一丢丢精度……就如上面的转换所示，最后两位已然面目全非……  
  
## 解决

既然 `json.Unmarshal` 处理较大的数会产生精度问题，那么不要让它处理数字就行。`json.Decoder` 就能实现这样的操作。  
  
`json.Decoder` 支持这样一个方法：[`UseNumber`](https://golang.org/pkg/encoding/json/#Decoder.UseNumber)

它是这样说明的：

> UseNumber causes the Decoder to unmarshal a number into an interface{} as a Number instead of as a float64.

UseNumber使Decoder将数字作为json.Number解析到interface{}中而不是float64。  
  
而 [`json.Number`](https://golang.org/pkg/encoding/json/#Number) 提供将其转换为 `Int64` 类型的方法。  
  
所以，我们可以这样写：

```golang
func Decoder(jsonStr string) {
	var result map[string]interface{}
	decoder := json.NewDecoder(bytes.NewReader([]byte(jsonStr)))
	//seNumber causes the Decoder to unmarshal a number into an interface{} as a Number instead of as a float64.
	decoder.UseNumber()
	decoder.Decode(&result)
	fmt.Printf("反序列化后：\t%#v\n", result)
	pid := result["config"].(map[string]interface{})["pid"]
	fmt.Printf("PID类型：\t%T \nPID值：\t%v\n", pid, pid)
	pidValue, _ := pid.(json.Number).Int64()
	fmt.Printf("Int64：%d", pidValue)
}
```

得到的结果是：

```bash
使用 json.Decoder 配合 UseNumber 方法的情况：

反序列化后：    map[string]interface {}{"userID":"1", "config":map[string]interface {}{"target_type":"1", "pid":"1234567890123456789"}}
PID类型：       json.Number
PID值： 1234567890123456789
Int64：1234567890123456789
```

问题解决……TAT（可TM坑死我了）