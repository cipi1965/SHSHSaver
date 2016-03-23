//
//  ViewController.h
//  SHSHSaver
//
//  Created by Matteo Piccina on 21/03/16.
//  Copyright © 2016 Matteo Piccina. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "MobileDeviceAccess.h"

@interface ViewController : NSViewController <MobileDeviceAccessListener>

@property (strong, nonatomic) NSMutableDictionary *tssRequestDict;
@property (strong, nonatomic) NSArray *firmwares;
@property (strong, nonatomic) AMDevice *connectedDevice;
@property (weak) IBOutlet NSButton *saveButton;
@property (weak) IBOutlet NSButton *saveButtonCydia;
@property (weak) IBOutlet NSTextField *connectedLabel;
@property (weak) IBOutlet NSProgressIndicator *progressBar;
@property (weak) IBOutlet NSTextField *progressBarLabel;
@property (weak) IBOutlet NSImageView *deviceImage;

@end

