//
//  ViewController.m
//  SHSHSaver
//
//  Created by Matteo Piccina on 21/03/16.
//  Copyright © 2016 Matteo Piccina. All rights reserved.
//

#import "ViewController.h"
#import "Utils.h"
#import "SHSH.h"
#import "PZFileBrowser.h"
#import "AppDelegate.h"
#import <AFNetworking/AFNetworking.h>

@implementation ViewController

@synthesize tssRequestDict;

- (void)viewDidLoad {
    [super viewDidLoad];
    
    MobileDeviceAccess *mda = [MobileDeviceAccess singleton];
    [mda setListener:self];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
}

- (void)viewDidDisappear {
    [[NSApplication sharedApplication] terminate:nil];
}

- (void)deviceConnected:(AMDevice*)device
{
    NSLog(@"Device connected: %@", [device deviceName]);
    self.connectedDevice = device;
    self.saveButton.enabled = YES;
    self.saveButtonCydia.enabled = YES;
    if ([[Utils imagesDictionary] objectForKey:[device productType]] != nil) {
        self.deviceImage.image = [NSImage imageNamed:[[Utils imagesDictionary] objectForKey:[device productType]]];
    } else {
        self.deviceImage.image = [NSImage imageNamed:@"Unknown"];
    }
    [self.progressBarLabel setStringValue:@"Click \"Save SHSH\" to start"];
    self.progressBarLabel.hidden = NO;
    [self.connectedLabel setStringValue:[NSString stringWithFormat:@"Device Connected: %@", [self.connectedDevice deviceName]]];
}

- (void)deviceDisconnected:(AMDevice *)device {
    self.connectedDevice = nil;
    self.firmwares = nil;
    self.saveButton.enabled = NO;
    self.deviceImage.image = nil;
    [self.progressBarLabel setStringValue:@""];
    self.progressBarLabel.hidden = YES;
    [self.connectedLabel setStringValue:@"No Connected Device"];
}

- (IBAction)saveButton:(id)sender {
    [self saveSHSH:NO];
}

- (void)saveSHSH:(BOOL)cydia {
    
    __block BOOL cydiaEnabled = cydia;
    self.saveButton.enabled = NO;
    self.saveButtonCydia.enabled = NO;
    self.firmwares = @[];
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        //Long things - background thread
        dispatch_sync((dispatch_get_main_queue()), ^{
            self.progressBar.indeterminate = YES;
            [self.progressBar startAnimation:nil];
        });
        if (!cydiaEnabled) {
            self.firmwares = [Utils getSignedVersionsForModel:[self.connectedDevice productType]
                                                     beta:NO];
        } else {
            self.firmwares = [Utils getSignedCydiaVersionsForEcid:[[self.connectedDevice deviceValueForKey:@"UniqueChipID" inDomain:nil] stringValue]];
        }
        dispatch_sync((dispatch_get_main_queue()), ^{
            self.progressBar.indeterminate = NO;
            self.progressBar.maxValue = [self.firmwares count];
            [self.progressBarLabel setStringValue:[NSString stringWithFormat:@"0 of %lu SHSH saved", (unsigned long)[self.firmwares count]]];
            self.progressBarLabel.hidden = NO;
        });
        __block int progressCount = 0;
        AppDelegate *appDelegate = (AppDelegate *)[[NSApplication sharedApplication] delegate];
        NSString *savePath = [appDelegate.userDefaults stringForKey:@"savePath"];
        for (NSDictionary *firmware in self.firmwares) {
            NSFileManager *fileManager = [NSFileManager defaultManager];
            NSString *filename = [NSString stringWithFormat:@"%@_%@_%@_%@.shsh", [self.connectedDevice productType], [[self.connectedDevice deviceValueForKey:@"UniqueChipID" inDomain:nil] stringValue],[firmware objectForKey:@"version"], [firmware objectForKey:@"build"]];
            NSLog(@"%@", [savePath stringByAppendingPathComponent:filename]);
            if (![fileManager fileExistsAtPath:[savePath stringByAppendingPathComponent:filename]]){
                NSDictionary *infos = [Utils getVersionInfosforModel:[self.connectedDevice productType] andBuild:[firmware objectForKey:@"build"]];
                NSDictionary *manifest;
                if ([appDelegate.userDefaults boolForKey:@"useIneal"]) {
                    
                    NSLog(@"I'm using iNeal");
                    NSString *url = [NSString stringWithFormat:@"http://api.ineal.me/tss/buildmanifest/%@/%@", [self.connectedDevice productType], [firmware objectForKey:@"build"]];
                    
                    __block NSData *manifestData = nil;
                    dispatch_semaphore_t sem;
                    sem = dispatch_semaphore_create(0);
                    
                    AFHTTPSessionManager *manager = [AFHTTPSessionManager manager];
                    manager.responseSerializer = [AFHTTPResponseSerializer serializer];
                    [manager GET:url parameters:nil progress:nil success:^(NSURLSessionDataTask * _Nonnull task, NSData *responseObject) {
                        manifestData = responseObject;
                        dispatch_semaphore_signal(sem);
                    } failure:^(NSURLSessionDataTask * _Nullable task, NSError * _Nonnull error) {
                        manifestData = nil;
                        dispatch_semaphore_signal(sem);
                    }];
                    
                    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
                    
                    NSString *tempFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent: [NSString stringWithFormat:@"Manifest_%@_%@_%@.plist", [self.connectedDevice productType], [infos objectForKey:@"version"], [infos objectForKey:@"buildid"]]];
                    [manifestData writeToFile:tempFilePath atomically:NO];
                    
                    manifest = [NSDictionary dictionaryWithContentsOfFile:tempFilePath];
                    
                } else {
                    PZFileBrowser *browser = [PZFileBrowser browserWithPath:[infos objectForKey:@"url"]];
                    NSString *path = @"BuildManifest.plist";
                    NSData *data = [browser getDataForPath:path];
                    
                    NSString *tempFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent: [NSString stringWithFormat:@"Manifest_%@_%@_%@.plist", [self.connectedDevice productType], [infos objectForKey:@"version"], [infos objectForKey:@"buildid"]]];
                    
                    [data writeToFile:tempFilePath atomically:NO];
                    
                    manifest = [NSDictionary dictionaryWithContentsOfFile:tempFilePath];
                    
                    NSLog(@"Downloaded manifest to: %@", tempFilePath);
                }
                
                NSData *bbnonce = [[NSData alloc] initWithBase64EncodedString:@"FFrp/uZvF8gUV8Xj9RaXRyOZiO0=" options:0];
                
                NSData *shshData;
                
                if ([self.connectedDevice deviceValueForKey:@"SEPNonce" inDomain:nil] == nil) {
                    
                    if ([[[[manifest objectForKey:@"BuildIdentities"] objectAtIndex:0] objectForKey:@"Manifest"] objectForKey:@"BasebandFirmware"] != nil) {
                        NSDictionary *deviceInfo = @{
                                                     @"ecid":[self.connectedDevice deviceValueForKey:@"UniqueChipID" inDomain:nil],
                                                     @"ApNonce":[self.connectedDevice deviceValueForKey:@"ApNonce" inDomain:nil],
                                                     @"BbGoldCertId":[self.connectedDevice deviceValueForKey:@"BasebandCertId" inDomain:nil],
                                                     @"BbNonce":bbnonce,
                                                     @"BbSNUM":[self.connectedDevice deviceValueForKey:@"BasebandSerialNumber" inDomain:nil],
                                                     
                                                     };
                        
                        shshData = [SHSH getSHSHFromDeviceWithBuildManifest:manifest Data:deviceInfo Baseband:YES arm64:NO cydia:cydiaEnabled];
                    } else {
                        NSDictionary *deviceInfo = @{
                                                     @"ecid":[self.connectedDevice deviceValueForKey:@"UniqueChipID" inDomain:nil],
                                                     @"ApNonce":[self.connectedDevice deviceValueForKey:@"ApNonce" inDomain:nil]
                                                     };
                        
                        shshData = [SHSH getSHSHFromDeviceWithBuildManifest:manifest Data:deviceInfo Baseband:NO arm64:NO cydia:cydiaEnabled];
                    }
                } else {
                    if ([[[[manifest objectForKey:@"BuildIdentities"] objectAtIndex:0] objectForKey:@"Manifest"] objectForKey:@"BasebandFirmware"] != nil) {
                        NSDictionary *deviceInfo = @{
                                                     @"ecid":[self.connectedDevice deviceValueForKey:@"UniqueChipID" inDomain:nil],
                                                     @"ApNonce":[self.connectedDevice deviceValueForKey:@"ApNonce" inDomain:nil],
                                                     @"BbGoldCertId":[self.connectedDevice deviceValueForKey:@"BasebandCertId" inDomain:nil],
                                                     @"BbNonce":bbnonce,
                                                     @"BbSNUM":[self.connectedDevice deviceValueForKey:@"BasebandSerialNumber" inDomain:nil],
                                                     @"SepNonce":[self.connectedDevice deviceValueForKey:@"SEPNonce" inDomain:nil]
                                                     
                                                     };
                        
                        shshData = [SHSH getSHSHFromDeviceWithBuildManifest:manifest Data:deviceInfo Baseband:YES arm64:YES cydia:cydiaEnabled];
                    } else {
                        NSDictionary *deviceInfo = @{
                                                     @"ecid":[self.connectedDevice deviceValueForKey:@"UniqueChipID" inDomain:nil],
                                                     @"ApNonce":[self.connectedDevice deviceValueForKey:@"ApNonce" inDomain:nil],
                                                     @"SepNonce":[self.connectedDevice deviceValueForKey:@"SEPNonce" inDomain:nil]
                                                     };
                        
                        shshData = [SHSH getSHSHFromDeviceWithBuildManifest:manifest Data:deviceInfo Baseband:NO arm64:YES cydia:cydiaEnabled];
                    }
                }
                
                NSString *shsh = [[NSString alloc] initWithData:shshData encoding:NSUTF8StringEncoding];
                if ([shsh containsString:@"STATUS=0&MESSAGE=SUCCESS&REQUEST_STRING="]) {
                    shsh = [shsh stringByReplacingOccurrencesOfString:@"STATUS=0&MESSAGE=SUCCESS&REQUEST_STRING=" withString:@""];
                    NSError *error;
                    [shsh writeToFile:[savePath stringByAppendingPathComponent:filename] atomically:NO encoding:NSUTF8StringEncoding error:&error];
                    if (error == nil) {
                        NSLog(@"SHSH saved with name: %@", filename);
                    } else {
                        NSLog(@"%@", error.description);
                    }
                }
                
            } else {
                NSLog(@"%@ already saved.", filename);
            }
            dispatch_sync((dispatch_get_main_queue()), ^{
                [self.progressBar incrementBy:1];
                progressCount = progressCount + 1;
                [self.progressBarLabel setStringValue:[NSString stringWithFormat:@"%d of %lu SHSH saved", progressCount,(unsigned long)[self.firmwares count]]];
            });
        }
        
        dispatch_sync((dispatch_get_main_queue()), ^{
            self.saveButton.enabled = YES;
            self.saveButtonCydia.enabled = YES;
            [self.progressBar stopAnimation:nil];
            self.progressBar.doubleValue = 0;
            if ([self.firmwares count] > 0) {
                [self.progressBarLabel setStringValue:@"All SHSH saved"];
            } else {
                [self.progressBarLabel setStringValue:@"No SHSH to save"];
            }
        });
    });
}

- (IBAction)saveButtonCydia:(id)sender {
    [self saveSHSH:YES];
}


@end
