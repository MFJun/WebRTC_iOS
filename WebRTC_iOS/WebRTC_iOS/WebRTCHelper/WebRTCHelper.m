//
//  WebRTCHelper.m
//  WebScoketTest
//
//  Created by 涂耀辉 on 17/3/1.
//  Copyright © 2017年 涂耀辉. All rights reserved.
//

//  WebRTCHelper.m
//  WebRTCDemo
//


#import "WebRTCHelper.h"
#import <UIKit/UIKit.h>
#import <AVFoundation/AVFoundation.h>

//google提供的
static NSString *const RTCSTUNServerURL = @"stun:stun.l.google.com:19302";
static NSString *const RTCSTUNServerURL2 = @"stun:23.21.150.121";

typedef enum : NSUInteger {
    //发送者
    RoleCaller,
    //被发送者
    RoleCallee,
    
} Role;

@interface WebRTCHelper ()<RTCPeerConnectionDelegate, RTCDataChannelDelegate>

@end

@implementation WebRTCHelper
{
    SRWebSocket *_socket;
    NSString *_server;
    NSString *_room;
    
    RTCPeerConnectionFactory *_factory;
    RTCPeerConnection *_peerConnection;
    RTCMediaStream *_localStream;
    RTCMediaStream *_remoteStream;
    
    RTCDataChannel *_dataChannel;
    RTCDataChannel *_remoteDataChannel;
    
    NSString *_connectId;
    
    Role _role;
    
    NSMutableArray *ICEServers;
    
}

static WebRTCHelper *instance = nil;

+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[[self class] alloc] init];
    });
    return instance;
}

/**
 *  与服务器建立连接
 *
 *  @param server 服务器地址
 *  @param room   房间号
 */
//初始化socket并且连接
- (void)connectServer:(NSString *)server port:(NSString *)port room:(NSString *)room
{
    _server = server;
    _room = room;
    
    NSURLRequest *request = [NSURLRequest requestWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"ws://%@:%@",server,port]] cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:10];
    _socket = [[SRWebSocket alloc] initWithURLRequest:request];
    _socket.delegate = self;
    [_socket open];
    
}

/**
 *  加入房间
 *
 *  @param room 房间号
 */
- (void)joinRoom:(NSString *)room
{
    //如果socket是打开状态
    if (_socket.readyState == SR_OPEN)
    {
        //初始化加入房间的类型参数 room房间号
        NSDictionary *dic = @{@"eventName": @"__join", @"data": @{@"room": room}};
        //得到json的data
        NSData *data = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
        //发送加入房间的数据
        [_socket send:data];
    }
}

/**
 *  退出房间
 */
- (void)exitRoom
{
    [self closePeerConnection];
    [_socket close];
}

/*
 *  与目标建立连接
 */
- (void)connectWithUserId:(NSString *)userId
{
    _peerConnection = [self createPeerConnection:userId];
    _connectId = userId;
    [self createLocalStream];
    [_peerConnection addStream:_localStream];
    [self createDataChannel];
    [self createOffer];
}

/**
 *  关闭peerConnection
 *
 */
- (void)closePeerConnection
{
    _connectId = nil;
    [_peerConnection close];
    _peerConnection.delegate = nil;
    _dataChannel = nil;
    _dataChannel.delegate = nil;
    _peerConnection = nil;
}

/**
 *  创建本地流，并且把本地流回调出去
 */
- (void)createLocalStream
{
    _localStream = [_factory mediaStreamWithStreamId:@"ARDAMS"];
    
    //音频
    RTCAudioTrack *audioTrack = [_factory audioTrackWithTrackId:@"ARDAMSa0"];
    [_localStream addAudioTrack:audioTrack];
    
    //视频
    NSArray *deviceArray = [AVCaptureDevice devicesWithMediaType:AVMediaTypeVideo];
    AVCaptureDevice *device = [deviceArray lastObject];
    //检测摄像头权限
    AVAuthorizationStatus authStatus = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if(authStatus == AVAuthorizationStatusRestricted || authStatus == AVAuthorizationStatusDenied)
    {
        NSLog(@"相机访问受限");
        UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:@"相机访问受限" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil];
        [alertView show];
    }
    else
    {
        if (device)
        {
            RTCAVFoundationVideoSource *videoSource = [_factory avFoundationVideoSourceWithConstraints:[self localVideoConstraints]];
            RTCVideoTrack *videoTrack = [_factory videoTrackWithSource:videoSource trackId:@"ARDAMSv0"];
            [_localStream addVideoTrack:videoTrack];
            if ([_chatdelegate respondsToSelector:@selector(webRTCHelper:setLocalStream:)])
            {
                [_chatdelegate webRTCHelper:self setLocalStream:_localStream];
            }
            
        }
        else
        {
            NSLog(@"该设备不能打开摄像头");
            UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:@"提示" message:@"该设备不能打开摄像头" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:nil];
            [alertView show];
        }
    }
    
}

/**
 *  视频的相关约束
 */
- (RTCMediaConstraints *)localVideoConstraints
{
    RTCMediaConstraints *constraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:@{kRTCMediaConstraintsMaxWidth:@"640",kRTCMediaConstraintsMinWidth:@"640",kRTCMediaConstraintsMaxHeight:@"480",kRTCMediaConstraintsMinHeight:@"480",kRTCMediaConstraintsMinFrameRate:@"15"} optionalConstraints:nil];
    return constraints;
}

/**
 *  为连接创建dataChannel
 */
- (void)createDataChannel
{
    //给点对点连接，创建dataChannel
    
    RTCDataChannelConfiguration *dataChannelConfiguration = [[RTCDataChannelConfiguration alloc] init];
    dataChannelConfiguration.isOrdered = YES;
    _dataChannel = [_peerConnection dataChannelForLabel:@"testDataChannel" configuration:dataChannelConfiguration];
    _dataChannel.delegate = self;
    
}

/**
 *  为所有连接创建offer
 */
- (void)createOffer
{
    //给每一个点对点连接，都去创建offer
    _role = RoleCaller;
    [_peerConnection offerForConstraints:[self creatAnswerOrOfferConstraint] completionHandler:^(RTCSessionDescription * _Nullable sdp, NSError * _Nullable error) {
        __weak RTCPeerConnection *peerConnection = _peerConnection;
        [peerConnection setLocalDescription:sdp completionHandler:^(NSError * _Nullable error) {
            [self setSessionDescriptionWithPeerConnection:peerConnection];
        }];
    }];
}

/**
 *  设置offer/answer的约束
 */
- (RTCMediaConstraints *)creatAnswerOrOfferConstraint
{
    RTCMediaConstraints *constraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:@{kRTCMediaConstraintsOfferToReceiveAudio:kRTCMediaConstraintsValueTrue,kRTCMediaConstraintsOfferToReceiveVideo:kRTCMediaConstraintsValueTrue} optionalConstraints:nil];
    return constraints;
}

/**
 *  创建点对点连接
 *
 *  @param connectionId <#connectionId description#>
 *
 *  @return <#return value description#>
 */
- (RTCPeerConnection *)createPeerConnection:(NSString *)connectionId
{
    //如果点对点工厂为空
    if (!_factory)
    {
        //先初始化工厂
        _factory = [[RTCPeerConnectionFactory alloc] init];
    }
    
    //得到ICEServer
    if (!ICEServers) {
        ICEServers = [NSMutableArray array];
        [ICEServers addObject:[self defaultSTUNServer]];
    }
    
    //用工厂来创建连接
    RTCConfiguration *configuration = [[RTCConfiguration alloc] init];
    configuration.iceServers = ICEServers;
    RTCPeerConnection *connection = [_factory peerConnectionWithConfiguration:configuration constraints:[self creatPeerConnectionConstraint] delegate:self];
    
    return connection;
}


- (RTCMediaConstraints *)creatPeerConnectionConstraint
{
    RTCMediaConstraints *constraints = [[RTCMediaConstraints alloc] initWithMandatoryConstraints:@{kRTCMediaConstraintsOfferToReceiveAudio:kRTCMediaConstraintsValueTrue,kRTCMediaConstraintsOfferToReceiveVideo:kRTCMediaConstraintsValueTrue} optionalConstraints:nil];
    return constraints;
}

//初始化STUN Server （ICE Server）
- (RTCIceServer *)defaultSTUNServer{
    return [[RTCIceServer alloc] initWithURLStrings:@[RTCSTUNServerURL,RTCSTUNServerURL2]];
}

// Called when setting a local or remote description.
//当一个远程或者本地的SDP被设置就会调用
- (void)setSessionDescriptionWithPeerConnection:(RTCPeerConnection *)peerConnection
{
    NSLog(@"%s",__func__);
    NSString *currentId = _connectId;
    
    //判断，当前连接状态为，收到了远程点发来的offer，这个是进入房间的时候，尚且没人，来人就调到这里
    if (peerConnection.signalingState == RTCSignalingStateHaveRemoteOffer)
    {
        //创建一个answer,会把自己的SDP信息返回出去
        [peerConnection answerForConstraints:[self creatAnswerOrOfferConstraint] completionHandler:^(RTCSessionDescription * _Nullable sdp, NSError * _Nullable error) {
            __weak RTCPeerConnection *obj = peerConnection;
            [peerConnection setLocalDescription:sdp completionHandler:^(NSError * _Nullable error) {
                [self setSessionDescriptionWithPeerConnection:obj];
            }];
        }];
    }
    //判断连接状态为本地发送offer
    else if (peerConnection.signalingState == RTCSignalingStateHaveLocalOffer)
    {
        if (_role == RoleCallee)
        {
            NSDictionary *dic = @{@"eventName": @"__answer", @"data": @{@"sdp": @{@"type": @"answer", @"sdp": peerConnection.localDescription.sdp}, @"socketId": currentId}};
            NSData *data = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
            [_socket send:data];
        }
        //发送者,发送自己的offer
        else if(_role == RoleCaller)
        {
            NSDictionary *dic = @{@"eventName": @"__offer", @"data": @{@"sdp": @{@"type": @"offer", @"sdp": peerConnection.localDescription.sdp}, @"socketId": currentId}};
            NSData *data = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
            [_socket send:data];
        }
    }
    else if (peerConnection.signalingState == RTCSignalingStateStable)
    {
        if (_role == RoleCallee)
        {
            NSDictionary *dic = @{@"eventName": @"__answer", @"data": @{@"sdp": @{@"type": @"answer", @"sdp": peerConnection.localDescription.sdp}, @"socketId": currentId}};
            NSData *data = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
            [_socket send:data];
        }
    }
    
}

#pragma mark--RTCPeerConnectionDelegate

/** Called when the SignalingState changed. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection didChangeSignalingState:(RTCSignalingState)stateChanged
{
    NSLog(@"%s",__func__);
    NSLog(@"%ld", (long)stateChanged);
}

/** Called when media is received on a new stream from remote peer. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
          didAddStream:(RTCMediaStream *)stream
{
    NSLog(@"%s",__func__);
    
    _remoteStream = stream;
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_chatdelegate respondsToSelector:@selector(webRTCHelper:setRemoteStream:)])
        {
            [_chatdelegate webRTCHelper:self setRemoteStream:_remoteStream];
        }
    });
}

/** Called when a remote peer closes a stream. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection
       didRemoveStream:(RTCMediaStream *)stream
{
    NSLog(@"%s",__func__);
}

/** Called when negotiation is needed, for example ICE has restarted. */
- (void)peerConnectionShouldNegotiate:(RTCPeerConnection *)peerConnection
{
    
}

/** Called any time the IceConnectionState changes. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection didChangeIceConnectionState:(RTCIceConnectionState)newState
{
    NSLog(@"%s",__func__);
    NSLog(@"%ld", (long)newState);
    if (newState == RTCIceConnectionStateDisconnected) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if ([_chatdelegate respondsToSelector:@selector(webRTCHelper:closeChatWithUserId:)]) {
                [_chatdelegate webRTCHelper:self closeChatWithUserId:_connectId];
            }
            [self closePeerConnection];
        });
    }
}

/** Called any time the IceGatheringState changes. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection didChangeIceGatheringState:(RTCIceGatheringState)newState
{
    NSLog(@"%s",__func__);
    NSLog(@"%ld", (long)newState);
}

//创建peerConnection之后，从server得到响应后调用，得到ICE 候选地址
/** New ice candidate has been found. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection didGenerateIceCandidate:(RTCIceCandidate *)candidate
{
    NSLog(@"%s",__func__);
    
    NSString *currentId = _connectId;
    
    NSDictionary *dic = @{@"eventName": @"__ice_candidate", @"data": @{@"id":candidate.sdpMid,@"label": [NSNumber numberWithInteger:candidate.sdpMLineIndex], @"candidate": candidate.sdp, @"socketId": currentId}};
    NSData *data = [NSJSONSerialization dataWithJSONObject:dic options:NSJSONWritingPrettyPrinted error:nil];
    [_socket send:data];
}

/** Called when a group of local Ice candidates have been removed. */
- (void)peerConnection:(RTCPeerConnection *)peerConnection didRemoveIceCandidates:(NSArray<RTCIceCandidate *> *)candidates
{
    NSLog(@"%s",__func__);
}

/** New data channel has been opened. */
- (void)peerConnection:(RTCPeerConnection*)peerConnection didOpenDataChannel:(RTCDataChannel*)dataChannel

{
    NSLog(@"%s",__func__);
    NSLog(@"channel.state %ld",(long)dataChannel.readyState);
    _remoteDataChannel = dataChannel;
    _remoteDataChannel.delegate = self;
    
}

#pragma mark--RTCDataChannelDelegate

/** The data channel state changed. */
- (void)dataChannelDidChangeState:(RTCDataChannel *)dataChannel
{
    NSLog(@"%s",__func__);
    NSLog(@"channel.state %ld",(long)dataChannel.readyState);
}

/** The data channel successfully received a data buffer. */
- (void)dataChannel:(RTCDataChannel *)dataChannel didReceiveMessageWithBuffer:(RTCDataBuffer *)buffer
{
    NSLog(@"%s",__func__);
    NSString *message = [[NSString alloc] initWithData:buffer.data encoding:NSUTF8StringEncoding];
    NSLog(@"message:%@",message);
    dispatch_async(dispatch_get_main_queue(), ^{
        if ([_chatdelegate respondsToSelector:@selector(webRTCHelper:receiveMessage:)])
        {
            [_chatdelegate webRTCHelper:self receiveMessage:message];
        }
    });
    
}

//发送消息
- (void)sendMessage:(NSString *)message
{
    
    RTCDataBuffer *buffer = [[RTCDataBuffer alloc] initWithData:[message dataUsingEncoding:NSUTF8StringEncoding] isBinary:NO];
    BOOL result = [_dataChannel sendData:buffer];
    if (result) {
        NSLog(@"success");
    }
    else
    {
        NSLog(@"error");
    }
}


#pragma mark--SRWebSocketDelegate
- (void)webSocket:(SRWebSocket *)webSocket didReceiveMessage:(id)message
{
    NSLog(@"收到服务器消息:%@",message);
    NSDictionary *dic = [NSJSONSerialization JSONObjectWithData:[message dataUsingEncoding:NSUTF8StringEncoding] options:NSJSONReadingMutableContainers error:nil];
    NSString *eventName = dic[@"eventName"];
    
    //1.发送加入房间后的反馈
    if ([eventName isEqualToString:@"_peers"])
    {
        //得到data
        NSDictionary *dataDic = dic[@"data"];
        //得到所有的连接
        NSArray *connections = dataDic[@"connections"];
        if ([_friendListDelegate respondsToSelector:@selector(webRTCHelper:gotFriendList:)]) {
            [_friendListDelegate webRTCHelper:self gotFriendList:connections];
        }
    }
    //4.接收到新加入的人发了ICE候选，（即经过ICEServer而获取到的地址）
    else if ([eventName isEqualToString:@"_ice_candidate"])
    {
        NSDictionary *dataDic = dic[@"data"];
        NSString *socketId = dataDic[@"socketId"];
        NSString *sdpMid = dataDic[@"id"];
        int sdpMLineIndex = [dataDic[@"label"] intValue];
        NSString *sdp = dataDic[@"candidate"];
        if ([_connectId isEqualToString:socketId]) {
            //生成远端网络地址对象
            RTCIceCandidate *candidate = [[RTCIceCandidate alloc] initWithSdp:sdp sdpMLineIndex:sdpMLineIndex sdpMid:sdpMid];
            //添加到点对点连接中
            [_peerConnection addIceCandidate:candidate];
        }
        
    }
    //2.其他新人加入房间的信息
    else if ([eventName isEqualToString:@"_new_peer"])
    {
        NSDictionary *dataDic = dic[@"data"];
        //拿到新人的ID
        NSString *socketId = dataDic[@"socketId"];
        if ([_friendListDelegate respondsToSelector:@selector(webRTCHelper:gotNewFriend:)]) {
            [_friendListDelegate webRTCHelper:self gotNewFriend:socketId];
        }
    }
    //有人离开房间的事件
    else if ([eventName isEqualToString:@"_remove_peer"])
    {
        NSDictionary *dataDic = dic[@"data"];
        NSString *socketId = dataDic[@"socketId"];
        //得到socketId，并从用户列表中删除
        if ([_friendListDelegate respondsToSelector:@selector(webRTCHelper:removeFriend:)]) {
            [_friendListDelegate webRTCHelper:self removeFriend:socketId];
        }
        //如果正与这个目标连接，关闭这个peerConnection
        if ([_connectId isEqualToString:socketId]) {
            if ([_chatdelegate respondsToSelector:@selector(webRTCHelper:closeChatWithUserId:)]) {
                [_chatdelegate webRTCHelper:self closeChatWithUserId:_connectId];
            }
            [self closePeerConnection];
        }
    }
    //这个新加入的人发了个offer
    else if ([eventName isEqualToString:@"_offer"])
    {
        NSDictionary *dataDic = dic[@"data"];
        NSDictionary *sdpDic = dataDic[@"sdp"];
        //拿到SDP
        NSString *sdp = sdpDic[@"sdp"];
        NSString *socketId = dataDic[@"socketId"];
        if (_peerConnection) {
            //已经建立WebRTC连接，拒绝与建立新的连接，但是可以创建新的RTCPeerConnection，并与发起者建立连接，此处拒绝是为了在聊天界面，只与一个目标连接
            return;
        }
        
        _connectId = socketId;
        if ([_friendListDelegate respondsToSelector:@selector(requestConnectWithUserId:)]) {
            [_friendListDelegate requestConnectWithUserId:socketId];
        }
        
        //设置当前角色状态为被呼叫，（被发offer）
        _role = RoleCallee;
        
        //根据类型和SDP 生成SDP描述对象
        RTCSessionDescription *remoteSdp = [[RTCSessionDescription alloc] initWithType:RTCSdpTypeOffer sdp:sdp];
        //设置给这个点对点连接
        _peerConnection = [self createPeerConnection:socketId];
        [self createDataChannel];
        [self createLocalStream];
        [_peerConnection addStream:_localStream];
        __weak RTCPeerConnection *peerConnection = _peerConnection;
        __weak WebRTCHelper *weakSelf = self;
        [peerConnection setRemoteDescription:remoteSdp completionHandler:^(NSError * _Nullable error) {
            [weakSelf setSessionDescriptionWithPeerConnection:peerConnection];
        }];
        
    }
    //回应offer
    else if ([eventName isEqualToString:@"_answer"])
    {
        NSDictionary *dataDic = dic[@"data"];
        NSDictionary *sdpDic = dataDic[@"sdp"];
        NSString *sdp = sdpDic[@"sdp"];
        NSString *socketId = dataDic[@"socketId"];
        if ([_connectId isEqualToString:socketId]) {
            RTCSessionDescription *remoteSdp = [[RTCSessionDescription alloc] initWithType:RTCSdpTypeAnswer sdp:sdp];
            __weak RTCPeerConnection *peerConnection = _peerConnection;
            __weak WebRTCHelper *weakSelf = self;
            [peerConnection setRemoteDescription:remoteSdp completionHandler:^(NSError * _Nullable error) {
                [weakSelf setSessionDescriptionWithPeerConnection:peerConnection];
            }];
        }
    }
}

- (void)webSocketDidOpen:(SRWebSocket *)webSocket
{
    NSLog(@"websocket建立成功");
    //加入房间
    [self joinRoom:_room];
}

- (void)webSocket:(SRWebSocket *)webSocket didFailWithError:(NSError *)error
{
    NSLog(@"%s",__func__);
    NSLog(@"%ld:%@",(long)error.code, error.localizedDescription);
}

- (void)webSocket:(SRWebSocket *)webSocket didCloseWithCode:(NSInteger)code reason:(NSString *)reason wasClean:(BOOL)wasClean
{
    NSLog(@"%s",__func__);
    NSLog(@"%ld:%@",(long)code, reason);
}

@end
