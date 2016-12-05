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
    
    [STWOAuth requestRequestTokenWithSession:[AppDelegate appDelegate].twitterSession xAuthMode:STWXAuthModeNone callback:@"oob" handler:^(NSString * _Nullable token, NSString * _Nullable tokenSecret, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if(error) {
                NSAlert* alert = [[NSAlert alloc] init];
                alert.alertStyle = NSCriticalAlertStyle;
                alert.messageText = NSLocalizedString(@"status.twitterloginerror", @"");
                [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
                    [self.view.window close];
                }];
                return;
            }
            
            self.oauthToken = token;
            self.oauthSecret = tokenSecret;
            
            self.webview.hidden = NO;
            
            NSString* url = [@"https://api.twitter.com/oauth/authorize?oauth_token=" stringByAppendingString:token];
            
            [self.webview.mainFrame loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
            
            [self.indicator stopAnimation:nil];
            self.indicator.hidden = YES;
        });
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
    
    [STWOAuth requestAccessTokenWithSession:[AppDelegate appDelegate].twitterSession requestToken:self.oauthToken requestTokenSecret:self.oauthSecret xAuthMode:STWXAuthModeNone xAuthUsername:nil xAuthPassword:nil oauthVerifier:key handler:^(NSString * _Nullable token, NSString * _Nullable tokenSecret, int64_t userID, NSString * _Nullable screenName, NSError * _Nullable error) {
        dispatch_async(dispatch_get_main_queue(), ^{
            if(error) {
                NSAlert* alert = [[NSAlert alloc] init];
                alert.alertStyle = NSCriticalAlertStyle;
                alert.messageText = NSLocalizedString(@"status.twitterloginerror", @"");
                [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
                    [self.view.window close];
                }];
                return;
            }
            
            
            [AppDelegate appDelegate].twitterSession.account = [[STWAccount alloc] initWithOauthToken:token oauthTokenSecret:tokenSecret];
            
            [MhSecurity SaveToUserDefaults:token key:KEY_TOKEN];
            [MhSecurity SaveToUserDefaults:tokenSecret key:KEY_SECRET];
            [MhSecurity SaveToUserDefaults:[NSString stringWithFormat:@"%lli", userID] key:KEY_USERID];
            
            [self.view.window close];
            
            [[AppDelegate appDelegate] refreshTwitterAccount];
        });
    }];
    
}


@end
