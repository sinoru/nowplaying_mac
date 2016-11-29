//
//  LoginController.m
//  NowPlaying
//
//  Created by Muhotchi on 1/16/16.
//  Copyright © 2016 Muhotchi. All rights reserved.
//
#import "LoginController.h"
#import "G.h"
#import "MhSecurity.h"
#import "MhTwitter.h"
#import "AppDelegate.h"


@interface LoginController ()

@property (copy) NSString* oauthToken;
@property (copy) NSString* oauthSecret;

@end

@implementation LoginController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.oauthToken = @"";
    self.oauthSecret = @"";
    
    self.webview.frameLoadDelegate = self;
    self.webview.hidden = YES;
    
    self.indicator.hidden = NO;
    [self.indicator startAnimation:nil];
    
    [[MhTwitter instance] sendTokenRequestWithHandler:^(NSDictionary* result, NSError* error) {
        if(error) {
            NSAlert* alert = [[NSAlert alloc] init];
            alert.alertStyle = NSCriticalAlertStyle;
            alert.messageText = NSLocalizedString(@"status.twitterloginerror", @"");
            [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
                [self.view.window close];
            }];
            return;
        }
        
        self.oauthToken = [result valueForKey:@"oauth_token"];
        self.oauthSecret = [result valueForKey:@"oauth_token_secret"];
        
        self.webview.hidden = NO;
        
        NSString* url = [@"https://api.twitter.com/oauth/authorize?oauth_token=" stringByAppendingString:[result valueForKey:@"oauth_token"]];
        [self.webview.mainFrame loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
        
        [self.indicator stopAnimation:nil];
        self.indicator.hidden = YES;
    }];
    
}

- (void)webView:(WebView*)sender didFinishLoadForFrame:(WebFrame*)frame {
    DOMDocument* doc = [sender mainFrameDocument];
    DOMNodeList* list = [doc getElementsByTagName:@"code"];
    if(list.length > 0) {
        DOMNode* node = [list item:0];
        //NSLog(@"Authorize Code: %@", node.textContent);
        [self authorize:node.textContent];
    }
}

- (void)authorize:(NSString*)key {
    self.indicator.hidden = NO;
    [self.indicator startAnimation:nil];
    
    [[MhTwitter instance] sendAuthorize:key token:self.oauthToken secret:self.oauthSecret withHandler:^(NSDictionary* result, NSError* error) {
        
        if(error) {
            NSAlert* alert = [[NSAlert alloc] init];
            alert.alertStyle = NSCriticalAlertStyle;
            alert.messageText = NSLocalizedString(@"status.twitterloginerror", @"");
            [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
                [self.view.window close];
            }];
            return;
        }
        
        NSString* token = [result valueForKey:@"oauth_token"];
        NSString* secret = [result valueForKey:@"oauth_token_secret"];
        
        [[MhTwitter instance] setAccessToken:token secret:secret];
        
        [MhSecurity SaveToUserDefaults:token key:KEY_TOKEN];
        [MhSecurity SaveToUserDefaults:secret key:KEY_SECRET];
        [MhSecurity SaveToUserDefaults:[result valueForKey:@"user_id"] key:KEY_USERID];
        
        [self.view.window close];
        
        [[AppDelegate appDelegate] refreshTwitterAccount];
    }];
}


@end
