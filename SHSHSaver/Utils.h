//
//  Utils.h
//  SHSHSaver
//
//  Created by Matteo Piccina on 21/03/16.
//  Copyright © 2016 Matteo Piccina. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface Utils : NSObject

+ (UInt64)getIntFromHexadecimal:(NSString *)string;
+ (NSArray *)getSignedVersionsForModel:(NSString *)model beta:(BOOL)isBeta;
+ (NSArray *)getSignedCydiaVersionsForEcid:(NSString *)ecid;
+ (NSDictionary *)getVersionInfosforModel:(NSString *)model andBuild:(NSString *)build;
+ (NSDictionary *)imagesDictionary;

@end
