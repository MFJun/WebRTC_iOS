# WebRTC_iOS

### 下载与编译
WebRTC.framework下载与编译，可以看这篇文章[iOS下载、编译WebRTC](http://www.jianshu.com/p/64bd7f5b18b1)

### 使用

需要一个服务器端，交换sdp、ice，使用的是[tuyaohui](https://github.com/tuyaohui)用nodejs写好的后台，交互用的是WebSocket，请在[WebRTC](https://github.com/tuyaohui/WebRTC_iOS)中下载[SkyRTC-demo-master](https://github.com/tuyaohui/WebRTC_iOS/tree/master/iOS下音视频通信的实现-基于WebRTC/Server%26WebClient)，我刚开始学习WebRTC也是从[iOS下音视频通信-基于WebRTC](http://www.jianshu.com/p/c49da1d93df4)学习，写的很棒，但是因为该WebRTC版本与openssl冲突，所以，我从官网下载了新的版本，编译后，用新版本写了demo

安装Node.js及npm环境，SkyRTC-demo-master下载后，启动
```
cd SkyRTC-demo-master
node server.js
```

修改IP地址为你电脑的IP地址，172.16.102.59是我的IP地址
```
[[WebRTCHelper sharedInstance] connectServer:@"172.16.102.59" port:@"3000" room:@"100"];
```

### 测试

模拟器无法进行视频通信，如果进行视频测试，请准备两个iPhone
手机需要和电脑同处一个局域网（wifi下），跨网通信需要有效的STUN Server，我没有找到，所以只能在局域网中使用，如果有人找到了，可以分享给我（捂脸）

### 参考文章
[iOS下音视频通信-基于WebRTC](http://www.jianshu.com/p/c49da1d93df4)

