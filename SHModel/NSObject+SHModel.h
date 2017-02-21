//
//  NSObject+SHModel.h
//  SHModel
//
//  Created by lalala on 17/2/20.
//  Copyright © 2017年 lsh. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol ModelMapProtocol <NSObject>

/*
    对象重名映射 （只支持数组或者字典映射）
 *key : 模型命名
 *value : Json命名
 */
@optional
+(NSDictionary *)sh_modelMapFromJson;

@end

@interface NSObject (SHModel)<ModelMapProtocol>

/**
 * json -> model
 *
 *@prarm jsonData 支持Str Data Dictionary等类型
 *@return 模型对象
 *
 */
+(id)sh_modelFromJson:(id)jsonData;

/**
 *model -> dictionary
 *
 *@return  字典对象
 *
 */
-(NSDictionary *)sh_modelToDictionary;

@end
