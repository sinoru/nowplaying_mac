//
//  PrefController.m
//  NowPlaying
//
//  Created by Muhotchi on 1/16/16.
//  Copyright © 2016 Muhotchi. All rights reserved.
//
#import "PrefController.h"
#import "G.h"
#import "MhSecurity.h"
#import "AppDelegate.h"


@interface PrefController ()

@end

@implementation PrefController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    NSString* ctoken = [MhSecurity StringFromUserDefaults:KEY_CTOKEN];
    NSString* csecret = [MhSecurity StringFromUserDefaults:KEY_CSECRET];
    
    if(ctoken) self.txtKey.stringValue = ctoken;
    if(csecret) self.txtSecret.stringValue = csecret;
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];
    
}

- (IBAction)changeConsumerToken:(id)sender {
    NSString* ctoken = [self.txtKey.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    NSString* csecret = [self.txtSecret.stringValue stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    
    NSString* otoken = [MhSecurity StringFromUserDefaults:KEY_CTOKEN];
    NSString* osecret = [MhSecurity StringFromUserDefaults:KEY_CSECRET];
    if(!otoken) otoken = @"";
    if(!osecret) osecret = @"";
    
    if([otoken isEqualToString:ctoken] && [osecret isEqualToString:csecret]) {
        [self.view.window close];
        return;
    }
    
    
    
    if(([ctoken isEqualToString:@""] && ![csecret isEqualToString:@""]) || (![ctoken isEqualToString:@""] && [csecret isEqualToString:@""])) {
        NSAlert* alert = [[NSAlert alloc] init];
        alert.alertStyle = NSCriticalAlertStyle;
        alert.messageText = NSLocalizedString(@"status.prefbothfield", @"");
        [alert beginSheetModalForWindow:self.view.window completionHandler:nil];
        return;
    }
    
    NSAlert* alert = [[NSAlert alloc] init];
    alert.alertStyle = NSInformationalAlertStyle;
    alert.messageText = NSLocalizedString(@"status.prefconfirm", @"");
    [alert addButtonWithTitle:NSLocalizedString(@"status.ok", @"")];
    [alert addButtonWithTitle:NSLocalizedString(@"status.cancel", @"")];
    [alert beginSheetModalForWindow:self.view.window completionHandler:^(NSModalResponse returnCode) {
        if(returnCode == 1000) {
            if([ctoken isEqualToString:@""] && [csecret isEqualToString:@""]) {
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:KEY_CTOKEN];
                [[NSUserDefaults standardUserDefaults] removeObjectForKey:KEY_CSECRET];
            }
            else {
                [MhSecurity SaveToUserDefaults:ctoken key:KEY_CTOKEN];
                [MhSecurity SaveToUserDefaults:csecret key:KEY_CSECRET];
            }
            
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:KEY_TOKEN];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:KEY_SECRET];
            [[NSUserDefaults standardUserDefaults] removeObjectForKey:KEY_USERID];
            [[NSUserDefaults standardUserDefaults] synchronize];
            
            [[AppDelegate appDelegate] refreshTwitterToken];
            [[AppDelegate appDelegate] refreshTwitterAccount];
            
            [self.view.window close];
        }
    }];
}

@end
