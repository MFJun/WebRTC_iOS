//
//  FriendListViewController.m
//  WebRTC_iOS
//
//  Created by MengFanJun on 2017/8/11.
//  Copyright © 2017年 MengFanJun. All rights reserved.
//

#import "FriendListViewController.h"
#import "ChatViewController.h"
#import "WebRTCHelper.h"

@interface FriendListViewController () <UITableViewDelegate, UITableViewDataSource, WebRTCHelperFriendListDelegate>

@property (nonatomic, strong) UITableView *tableView;
@property (nonatomic, strong) NSMutableArray *informationArray;

@end

@implementation FriendListViewController

- (void)dealloc
{
    [WebRTCHelper sharedInstance].friendListDelegate = nil;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    
    self.view.backgroundColor = [UIColor whiteColor];
    self.informationArray = [NSMutableArray array];
    [self creatNavi];
    [self creatSubViews];
    [WebRTCHelper sharedInstance].friendListDelegate = self;
    [self connectAction];
    
}

- (void)creatNavi
{
    self.title = @"好友列表";
    UIBarButtonItem *leftButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:self action:@selector(leftButtonItemClicked)];
    self.navigationItem.leftBarButtonItem = leftButtonItem;
}

- (void)creatSubViews
{
    self.tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, self.view.frame.size.height) style:UITableViewStyleGrouped];
    [self.view addSubview:self.tableView];
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [_tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"reuse"];
    _tableView.separatorStyle = UITableViewCellSeparatorStyleSingleLine;
    _tableView.backgroundColor = [UIColor clearColor];
    
}

- (void)leftButtonItemClicked
{
    [[WebRTCHelper sharedInstance] exitRoom];
    [self.navigationController popViewControllerAnimated:YES];
}

//连接到房间
- (void)connectAction
{
    [[WebRTCHelper sharedInstance] connectServer:@"172.16.102.59" port:@"3000" room:@"100"];

}

#pragma  mark ** WebRTCHelperFriendListDelegate协议方法
- (void)webRTCHelper:(WebRTCHelper *)webRTCHelper gotFriendList:(NSArray *)friendList
{
    [self.informationArray removeAllObjects];
    [self.informationArray addObjectsFromArray:friendList];
    [self.tableView reloadData];
}

- (void)webRTCHelper:(WebRTCHelper *)webRTCHelper gotNewFriend:(NSString *)userId
{
    [self.informationArray addObject:userId];
    [self.tableView reloadData];
}

- (void)webRTCHelper:(WebRTCHelper *)webRTCHelper removeFriend:(NSString *)userId
{
    for (int i = 0; i < self.informationArray.count; i++) {
        NSString *friendId = self.informationArray[i];
        if ([friendId isEqualToString:userId]) {
            [self.informationArray removeObjectAtIndex:i];
            break;
        }
    }
    [self.tableView reloadData];
}

- (void)requestConnectWithUserId:(NSString *)userId
{
    ChatViewController *chatViewController = [[ChatViewController alloc] init];
    [self.navigationController pushViewController:chatViewController animated:YES];
}

#pragma  mark ** tableView协议方法
//分区个数
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

//每个分区cell个数
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.informationArray.count;
}

//重用cell
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    if (indexPath.section == 0) {
        UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"reuse"];
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.textLabel.text = self.informationArray[indexPath.row];
        return cell;
    }
    return nil;
}

//cell高度
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50;
}

//分区header高度
- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 0.01;
}

//分区headView
- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    return nil;
}

//分区footer高度
- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section{
    return 0.01;
}

//分区footView
- (UIView *)tableView:(UITableView *)tableView viewForFooterInSection:(NSInteger)section
{
    return nil;
}

//点击cell跳转至详情页
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    ChatViewController *chatViewController = [[ChatViewController alloc] init];
    chatViewController.userId = self.informationArray[indexPath.row];
    [self.navigationController pushViewController:chatViewController animated:YES];
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
