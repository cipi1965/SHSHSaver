//
//  AppDelegate.m
//  SHSHSaver
//
//  Created by Matteo Piccina on 21/03/16.
//  Copyright © 2016 Matteo Piccina. All rights reserved.
//

#import "AppDelegate.h"

@interface AppDelegate ()

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    self.userDefaults = [NSUserDefaults standardUserDefaults];
    if ([self.userDefaults stringForKey:@"savePath"] == nil) {
        NSError *error;
        NSString *path = [NSHomeDirectory() stringByAppendingPathComponent:@"SHSH"];
        [[NSFileManager defaultManager] createDirectoryAtPath:path
                                  withIntermediateDirectories:YES
                                                   attributes:nil
                                                        error:&error];
        [self.userDefaults setValue:path forKey:@"savePath"];
        [self.userDefaults synchronize];
    }
    
    if ([self.userDefaults valueForKey:@"useIneal"] == nil) {
        [self.userDefaults setBool:YES forKey:@"useIneal"];
        [self.userDefaults synchronize];
    }
    
    if ([self.userDefaults boolForKey:@"useIneal"] == YES) {
        self.inealCheck.state = 1;
    } else {
        self.inealCheck.state = 0;
    }
    NSLog(@"Save Path: %@", [self.userDefaults stringForKey:@"savePath"]);
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    // Insert code here to tear down your application
}

- (IBAction)changeSaveDirectory:(id)sender {
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.allowsMultipleSelection = NO;
    panel.canChooseFiles = NO;
    panel.canCreateDirectories = YES;
    panel.canChooseDirectories = YES;
    NSInteger panelResult = [panel runModal];
    if (panelResult == NSFileHandlingPanelOKButton) {
        [self.userDefaults setValue:[[[panel URL] absoluteString] stringByReplacingOccurrencesOfString:@"file://" withString:@""] forKey:@"savePath"];
        [self.userDefaults synchronize];
    }
}
- (IBAction)inealCheckChanged:(id)sender {
    if (self.inealCheck.state == 0) {
        self.inealCheck.state = 1;
        [self.userDefaults setBool:YES forKey:@"useIneal"];
    } else {
        self.inealCheck.state = 0;
        [self.userDefaults setBool:NO forKey:@"useIneal"];
    }
    [self.userDefaults synchronize];
}

@end
