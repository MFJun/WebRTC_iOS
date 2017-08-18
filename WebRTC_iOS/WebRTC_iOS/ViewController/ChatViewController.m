//
//  ChatViewController.m
//  WebRTC_iOS
//
//  Created by MengFanJun on 2017/8/11.
//  Copyright © 2017年 MengFanJun. All rights reserved.
//

#import "ChatViewController.h"
#import "WebRTCHelper.h"

#define KScreenWidth [UIScreen mainScreen].bounds.size.width
#define KScreenHeight [UIScreen mainScreen].bounds.size.height

#define KVedioWidth KScreenWidth/3.0
#define KVedioHeight KVedioWidth*320/240

@interface ChatViewController ()<WebRTCHelperChatDelegate>
{
    //本地摄像头追踪
    RTCVideoTrack *_localVideoTrack;
    //远程的视频追踪
    RTCVideoTrack *_remoteVideoTrack;

}

@property (nonatomic, strong) UITextField *textField;
@property (nonatomic, strong) UILabel *messageLabel;

@end

@implementation ChatViewController

- (void)dealloc
{
    [WebRTCHelper sharedInstance].chatdelegate = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.view.backgroundColor = [UIColor whiteColor];
    
    [WebRTCHelper sharedInstance].chatdelegate = self;
    [self creatNavi];
    [self creatSubViews];
    [self handleKeyEvent];
    [self connect];
}

- (void)connect
{
    if (self.userId) {
        [[WebRTCHelper sharedInstance] connectWithUserId:self.userId];
    }
}

- (void)creatNavi
{
    self.title = @"聊天室";
    UIBarButtonItem *leftButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:self action:@selector(leftButtonItemClicked)];
    self.navigationItem.leftBarButtonItem = leftButtonItem;
    
}

- (void)creatSubViews
{
    self.messageLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 64 + KVedioHeight, KScreenWidth, 40)];
    self.messageLabel.textAlignment = NSTextAlignmentCenter;
    self.messageLabel.backgroundColor = [UIColor colorWithRed:0 green:0 blue:0 alpha:0.1];
    [self.view addSubview:self.messageLabel];
    
    self.textField = [[UITextField alloc] initWithFrame:CGRectMake(0, 110 + KVedioHeight, KScreenWidth - 130, 40)];
    self.textField.borderStyle = UITextBorderStyleRoundedRect;
    [self.view addSubview:self.textField];
    
    UIButton *btn1 = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    btn1.frame = CGRectMake(KScreenWidth - 115, 110 + KVedioHeight, 100, 40);
    btn1.backgroundColor = [UIColor blackColor];
    [btn1 setTitle:@"发送" forState:UIControlStateNormal];
    [btn1 addTarget:self action:@selector(sendMessage) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:btn1];
}

- (void)leftButtonItemClicked
{
    [[WebRTCHelper sharedInstance] closePeerConnection];
    [self.navigationController popViewControllerAnimated:YES];
}

//发送消息
- (void)sendMessage
{
    if (self.textField.text.length == 0) {
        return;
    }
    [[WebRTCHelper sharedInstance] sendMessage:self.textField.text];
    self.textField.text = @"";
}

#pragma mark--WebRTCHelperChatDelegate
//接收到消息
- (void)webRTCHelper:(WebRTCHelper *)webRTChelper receiveMessage:(NSString *)message
{
    self.messageLabel.text = message;
}

- (void)webRTCHelper:(WebRTCHelper *)webRTChelper setLocalStream:(RTCMediaStream *)stream
{
    NSLog(@"setLocalStream");
    
    RTCEAGLVideoView *localVideoView = [[RTCEAGLVideoView alloc] initWithFrame:CGRectMake(0, 64, KVedioWidth, KVedioHeight)];
    _localVideoTrack = [stream.videoTracks lastObject];
    [_localVideoTrack addRenderer:localVideoView];
    
    [self.view addSubview:localVideoView];
    
}

- (void)webRTCHelper:(WebRTCHelper *)webRTChelper setRemoteStream:(RTCMediaStream *)stream
{
    NSLog(@"setRemoteStream");
    
    RTCEAGLVideoView *remoteVideoView = [[RTCEAGLVideoView alloc] initWithFrame:CGRectMake(KScreenWidth - KVedioWidth, 64, KVedioWidth, KVedioHeight)];
    _remoteVideoTrack = [stream.videoTracks lastObject];
    [_remoteVideoTrack addRenderer:remoteVideoView];

    [self.view addSubview:remoteVideoView];
    
}

//连接断开
- (void)webRTCHelper:(WebRTCHelper *)webRTChelper closeChatWithUserId:(NSString *)userId
{
    [self.navigationController popViewControllerAnimated:YES];
}

//键盘处理
-(void)handleKeyEvent
{
    [self.view addGestureRecognizer:[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(resignKeyTap)]];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(keyWillHiden:) name:UIKeyboardWillHideNotification object:nil];
}

-(void)resignKeyTap
{
    [self.view endEditing:YES];
}

-(void)keyWillShow:(NSNotification *)noti
{
    
}

-(void)keyWillHiden:(NSNotification *)noti
{
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */

@end
