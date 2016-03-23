//
//  Utils.m
//  SHSHSaver
//
//  Created by Matteo Piccina on 21/03/16.
//  Copyright © 2016 Matteo Piccina. All rights reserved.
//

#import "Utils.h"
#import <AFNetworking/AFNetworking.h>
#import "PZFileBrowser.h"

@implementation Utils

+ (UInt64)getIntFromHexadecimal:(NSString *)string
{
    
    UInt64 length;
    length = (UInt64)strtoull([string UTF8String], NULL, 16);
    return length;
    
}

+ (NSArray *)getSignedVersionsForModel:(NSString *)model beta:(BOOL)isBeta {
    
    NSString *url = [[NSString alloc] init];
    if (!isBeta) {
        url = [NSString stringWithFormat:@"http://api.ineal.me/tss/%@", model];
    } else {
        url = [NSString stringWithFormat:@"http://api.ineal.me/tss/beta/%@", model];
    }
    
    __block NSString *modelBlock = model;
    __block NSArray *firmwares = nil;
    dispatch_semaphore_t sem;
    sem = dispatch_semaphore_create(0);
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [manager GET:url parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        firmwares = [[responseObject objectForKey:modelBlock] objectForKey:@"firmwares"];
        dispatch_semaphore_signal(sem);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        firmwares = @[];
        dispatch_semaphore_signal(sem);
    }];
    
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
    return firmwares;
}

+ (NSArray *)getSignedCydiaVersionsForEcid:(NSString *)ecid {
    
    NSString *url = [NSString stringWithFormat:@"http://cydia.saurik.com/tss@home/api/check/%@", ecid];
    
    __block NSArray *firmwares = nil;
    dispatch_semaphore_t sem;
    sem = dispatch_semaphore_create(0);
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [manager GET:url parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        firmwares = responseObject;
        dispatch_semaphore_signal(sem);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        firmwares = @[];
        dispatch_semaphore_signal(sem);
    }];
    
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
    return firmwares;
}

+ (NSDictionary *)getVersionInfosforModel:(NSString *)model andBuild:(NSString *)build
{
    
    NSString *url = [NSString stringWithFormat:@"https://api.ipsw.me/v2.1/%@/%@/info.json", model, build];
    
    __block NSDictionary *infos = nil;
    dispatch_semaphore_t sem;
    sem = dispatch_semaphore_create(0);
    
    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
    [manager GET:url parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, id  _Nullable responseObject) {
        infos = [responseObject objectAtIndex:0];
        dispatch_semaphore_signal(sem);
    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
        infos = nil;
        dispatch_semaphore_signal(sem);
    }];
    
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
    return infos;
}

+ (NSDictionary *)imagesDictionary
{
    return @{
             @"AppleTV5,3": @"AppleTV4G",
             @"iPad1,1": @"iPad",
             @"iPad2,1": @"iPad2",
             @"iPad2,2": @"iPad2",
             @"iPad2,3": @"iPad2",
             @"iPad2,4": @"iPad2",
             @"iPad3,1": @"iPad3",
             @"iPad3,2": @"iPad3",
             @"iPad3,3": @"iPad3",
             @"iPad3,4": @"iPad4",
             @"iPad3,5": @"iPad4",
             @"iPad3,6": @"iPad4",
             @"iPad4,1": @"iPadAir",
             @"iPad4,2": @"iPadAir",
             @"iPad4,3": @"iPadAir",
             @"iPad5,3": @"iPadAir2",
             @"iPad5,4": @"iPadAir2",
             @"iPad6,7": @"iPadPro",
             @"iPad6,8": @"iPadPro",
             @"iPad2,5": @"iPadMini",
             @"iPad2,6": @"iPadMini",
             @"iPad2,7": @"iPadMini",
             @"iPad4,4": @"iPadMini2",
             @"iPad4,5": @"iPadMini2",
             @"iPad4,6": @"iPadMini2",
             @"iPad4,7": @"iPadMini3",
             @"iPad4,8": @"iPadMini3",
             @"iPad4,9": @"iPadMini3",
             @"iPad5,1": @"iPadMIni4",
             @"iPad5,2": @"iPadMini4",
             @"iPhone2,1": @"iPhone3gs",
             @"iPhone3,1": @"iPhone4",
             @"iPhone3,2": @"iPhone4",
             @"iPhone3,3": @"iPhone4",
             @"iPhone4,1": @"iPhone4s",
             @"iPhone5,1": @"iPhone5",
             @"iPhone5,2": @"iPhone5",
             @"iPhone5,3": @"iPhone5c",
             @"iPhone5,4": @"iPhone5c",
             @"iPhone6,1": @"iPhone5s",
             @"iPhone6,2": @"iPhone5s",
             @"iPhone7,2": @"iPhone6",
             @"iPhone7,1": @"iPhone6Plus",
             @"iPhone8,1": @"iPhone6s",
             @"iPhone8,2": @"iPhone6sPlus",
             @"iPod4,1": @"iPodTouch4G",
             @"iPod5,1": @"iPodTouch5G",
             @"iPod7,1": @"iPodTouch6G",
             };
}

@end
