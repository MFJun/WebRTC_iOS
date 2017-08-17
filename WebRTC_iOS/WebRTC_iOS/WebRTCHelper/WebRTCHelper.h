//
//  WebRTCHelper.h
//  WebScoketTest
//
//  Created by 涂耀辉 on 17/3/1.
//  Copyright © 2017年 涂耀辉. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SocketRocket.h"

#import <WebRTC/RTCPeerConnectionFactory.h>
#import <WebRTC/RTCPeerConnection.h>
#import <WebRTC/RTCMediaConstraints.h>
#import <WebRTC/RTCVideoCapturer.h>
#import <WebRTC/RTCVideoTrack.h>
#import <WebRTC/RTCEAGLVideoView.h>
#import <WebRTC/RTCIceServer.h>
#import <WebRTC/RTCIceCandidate.h>
#import <WebRTC/RTCConfiguration.h>
#import <WebRTC/RTCMediaStream.h>
#import <WebRTC/RTCDataChannel.h>
#import <WebRTC/RTCDataChannelConfiguration.h>
#import <WebRTC/RTCSessionDescription.h>

@protocol WebRTCHelperFriendListDelegate;
@protocol WebRTCHelperChatDelegate;

@interface WebRTCHelper : NSObject<SRWebSocketDelegate>

+ (instancetype)sharedInstance;

@property (nonatomic, weak)id<WebRTCHelperFriendListDelegate> friendListDelegate;
@property (nonatomic, weak)id<WebRTCHelperChatDelegate> chatdelegate;

/**
 *  与服务器建立连接
 *
 *  @param server 服务器地址
 @pram  port   端口号
 *  @param room   房间号
 */
- (void)connectServer:(NSString *)server port:(NSString *)port room:(NSString *)room;

/**
 *  退出房间
 */
- (void)exitRoom;

/*
 *  断开连接
 */
- (void)closePeerConnection;
/*
 *建立与好友的WebRTC连接
 */
- (void)connectWithUserId:(NSString *)userId;

/*
 *WebRTC连接建立成功后，发送消息方法
 */
- (void)sendMessage:(NSString *)message;

@end

/*
 *  好友列表协议
 */
@protocol WebRTCHelperFriendListDelegate <NSObject>
@optional
- (void)webRTCHelper:(WebRTCHelper *)webRTCHelper gotFriendList:(NSArray *)friendList;
- (void)webRTCHelper:(WebRTCHelper *)webRTCHelper gotNewFriend:(NSString *)userId;
- (void)webRTCHelper:(WebRTCHelper *)webRTCHelper removeFriend:(NSString *)userId;
- (void)requestConnectWithUserId:(NSString *)userId;

@end

/*
 *  聊天消息协议
 */
@protocol WebRTCHelperChatDelegate <NSObject>
@optional
- (void)webRTCHelper:(WebRTCHelper *)webRTChelper receiveMessage:(NSString *)message;
- (void)webRTCHelper:(WebRTCHelper *)webRTChelper closeChatWithUserId:(NSString *)userId;

- (void)webRTCHelper:(WebRTCHelper *)webRTChelper setLocalStream:(RTCMediaStream *)stream;
- (void)webRTCHelper:(WebRTCHelper *)webRTChelper setRemoteStream:(RTCMediaStream *)stream;

@end
