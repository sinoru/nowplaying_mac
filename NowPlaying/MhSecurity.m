//
//  MhSecurity.m
//  NowPlaying
//
//  Created by Muhotchi on 1/16/16.
//  Copyright © 2016 Muhotchi. All rights reserved.
//
#import "MhSecurity.h"


@implementation MhSecurity

+ (NSString*)StringFromUserDefaults:(NSString*)key {
    NSString* data = [[NSUserDefaults standardUserDefaults] valueForKey:key];
    if(!data) return nil;
    return [[NSString alloc] initWithData:[MhSecurity AES256Decrypt:data WithKey:ENCRYPT_KEY] encoding:NSUTF8StringEncoding];
}
+ (void)SaveToUserDefaults:(NSString*)value key:(NSString*)key {
    NSString* data = [MhSecurity AES256Encrypt:[value dataUsingEncoding:NSUTF8StringEncoding] WithKey:ENCRYPT_KEY];
    [[NSUserDefaults standardUserDefaults] setValue:data forKey:key];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

+ (NSString*)AES256Encrypt:(NSData*)data WithKey:(NSString*)key {
    NSData* keyData = [key dataUsingEncoding:NSUTF8StringEncoding];
    
    size_t bufferSize = [data length] + kCCBlockSizeAES128;
    void* buffer = malloc(bufferSize);
    
    size_t numBytesDecrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCEncrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding | kCCOptionECBMode, keyData.bytes, kCCKeySizeAES256, NULL, [data bytes], [data length], buffer, bufferSize, &numBytesDecrypted);
    
    if(cryptStatus == kCCSuccess) {
        data = [NSData dataWithBytesNoCopy:buffer length:numBytesDecrypted];
        return [data base64EncodedStringWithOptions:NSDataBase64Encoding64CharacterLineLength];
    }
    free(buffer);
    return nil;
}

+ (NSData*)AES256Decrypt:(NSString*)encrypted WithKey:(NSString*)key {
    NSData* data = [[NSMutableData alloc] initWithBase64EncodedString:encrypted options:NSDataBase64DecodingIgnoreUnknownCharacters];
    NSData* keyData = [key dataUsingEncoding:NSUTF8StringEncoding];
    
    size_t bufferSize = [data length] + kCCBlockSizeAES128;
    void* buffer = malloc(bufferSize);
    
    size_t numBytesDecrypted = 0;
    CCCryptorStatus cryptStatus = CCCrypt(kCCDecrypt, kCCAlgorithmAES128, kCCOptionPKCS7Padding | kCCOptionECBMode, keyData.bytes, kCCKeySizeAES256, NULL, [data bytes], [data length], buffer, bufferSize, &numBytesDecrypted);
    
    if(cryptStatus == kCCSuccess) {
        return [NSData dataWithBytesNoCopy:buffer length:numBytesDecrypted];
    }
    free(buffer);
    return nil;
}

@end
