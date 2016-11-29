//
//  MhTwitter.m
//  NowPlaying
//
//  Created by Muhotchi on 1/15/16.
//  Copyright © 2016 Muhotchi. All rights reserved.
//
#import "MhTwitter.h"


static MhTwitter* _instance;

@interface MhTwitter ()

@property (copy) NSString* consumerKey;
@property (copy) NSString* consumerSecret;
@property (copy) NSString* accessToken;
@property (copy) NSString* accessSecret;

@end

@implementation MhTwitter

+ (MhTwitter*)instance {
    if(!_instance) _instance = [[MhTwitter alloc] init];
    return _instance;
}

#pragma Initialize
- (void)setConsumerToken:(NSString*)consumerKey secret:(NSString*)consumerSecret {
    self.consumerKey = consumerKey;
    self.consumerSecret = consumerSecret;
    self.accessToken = @"";
    self.accessSecret = @"";
}
- (void)setAccessToken:(NSString*)token secret:(NSString*)secret {
    self.accessToken = token;
    self.accessSecret = secret;
}



#pragma Authorize
- (void)sendTokenRequestWithHandler:(CallbackHandler)handler {
    [self sendRequest:@{@"oauth_callback": @"oob"} token:@"" secret:@"" method:@"POST" URL:@"https://api.twitter.com/oauth/request_token" handler:handler];
}
- (void)sendAuthorize:(NSString*)key token:(NSString*)token secret:(NSString*)secret withHandler:(CallbackHandler)handler {
    [self sendRequest:@{@"oauth_verifier": key} token:token secret:secret method:@"POST" URL:@"https://api.twitter.com/oauth/access_token" handler:handler];
}



#pragma API
- (void)sendUserInfo:(NSString*)userid withHandler:(CallbackHandler)handler {
    [self sendRequest:@{@"user_id": userid} token:self.accessToken secret:self.accessSecret method:@"GET" URL:@"https://api.twitter.com/1.1/users/show.json" handler:handler];
}

- (void)sendUpdate:(NSDictionary*)data withHandler:(CallbackHandler)handler {
    [self sendRequest:data token:self.accessToken secret:self.accessSecret method:@"POST" URL:@"https://api.twitter.com/1.1/statuses/update.json" handler:handler];
}
- (void)sendBaseEncodedMedia:(NSData*)data withHandler:(CallbackHandler)handler {
    // TODO : multipart/form-data?
    [self sendRequest:@{@"media_data": [[NSString alloc] initWithData:[data base64EncodedDataWithOptions:NSDataBase64Encoding64CharacterLineLength] encoding:NSUTF8StringEncoding]} token:self.accessToken secret:self.accessSecret method:@"POST" URL:@"https://upload.twitter.com/1.1/media/upload.json" handler:handler];
}


#pragma Initial Methods: process

- (void)sendRequest:(NSDictionary*)data token:(NSString*)token secret:(NSString*)secret method:(NSString*)method URL:(NSString*)url handler:(CallbackHandler)handler {
    NSString* timestamp = [NSString stringWithFormat:@"%d", (int)floor([[NSDate date] timeIntervalSince1970])];
    NSString* nonce = [self.consumerKey stringByAppendingFormat:@"%@", timestamp];
    
    NSMutableDictionary* headers = [[NSMutableDictionary alloc] init];
    [headers setValue:self.consumerKey forKey:@"oauth_consumer_key"];
    [headers setValue:nonce forKey:@"oauth_nonce"];
    [headers setValue:@"HMAC-SHA1" forKey:@"oauth_signature_method"];
    [headers setValue:timestamp forKey:@"oauth_timestamp"];
    [headers setValue:token forKey:@"oauth_token"];
    [headers setValue:@"1.0" forKey:@"oauth_version"];
    for(NSString* k in data) [headers setValue:[data valueForKey:k] forKey:k];
    
    NSString* baseString = [NSString stringWithFormat:@"%@&%@&%@", method, [self URLEncodeWithString:url], [self URLEncodeWithString:[self URLEncodeWithDict:headers]]];
    
    NSString* signature = [self HMACSha1:baseString key:[NSString stringWithFormat:@"%@&%@", self.consumerSecret, secret]];
    
    NSString* params = [self URLEncodeWithDict:data];
    
    if(![method isEqualToString:@"POST"] && ![method isEqualToString:@"PUT"]) {
        url = [url stringByAppendingFormat:@"?%@", params];
    }
    
    NSMutableURLRequest* req = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url]];
    req.HTTPMethod = method;
    if([method isEqualToString:@"POST"] || [method isEqualToString:@"PUT"]) {
        req.HTTPBody = [params dataUsingEncoding:NSUTF8StringEncoding];
    }
    
    [req setValue:[NSString stringWithFormat:@"OAuth oauth_consumer_key=\"%@\", oauth_nonce=\"%@\", oauth_signature=\"%@\", oauth_signature_method=\"HMAC-SHA1\", oauth_timestamp=\"%@\", oauth_token=\"%@\", oauth_version=\"1.0\"", self.consumerKey, nonce, [self URLEncodeWithString:signature], timestamp, token] forHTTPHeaderField:@"Authorization"];
    
    NSURLSessionTask* task = [[NSURLSession sharedSession] dataTaskWithRequest:req completionHandler:^(NSData* data, NSURLResponse* response, NSError* error) {
        
        NSDictionary* result;
        if(data) {
            //NSLog(@"Success : %@", [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding]);
            if([url containsString:@"oauth/request_token"] || [url containsString:@"oauth/access_token"]) {
                NSString* dataStr = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                @try {
                    result = [self dictionaryFromQueryString:dataStr];
                }
                @catch(NSException *exception) {
                    error = [NSError errorWithDomain:@"MhTwitter" code:-1 userInfo:@{NSLocalizedDescriptionKey: dataStr}];
                }
            }
            else {
                result = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            }
        }
        
        if(result) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if(handler) handler(result, nil);
            });
        }
        if(error) {
            // NSLog(@"Failed to fetch : %@", error);
            dispatch_async(dispatch_get_main_queue(), ^{
                if(handler) handler(nil, error);
            });
        }
    }];
    [task resume];
}





- (NSString*)URLEncodeWithDict:(NSDictionary*)dict {
    NSString* result = @"";
    
    NSArray* keys = [[dict allKeys] sortedArrayUsingComparator:^NSComparisonResult(NSString* obj1, NSString* obj2) {
        return [obj1 compare:obj2 options:0];
    }];
    
    for(NSString* key in keys) {
        if(![result isEqualToString:@""]) result = [result stringByAppendingString:@"&"];
        
        result = [result stringByAppendingFormat:@"%@=%@", key, [self URLEncodeWithString:[dict valueForKey:key]]];
    }
    return result;
}
- (NSString*)URLEncodeWithString:(NSString*)data {
    NSString* res = [data stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet alphanumericCharacterSet]
            ];
    res = [res stringByReplacingOccurrencesOfString:@"%2D" withString:@"-"];
    res = [res stringByReplacingOccurrencesOfString:@"%5F" withString:@"_"];
    res = [res stringByReplacingOccurrencesOfString:@"%2E" withString:@"."];
    return res;
}

- (NSDictionary*)dictionaryFromQueryString:(NSString*)query {
    NSMutableDictionary* dict = [[NSMutableDictionary alloc] init];
    for(NSString* pair in [query componentsSeparatedByString:@"&"]) {
        NSArray* elements = [pair componentsSeparatedByString:@"="];
        NSString* val = [[elements objectAtIndex:1] stringByRemovingPercentEncoding];
        [dict setValue:val forKey:[elements objectAtIndex:0]];
    }
    return dict;
}

- (NSString*)HMACSha1:(NSString*)data key:(NSString*)key {
    const char *cKey  = [key cStringUsingEncoding:NSASCIIStringEncoding];
    const char *cData = [data cStringUsingEncoding:NSASCIIStringEncoding];
    
    unsigned char cHMAC[CC_SHA1_DIGEST_LENGTH];
    
    CCHmac(kCCHmacAlgSHA1, cKey, strlen(cKey), cData, strlen(cData), cHMAC);
    
    NSData* HMAC = [[NSData alloc] initWithBytes:cHMAC length:sizeof(cHMAC)];
    return [HMAC base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
}

@end
