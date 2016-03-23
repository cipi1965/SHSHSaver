//
//  SHSH.m
//  SHSHSaver
//
//  Created by Matteo Piccina on 21/03/16.
//  Copyright © 2016 Matteo Piccina. All rights reserved.
//

#import "SHSH.h"
#import <AFNetworking/AFNetworking.h>

@implementation SHSH
+ (NSData *)getSHSHFromDeviceWithBuildManifest:(NSDictionary *)BuildManifest Data:(NSDictionary *)infos Baseband:(BOOL)saveBaseband arm64:(BOOL)isArm64 cydia:(BOOL)getFromCydia
//+ (NSData *)getSHSHFromDeviceWithBuildManifest:(NSDictionary *)BuildManifest ECID:(NSNumber *)ecid ApNonce:(NSData *)ApNonce BbGoldCertId:(NSNumber *)BbGoldCertId BbNonce:(NSData *)BbNonce BbSNUM:(NSData *)BbSNUM SepNonce:(NSData *)SepNonce
{
    
    NSMutableDictionary *tempTssDict = [NSMutableDictionary new];
    
    [tempTssDict setObject:[infos objectForKey:@"ecid"] forKey:@"ApECID"];
    [tempTssDict setObject:[infos objectForKey:@"ApNonce"] forKey:@"ApNonce"];
    [tempTssDict setObject:@YES forKey:@"ApProductionMode"];
    
    if (isArm64) {
        NSLog(@"isArm64");
        [tempTssDict setObject:@YES forKey:@"@ApImg4Ticket"];
        [tempTssDict setObject:[infos objectForKey:@"SepNonce"] forKey:@"SepNonce"];
        [tempTssDict setObject:@YES forKey:@"ApSecurityMode"];
    } else {
        [tempTssDict setObject:@YES forKey:@"@APTicket"];
    }
    
    if (saveBaseband) {
        [tempTssDict setObject:[infos objectForKey:@"BbGoldCertId"] forKey:@"BbGoldCertId"];
        [tempTssDict setObject:[infos objectForKey:@"BbNonce"] forKey:@"BbNonce"];
        [tempTssDict setObject:[infos objectForKey:@"BbSNUM"] forKey:@"BbSNUM"];
        [tempTssDict setObject:@YES forKey:@"@BBTicket"];
    }
    
    __block BOOL passArm64 = isArm64;
    
    [[[BuildManifest objectForKey:@"BuildIdentities"] objectAtIndex:0] enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
        if (![key isEqualToString:@"Manifest"] && ![key isEqualToString:@"Info"]) {
            if ([NSStringFromClass([obj class]) isEqualToString:@"__NSCFData"]) {
                [tempTssDict setObject:obj forKey:key];
            } else {
                if ([obj containsString:@"0x"]) {
                    NSNumber *tempNumber = [NSNumber numberWithInt:(int)[Utils getIntFromHexadecimal:obj]];
                    [tempTssDict setObject:tempNumber forKey:key];
                } else {
                    [tempTssDict setObject:obj forKey:key];
                }
            }
        } else if ([key isEqualToString:@"Manifest"]) {
            [obj enumerateKeysAndObjectsUsingBlock:^(id key, id obj, BOOL *stop) {
                if (![key isEqualToString:@"OS"]) {
                    NSMutableDictionary *tempDict = obj;
                    if (![key isEqualToString:@"BasebandFirmware"]) {
                        if ([tempDict objectForKey:@"Info"] != nil) {
                            [tempDict removeObjectForKey:@"Info"];
                        }
                        if (passArm64) {
                            NSLog(@"Arm64");
                            [tempDict setObject:@YES forKey:@"EPRO"];
                            [tempDict setObject:@YES forKey:@"ESEC"];
                        }
                        if ([key isEqualToString:@"ftap"] && [key isEqualToString:@"ftsp"] && [key isEqualToString:@"rfta"] && [key isEqualToString:@"rfts"]) {
                            [tempDict setObject:[NSData new] forKey:@"Digest"];
                        }
                    }
                    [tempTssDict setObject:tempDict forKey:key];
                }
            }];
        }
        
    }];
    //NSLog(@"%@", tempTssDict);
    NSString *tempFilePath = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"TSSReq_%@_%@.plist", [infos objectForKey:@"ecid"], [[BuildManifest objectForKey:@"SupportedProductTypes"] objectAtIndex:0]]];
    [tempTssDict writeToFile:tempFilePath atomically:NO];
    
    NSURLSessionConfiguration* sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
    
    /* Create session, and optionally set a NSURLSessionDelegate. */
    NSURLSession* session = [NSURLSession sessionWithConfiguration:sessionConfig delegate:nil delegateQueue:nil];
    
    NSURL* URL = [NSURL new];
    if (!getFromCydia) {
        URL = [NSURL URLWithString:@"https://gs.apple.com/TSS/controller"];
    } else {
        URL = [NSURL URLWithString:@"http://cydia.saurik.com/TSS/controller?action=2"];
    }
    NSDictionary* URLParams = @{
                                @"action": @"2",
                                };
    URL = NSURLByAppendingQueryParameters(URL, URLParams);
    NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:URL];
    request.HTTPMethod = @"POST";
    
    // Headers
    
    [request addValue:@"utf8" forHTTPHeaderField:@"charset"];
    [request addValue:@"text/xml" forHTTPHeaderField:@"Content-Type"];
    
    if (getFromCydia) {
        [request addValue:@"gs.apple.com" forHTTPHeaderField:@"Host"];
    }
    // Body
    
    request.HTTPBody = [[NSString stringWithContentsOfFile:tempFilePath encoding:NSUTF8StringEncoding error:nil] dataUsingEncoding:NSUTF8StringEncoding];
    
    __block NSData *result;
    dispatch_semaphore_t sem;
    result = nil;
    
    sem = dispatch_semaphore_create(0);
    
    /* Start a new Task */
    NSURLSessionDataTask* task = [session dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
        if (error == nil) {
            // Success
            NSLog(@"URL Session Task Succeeded: HTTP %ld", ((NSHTTPURLResponse*)response).statusCode);
            /*NSString *shsh = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
            if ([shsh containsString:@"STATUS=0&MESSAGE=SUCCESS&REQUEST_STRING="]) {
                shsh = [shsh stringByReplacingOccurrencesOfString:@"STATUS=0&MESSAGE=SUCCESS&REQUEST_STRING=" withString:@""];
                [shsh writeToFile:@"/Users/matteopiccina/SHSH/test.shsh" atomically:NO encoding:NSUTF8StringEncoding error:nil];
            }*/
            result = data;
            dispatch_semaphore_signal(sem);
        }
        else {
            // Failure
            NSLog(@"URL Session Task Failed: %@", [error localizedDescription]);
        }
    }];
    [task resume];
    
    dispatch_semaphore_wait(sem, DISPATCH_TIME_FOREVER);
    
    return result;
}

static NSString* NSStringFromQueryParameters(NSDictionary* queryParameters)
{
    NSMutableArray* parts = [NSMutableArray array];
    [queryParameters enumerateKeysAndObjectsUsingBlock:^(id key, id value, BOOL *stop) {
        NSString *part = [NSString stringWithFormat: @"%@=%@",
                          [key stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding],
                          [value stringByAddingPercentEscapesUsingEncoding: NSUTF8StringEncoding]
                          ];
        [parts addObject:part];
    }];
    return [parts componentsJoinedByString: @"&"];
}

static NSURL* NSURLByAppendingQueryParameters(NSURL* URL, NSDictionary* queryParameters)
{
    NSString* URLString = [NSString stringWithFormat:@"%@?%@",
                           [URL absoluteString],
                           NSStringFromQueryParameters(queryParameters)
                           ];
    return [NSURL URLWithString:URLString];
}
@end
