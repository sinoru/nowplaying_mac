//
//  MhSecurity.h
//  NowPlaying
//
//  Created by Muhotchi on 1/16/16.
//  Copyright © 2016 Muhotchi. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonCryptor.h>
#import "G.h"

@interface MhSecurity : NSObject

+ (NSString*)AES256Encrypt:(NSData*)data WithKey:(NSString*)key;
+ (NSData*)AES256Decrypt:(NSString*)encrypted WithKey:(NSString*)key;

+ (NSString*)StringFromUserDefaults:(NSString*)key;
+ (void)SaveToUserDefaults:(NSString*)value key:(NSString*)key;

@end
