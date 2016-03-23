//
//  AppDelegate.h
//  SHSHSaver
//
//  Created by Matteo Piccina on 21/03/16.
//  Copyright © 2016 Matteo Piccina. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (strong, nonatomic) NSUserDefaults *userDefaults;
@property (weak) IBOutlet NSMenuItem *inealCheck;

@end

