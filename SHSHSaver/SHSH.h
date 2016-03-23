//
//  SHSH.h
//  SHSHSaver
//
//  Created by Matteo Piccina on 21/03/16.
//  Copyright © 2016 Matteo Piccina. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "Utils.h"

@interface SHSH : NSObject

+ (NSData *)getSHSHFromDeviceWithBuildManifest:(NSDictionary *)BuildManifest Data:(NSDictionary *)infos Baseband:(BOOL)saveBaseband arm64:(BOOL)isArm64 cydia:(BOOL)getFromCydia;

@end
