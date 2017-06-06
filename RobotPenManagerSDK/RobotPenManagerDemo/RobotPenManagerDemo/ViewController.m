//
//  ViewController.m
//  RobotPenManagerDemo
//
//  Created by JMS on 2017/2/18.
//  Copyright © 2017年 JMS. All rights reserved.
//

#import "ViewController.h"
#import "RobotPenManager.h"
#import "RobotPenDevice.h"
#import "RobotPenPoint.h"

#define SCREEN_WIDTH self.view.bounds.size.width
#define SCREEN_HEIGHT self.view.bounds.size.height
@interface ViewController ()<UITableViewDelegate,UITableViewDataSource,RobotPenDelegate>
{
    BOOL isConnect;
    
}

@property (weak, nonatomic) IBOutlet UILabel *xValue;
@property (weak, nonatomic) IBOutlet UILabel *yValue;
@property (weak, nonatomic) IBOutlet UILabel *pressureLabel;

@property (weak, nonatomic) IBOutlet UILabel *routeLabel;
@property (weak, nonatomic) IBOutlet UILabel *deviceUUID;
@property (weak, nonatomic) IBOutlet UILabel *deviceName;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UIButton *blueToothButton;
@property (weak, nonatomic) IBOutlet UILabel *SyncNumberLabel;
@property (weak, nonatomic) IBOutlet UIButton *SyncButton;
@property (weak, nonatomic) IBOutlet UILabel *VersionLabel;
@property (weak, nonatomic) IBOutlet UIButton *UpdateButton;
@property (weak, nonatomic) IBOutlet UILabel *BatteryLabel;
@property (weak, nonatomic) IBOutlet UILabel *RSSILabel;
@property(nonatomic,strong)RobotPenDevice *device;
@property(nonatomic,strong)NSMutableArray *deviceArray;
@end

@implementation ViewController

-(NSMutableArray *)deviceArray{
    if (!_deviceArray) {
        _deviceArray = [NSMutableArray array];
    }
    return _deviceArray;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    isConnect = NO;
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    [_blueToothButton setTitle:@"查找设备" forState:UIControlStateNormal];
    [_blueToothButton setTitle:@"断开连接" forState:UIControlStateSelected];
    [_blueToothButton addTarget:self action:@selector(blueToothButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    _SyncButton.hidden = YES;
    _UpdateButton.hidden = YES;
    
    [_SyncButton setTitle:@"同步" forState:UIControlStateNormal];
    [_SyncButton setTitle:@"停止同步" forState:UIControlStateSelected];
    [_SyncButton addTarget:self action:@selector(SyncButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
     [_UpdateButton addTarget:self action:@selector(UpdateButtonPressed:) forControlEvents:UIControlEventTouchUpInside];

    //遵守RobotPenManager协议
    [[RobotPenManager sharePenManager] setPenDelegate:self];
    
    // Do any additional setup after loading the view, typically from a nib.
}


-(void)blueToothButtonPressed:(UIButton *)sender{
    NSLog(@"%s",__func__);
    if (isConnect == NO) {
        [self.deviceArray removeAllObjects];
        [[RobotPenManager sharePenManager] scanDevice:self];
        
    } else{
        sender.selected = NO;
        [self.deviceArray removeAllObjects];
        [_tableView reloadData];
        [[RobotPenManager sharePenManager] disconnectDevice];
    }
}

-(void)SyncButtonPressed:(UIButton *)sender
{
    sender.selected = !sender.selected;
    if (sender.selected) {
        [[RobotPenManager sharePenManager] startSyncNote];
    }
    else
    {
        [[RobotPenManager sharePenManager] stopSyncNote];
    }
   
}
-(void)UpdateButtonPressed:(UIButton *)sender
{
    //OTA升级 过程中不要进行其他操作。
   [[RobotPenManager sharePenManager] startOTA:self];
}

/**
 获取点的信息
 */
-(void)getPointInfo:(RobotPenPoint *)point{
    
    self.xValue.text = [NSString stringWithFormat:@"%hd",point.originalX];
    self.yValue.text = [NSString stringWithFormat:@"%hd",point.originalY];
    
    self.pressureLabel.text = [NSString stringWithFormat:@"%hd",point.pressure];
    
    self.routeLabel.text = [NSString stringWithFormat:@"%d",point.touchState];
    
    
}

-(void)getBufferDevice:(RobotPenDevice *)device{
    
    [self.deviceArray addObject:device];
    [self.tableView reloadData];
}
-(void)getDeviceState:(DeviceState)State{
    switch (State) {
        case DISCONNECTED:
            NSLog(@"disconnect");
            isConnect = NO;
            _blueToothButton.selected = NO;
            [self refreshAll];
            [[RobotPenManager sharePenManager] scanDevice];
            break;
        case CONNECTED:
            NSLog(@"CONNECTED");
            [[RobotPenManager sharePenManager] stopScanDevice];
            isConnect = YES;
            _blueToothButton.selected = YES;
            self.device = [[RobotPenManager sharePenManager] getConnectDevice];
            [[RobotPenManager sharePenManager] stopScanDevice];
            
            [self.deviceArray removeAllObjects];
            [self.deviceArray addObject:self.device];
            [self.tableView reloadData];
            break;
        case CONNECTING:
            NSLog(@"connecting");
            break;
        case DEVICE_UPDATE:
        {
           
            [[RobotPenManager sharePenManager] getIsNeedUpdate];
                
        }
            break;
            
        case /**设备可更新**/
        DEVICE_UPDATE_CAN:
        {
            
            _UpdateButton.hidden = NO;
        }
            break;

           
        case DEVICE_INFO_END:
        {
            self.deviceName.text = [NSString stringWithFormat:@"%@",[self.device getName]];
            self.deviceUUID.text = [NSString stringWithFormat:@"%@",self.device.uuID];
            self.VersionLabel.text =[NSString stringWithFormat:@"%@",self.device.SWStr];
            self.BatteryLabel.text =[NSString stringWithFormat:@"%d",self.device.Battery];
            self.RSSILabel.text =[NSString stringWithFormat:@"%d",self.device.RSSI];
            
        }
            break;
        default:
            
            break;
    }
    
}



-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    NSInteger rowNumber = 0;
    if (self.deviceArray && [self.deviceArray count] > 0) {
        rowNumber = [self.deviceArray count];
    }
    return rowNumber;
}
-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *cellIdentifier = @"cellIdentifier";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (!cell) {
        cell = [[UITableViewCell alloc]initWithStyle:UITableViewCellStyleDefault reuseIdentifier:cellIdentifier];
    }
    cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    cell.textLabel.text = [[self.deviceArray objectAtIndex:indexPath.row] getName];
    return cell;
}
-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    NSLog(@"%s",__func__);
    if (!self.device) {
        RobotPenDevice *selectItem = [self.deviceArray objectAtIndex:[indexPath row]];
        [[RobotPenManager sharePenManager] connectDevice:selectItem :self];

    }
    
    
}

-(void)refreshAll
{
    _xValue.text = @"0.0";
    _yValue.text = @"0.0";
    _pressureLabel.text = @"0.0";
    _routeLabel.text = @"0";
    _deviceUUID.text = @"";
    _deviceName.text = @"";
    _SyncNumberLabel.text = @"0";
    _VersionLabel.text = @"0.0.0.0";
    _BatteryLabel.text = @"0";
    _RSSILabel.text = @"0";
    _SyncButton.hidden = YES;
    _UpdateButton.hidden = YES;
    self.device = nil;
}





#pragma mark 同步笔记
- (void)getSyncData:(RobotTrails *)trails
{
    NSLog(@"同步笔记的轨迹：%@",trails);
}
- (void)getSyncNote:(RobotNote *)note
{
    NSLog(@"同步笔记的笔记：%@",note);
}
- (void)SyncState:(SYNCState)state{
    switch (state) {
        case SYNC_ERROR:
        {
            NSLog(@"同步笔记错误");
        }
            break;
        case SYNC_NOTE:
        {
            NSLog(@"有未同步笔记");
            
        }
            break;
        case SYNC_NO_NOTE:
        {
            NSLog(@"没有未同步笔记");

        }
            break;
        case SYNC_SUCCESS:
        {
            NSLog(@"同步成功");
        }
            break;
        case SYNC_START:
        {
            NSLog(@"开始同步");
        }
            break;
        case SYNC_STOP:
        {
            NSLog(@"停止同步");
           _SyncButton.selected = NO;
        }
            break;
        case SYNC_COMPLETE:
        {
            NSLog(@"同步完成");
            _SyncButton.selected = NO;
            _SyncButton.hidden = YES;
            
        }
            break;
            
        default:
            break;
    }
}


//获取未同步笔记条数
- (void)getStorageNum:(int)num
{
    _SyncNumberLabel.text = [NSString stringWithFormat:@"%d",num];
    if (num > 0) {
        _SyncButton.hidden = NO;
    }
}


#pragma mark OTA

- (void)OTAUpdateState:(OTAState)state{
    switch (state) {
        case OTA_DATA:
        {
            NSLog(@"正在下载固件");
        
        }
            break;
        case OTA_UPDATE:
        {
            NSLog(@"ota升级");
        }
            break;
        case OTA_SUCCESS:
        {
            
            NSLog(@"升级成功");
            if (!_UpdateButton.hidden) {
                _UpdateButton.hidden = YES;
            }
        }
            break;
        case OTA_RESET:
        {
            NSLog(@"重启设备");
            
        }
            break;
        case OTA_ERROR:
        {
            NSLog(@"OTA升级错误");
        }
            break;
            
        default:
            break;
    }
}

- (void)OTAUpdateProgress:(float)progress{
    NSLog(@"OTA升级进度：%d%%",(int)(progress * 100));
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end