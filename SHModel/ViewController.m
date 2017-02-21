//
//  ViewController.m
//  SHModel
//
//  Created by lalala on 17/2/20.
//  Copyright © 2017年 lsh. All rights reserved.
//

#import "ViewController.h"
//解析数据类
#import "SHUser.h"
#import "NSObject+SHModel.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    //轻量级的数据解析
    NSString * path = [[NSBundle mainBundle] pathForResource:@"user.json" ofType:nil];
    NSData * data = [NSData dataWithContentsOfFile:path];
    
    //jsonToModel
    SHUser * model = [SHUser sh_modelFromJson:data];
    
    //modelToDic
    //NSLog(@"%@",[model sh_modelToDictionary]);
    
    NSLog(@"%@",[model.Array sh_modelToDictionary]);
    
    //PicInfos * model = [PicInfos sh_modelFromJson:model.Array];
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
