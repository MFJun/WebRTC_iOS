//
//  ViewController.m
//  WebRTC_iOS
//
//  Created by MengFanJun on 2017/8/15.
//  Copyright © 2017年 MengFanJun. All rights reserved.
//

#import "ViewController.h"
#import "FriendListViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    UIButton *connectBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    connectBtn.frame = CGRectMake(0, 0, 150, 40);
    connectBtn.center = self.view.center;
    connectBtn.backgroundColor = [UIColor blackColor];
    [connectBtn setTitle:@"进入聊天室" forState:UIControlStateNormal];
    [connectBtn addTarget:self action:@selector(enterChatRoom) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:connectBtn];
}

- (void)enterChatRoom
{
    FriendListViewController *friendListViewController = [[FriendListViewController alloc] init];
    [self.navigationController pushViewController:friendListViewController animated:YES];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
