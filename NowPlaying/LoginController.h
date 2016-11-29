//
//  LoginController.h
//  NowPlaying
//
//  Created by Muhotchi on 1/16/16.
//  Copyright © 2016 Muhotchi. All rights reserved.
//
#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>


@interface LoginController : NSViewController <WebFrameLoadDelegate>

@property (weak) IBOutlet WebView* webview;
@property (weak) IBOutlet NSProgressIndicator* indicator;

@end
