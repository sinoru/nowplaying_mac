//
//  AppDelegate.m
//  NowPlaying
//
//  Created by Muhotchi on 1/15/16.
//  Copyright © 2016 Muhotchi. All rights reserved.
//
#import "AppDelegate.h"
#import "G.h"
#import "MhSecurity.h"
#import "MhTwitter.h"
#import "ViewController.h"


@interface AppDelegate ()

@end

@implementation AppDelegate


+ (AppDelegate*)appDelegate {
    return [[NSApplication sharedApplication] delegate];
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    [self refreshTwitterToken];
    
    self.statusItem = [[NSStatusBar systemStatusBar] statusItemWithLength:NSVariableStatusItemLength];
    self.statusItem.title = @"";
    
    NSImage* icon = [NSImage imageNamed:@"StatusIcon"];
    icon.template = YES;
    self.statusItem.image = icon;
    self.statusItem.action = @selector(toggleWindow:);
    
    
    NSStoryboard* storyboard = [NSStoryboard storyboardWithName:@"Main" bundle:nil];
    self.popover = [[NSPopover alloc] init];
    self.popover.behavior = NSPopoverBehaviorTransient;
    self.popover.appearance = [NSAppearance appearanceNamed:NSAppearanceNameAqua];
    self.popover.contentViewController = [storyboard instantiateControllerWithIdentifier:@"NowPlaying"];
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
    
}


- (void)refreshTwitterToken {
    NSString* ctoken = [MhSecurity StringFromUserDefaults:KEY_CTOKEN];
    NSString* csecret = [MhSecurity StringFromUserDefaults:KEY_CSECRET];
    NSString* token = [MhSecurity StringFromUserDefaults:KEY_TOKEN];
    NSString* secret = [MhSecurity StringFromUserDefaults:KEY_SECRET];
    
    if(ctoken && csecret) {
        [[MhTwitter instance] setConsumerToken:ctoken secret:csecret];
    }
    else {
        [[MhTwitter instance] setConsumerToken:DEFAULT_TWITTER_TOKEN secret:DEFAULT_TWITTER_SECRET];
    }
    
    if(token && secret) {
        [[MhTwitter instance] setAccessToken:token secret:secret];
    }
    else {
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:KEY_TOKEN];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:KEY_SECRET];
        [[NSUserDefaults standardUserDefaults] removeObjectForKey:KEY_USERID];
        [[NSUserDefaults standardUserDefaults] synchronize];
    }
}


- (IBAction)toggleWindow:(id)sender {
    if(self.popover.shown) {
        [self.popover performClose:sender];
    }
    else {
        [self.popover showRelativeToRect:self.statusItem.button.bounds ofView:self.statusItem.button preferredEdge:NSMinYEdge];
    }
}

- (void)refreshTwitterAccount {
    [(ViewController*)self.popover.contentViewController initTwitterUI];
}

@end
