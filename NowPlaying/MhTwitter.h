//
//  MhTwitter.h
//  NowPlaying
//
//  Created by Muhotchi on 1/15/16.
//  Copyright © 2016 Muhotchi. All rights reserved.
//
#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h>
#import <CommonCrypto/CommonHMAC.h>


#if NS_BLOCKS_AVAILABLE
typedef void (^CallbackHandler)(NSDictionary* result, NSError *error);
#endif

@interface MhTwitter : NSObject

+ (MhTwitter*)instance;

- (void)setConsumerToken:(NSString*)consumerKey secret:(NSString*)consumerSecret;
- (void)setAccessToken:(NSString*)token secret:(NSString*)secret;

- (void)sendTokenRequestWithHandler:(CallbackHandler)handler;
- (void)sendAuthorize:(NSString*)key token:(NSString*)token secret:(NSString*)secret withHandler:(CallbackHandler)handler;

- (void)sendUserInfo:(NSString*)userid withHandler:(CallbackHandler)handler;
- (void)sendUpdate:(NSDictionary*)data withHandler:(CallbackHandler)handler;
- (void)sendBaseEncodedMedia:(NSData*)data withHandler:(CallbackHandler)handler;

@end
