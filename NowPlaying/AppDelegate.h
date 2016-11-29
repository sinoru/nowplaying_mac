//
//  AppDelegate.h
//  NowPlaying
//
//  Created by Muhotchi on 1/15/16.
//  Copyright © 2016 Muhotchi. All rights reserved.
//
#import <Cocoa/Cocoa.h>


@interface AppDelegate : NSObject <NSApplicationDelegate>

@property (strong) NSPopover* popover;
@property (strong) NSStatusItem* statusItem;

+ (AppDelegate*)appDelegate;

- (void)refreshTwitterToken;
- (void)refreshTwitterAccount;

@end

