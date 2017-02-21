//
//  NSObject+SHModel.m
//  SHModel
//
//  Created by lalala on 17/2/20.
//  Copyright © 2017年 lsh. All rights reserved.
//

#import "NSObject+SHModel.h"
#import <objc/runtime.h>

#define SuppressPerformSelectorLeakWarning(Stuff) \
do { \
_Pragma("clang diagnostic push") \
_Pragma("clang diagnostic ignored \"-Warc-performSelector-leaks\"") \
Stuff; \
_Pragma("clang diagnostic pop") \
} while (0)


const char SHPropertyTypeInt = 'i';
const char SHPropertyTypeShort = 's';
const char SHPropertyTypeLong = 'l';
const char SHPropertyTypeLongLong = 'q';
const char SHPropertyTypeFloat = 'f';
const char SHPropertyTypeDouble = 'd';
const char SHPropertyTypeBOOL1 = 'c';
const char SHPropertyTypeBOOL2 = 'B';
const char SHPropertyTypeChar = 'c';
const char SHPropertyTypeUnSignedInt = 'I';
const char SHPropertyTypeUnSignedShort = 'S';
const char SHPropertyTypeUnSignedLong = 'L';
const char SHPropertyTypeUnSignedLongLong = 'Q';
const char SHPropertyTypeUnSignedChar = 'C';

const char SHPropertyTypeObject = '@';

NSString * const SHNullString = @"";

@implementation NSObject (SHModel)
inline static const char * getPropertyType(objc_property_t property){
    const char * attributes = property_getAttributes(property);
    
    char buffer[1 + strlen(attributes)];
    strcpy(buffer, attributes);
    char * state = buffer, *attribute;
    while ((attribute = strsep(&state, ",")) != NULL) {
        if (attributes[0] == 'T' && attributes[1] != '@') {
            char * attributeTemp = (char *)[[NSData dataWithBytes:(attribute + 1) length:strlen(attribute)]bytes];
            char * p = strtok(attributeTemp, "\"");
            if (p) {
                return (const char*)p;
            }
            p = strtok(NULL, "\"");
            if (p) {
                return (const char *)p;
            }
        } else if (attribute[0] == 'T' && attribute[1] == '@' && strlen(attribute) == 2){
            return "id";
        } else if (attribute[0] == 'T' && attribute[1] == '@'){
            char * attributeTemp = (char *)[[NSData dataWithBytes:(attribute + 3) length:strlen(attribute)]bytes];
            char * p = strtok(attributeTemp, "\"");
            if (p) {
                return (const char *)p;
            }
            p = strtok(NULL, "\"");
            if (p) {
                return (const char *)p;
            }
        }
        return nil;
    }
    return nil;
}
+(id)sh_modelFromJson:(id)jsonData{
    id model = self.new;
    
    NSDictionary * dict = [jsonData sh_JSONObject];
    
    if (dict == nil || dict.count == 0) return model;
    
    unsigned int propertyCount;
    objc_property_t * properties = class_copyPropertyList(self.class, &propertyCount);
    for (NSUInteger i = 0; i < propertyCount; i++) {
        objc_property_t property = properties[i];
        NSString * keyName = [NSString stringWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
        NSObject * value;
        if ([self respondsToSelector:@selector(sh_modelMapFromJson)]) {
            NSDictionary * newDic = [self performSelector:@selector(sh_modelMapFromJson)];
            NSArray * valueArray = [newDic allValues];
            if ([valueArray containsObject:keyName]) {
                value = (NSObject *)[dict objectForKey:[newDic objectForKey:keyName]];
            } else {
                value = (NSObject *)[dict objectForKey:keyName];
            }
        } else {
            value = (NSObject *)[dict objectForKey:keyName];
        }
        
        if (value == nil || [[value class] isSubclassOfClass:[NSNull class]]) continue;
        
        char * typeEncoding = property_copyAttributeValue(property, "T");
        
        if (typeEncoding == NULL) continue;
        switch (typeEncoding[0]) {
            case  SHPropertyTypeObject:
            {
                Class class = nil;
                if (strlen(typeEncoding) > 3) {
                    char * className = strndup(typeEncoding + 2, strlen(typeEncoding) - 3);
                    class = NSClassFromString([NSString stringWithUTF8String:className]);
                    free(className);
                }
                //类型容错
                if ([class isSubclassOfClass:[NSString class]] && [value isKindOfClass:[NSNumber class]]) {
                    value = [(NSNumber *)value stringValue];
                } else if ([class isSubclassOfClass:[NSNumber class]] && [value isKindOfClass:[NSString class]]){
                    NSNumberFormatter * numberFormatter = [[NSNumberFormatter alloc]init];
                    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
                    value = [numberFormatter numberFromString:(NSString *)value];
                } else if ([class isSubclassOfClass:[NSArray class]] && [[value class] isSubclassOfClass:[NSArray class]]){
                    //数组
                    NSArray * arr = (NSArray *)value;
                    NSMutableArray * fieldArr = [[NSMutableArray alloc]init];
                    for (NSInteger i = 0; i < [arr count]; i++) {
                        NSDictionary * itemDict = [arr objectAtIndex:i];
                        if ([itemDict isKindOfClass:[NSDictionary class]] == NO) continue;
                        [fieldArr addObject:[NSClassFromString(keyName) sh_modelFromJson:itemDict]];
                    }
                    value = fieldArr;
                } else if ([[value class] isSubclassOfClass:[NSDictionary class]]){
                    //字典
                    value = [class sh_modelFromJson:keyName];
                }
                
                [model setValue:value forKey:keyName];
            }
                break;
                
            case SHPropertyTypeInt: //按照简单数据类型赋值
            case SHPropertyTypeShort:
            case SHPropertyTypeLong:
            case SHPropertyTypeLongLong:
            case SHPropertyTypeUnSignedInt:
            case SHPropertyTypeUnSignedShort:
            case SHPropertyTypeUnSignedLong:
            case SHPropertyTypeUnSignedLongLong:
            case SHPropertyTypeFloat:
            case SHPropertyTypeDouble:{
                if ([value isKindOfClass:[NSString class]]) {
                    NSNumberFormatter * numberFormatter = [[NSNumberFormatter alloc]init];
                    [numberFormatter setNumberStyle:NSNumberFormatterDecimalStyle];
                    value = [numberFormatter numberFromString:(NSString *)value];
                    if (!value) value = [NSNumber numberWithInt:0];
                }
                [model setValue:value forKey:keyName];
            }
                break;
            case SHPropertyTypeBOOL1://bool 类型容错
            case SHPropertyTypeBOOL2:
            {
                if ([value isKindOfClass:[NSString class]]) {
                    NSString * str = (NSString *)value;
                    NSString * lowStr = str.lowercaseString;
                    if ([lowStr isEqualToString:@"false"]||
                        [lowStr isEqualToString:@"no"]||
                        [lowStr isEqualToString:@"nil"]||
                        [lowStr isEqualToString:@"null"]||
                        [lowStr isEqualToString:@"(null)"]||
                        [lowStr isEqualToString:@"<null>"]) {
                        value = [NSNumber numberWithBool:0];
                    } else {
                        value = [NSNumber numberWithBool:1];
                    }
                }
                [model setValue:value forKey:keyName];
            }
                break;
            case SHPropertyTypeUnSignedChar://如果字符取第一个
            {
                if ([value isKindOfClass:[NSString class]]) {
                    NSString * str = (NSString *)value;
                    if (!str || str.length == 0) {
                        value = [NSNumber numberWithInt:0];
                    } else {
                        value = [NSNumber numberWithInt:[str characterAtIndex:0]];
                    }
                }
                [model setValue:value forKey:keyName];
            }
                break;
            default:
                break;
        }
        free(typeEncoding);
    }
    free(properties);
    return model;
}
-(NSDictionary *)sh_modelToDictionary{
    
    NSMutableDictionary * finalDict = nil;
    @synchronized (self) {
        NSString * className = NSStringFromClass([self class]);
        const char * cClassName = [className UTF8String];
        id theClass = objc_getClass(cClassName);
        unsigned int outCount,i;
        objc_property_t * properties = class_copyPropertyList(theClass, &outCount);
        finalDict = [NSMutableDictionary dictionary];
        for (i = 0; i < outCount; i++) {
            objc_property_t property = properties[i];
            NSString * name = [NSString stringWithCString:property_getName(property) encoding:NSUTF8StringEncoding];
            NSString * type = [NSString stringWithCString:getPropertyType(property) encoding:NSUTF8StringEncoding];
            if (!type)  type = [NSString stringWithCString:getPropertyType(property) encoding:NSUTF8StringEncoding];
            
            SEL selector = NSSelectorFromString(name);
            
            NSString * lowTypeStr = type.lowercaseString;
            
            if ([lowTypeStr isEqualToString:@"i"]||
                [lowTypeStr isEqualToString:@"l"]||
                [lowTypeStr isEqualToString:@"s"]||
                [lowTypeStr isEqualToString:@"q"]||
                [lowTypeStr isEqualToString:@"b"]) {
                NSInteger value;
                SuppressPerformSelectorLeakWarning(value = (NSInteger)[self performSelector:selector]);
                [finalDict setObject:[NSNumber numberWithInteger:value] forKey:name];
            } else if ([lowTypeStr isEqualToString:@"f"] || [lowTypeStr isEqualToString:@"d"]){
                Ivar * ivar = class_copyIvarList(self.class, nil);
                float newFloat;
#warning This file must be compiled with Non_ARC.
                object_getInstanceVariable(self,ivar_getName(ivar[0]),(void *)&newFloat);
                [finalDict setObject:[NSNumber numberWithFloat:newFloat] forKey:name];
            } else if ([lowTypeStr isEqualToString:@"c"]){
                char value;
                SuppressPerformSelectorLeakWarning(value = (char)[self performSelector:selector]);
                [finalDict setValue:[NSString stringWithFormat:@"%c",value] forKey:name];
            } else {
                id value;
                SuppressPerformSelectorLeakWarning(value = [self performSelector:selector]);
                if ([type isEqualToString:@"NSString"]) {
                    if (value) [finalDict setObject:[NSString stringWithFormat:@"%@",value] forKey:name];
                } else if([type isEqualToString:@"NSMutableArray"]||[type isEqualToString:@"NSArray"]){
                    //数组
                    if (![value isKindOfClass:[NSArray class]]) continue;
                    NSMutableArray * array = [[NSMutableArray alloc]initWithArray:value];
                    NSMutableArray * results = [NSMutableArray array];
                    for (id onceId in array) {
                        [results addObject:[onceId sh_modelToDictionary]];
                    }
                    if (results) {
                        [finalDict setObject:results forKey:name];
                    }
                } else {
                    //对象
                    NSDictionary * dic = [value sh_modelToDictionary];
                    if (dic) {
                        [finalDict setObject:dic forKey:name];
                    }
                }
            }
        }
        free(properties);
    }
    
    return finalDict;
}
-(id)sh_JSONObject{
    if ([self isKindOfClass:[NSString class]]) {
        return [NSJSONSerialization JSONObjectWithData:[((NSString *)self) dataUsingEncoding:NSUTF8StringEncoding] options:kNilOptions error:nil];
    } else if ([self isKindOfClass:[NSData class]]){
        return [NSJSONSerialization JSONObjectWithData:(NSData *)self options:kNilOptions error:nil];
    }
    return self;
}

@end
