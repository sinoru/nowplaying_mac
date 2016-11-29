//
//  ViewController.m
//  NowPlaying
//
//  Created by Muhotchi on 1/15/16.
//  Copyright © 2016 Muhotchi. All rights reserved.
//
#import "ViewController.h"
#import "G.h"
#import "MhSecurity.h"
#import "iTunes.h"
#import "MhTwitter.h"
#import "NSImage+Resize.h"


@interface ViewController ()

@property (strong) iTunesApplication* iTunes;
@property (strong) NSTimer* timer;

@property (assign) NSInteger itunesID;
@property (strong) NSString* tweetMsg;

@property (copy) NSString* twitterURL;
@property (copy) NSString* twitterName;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    self.iTunes = [SBApplication applicationWithBundleIdentifier:@"com.apple.iTunes"];
    self.itunesID = 0;
    
    [self initTwitterUI];
}

- (void)setRepresentedObject:(id)representedObject {
    [super setRepresentedObject:representedObject];

    // Update the view, if already loaded.
}


- (void)initTwitterUI {
    self.btnTwitterLogin.hidden = YES;
    self.btnTwitterLogout.hidden = YES;
    self.imgTwitterIcon.hidden = YES;
    self.txtTwitterName.hidden = YES;
    
    self.imgTwitterIcon.image = nil;
    self.txtTwitterName.stringValue = @"";
    
    NSString* userid = [MhSecurity StringFromUserDefaults:KEY_USERID];
    if([MhSecurity StringFromUserDefaults:KEY_TOKEN] && [MhSecurity StringFromUserDefaults:KEY_SECRET] && userid) {
        [[MhTwitter instance] sendUserInfo:userid withHandler:^(NSDictionary* result, NSError* error) {
            if(error || [result valueForKey:@"error"]) {
                // error
                [self twitterLogout:nil];
                return;
            }
            self.btnTwitterLogout.hidden = NO;
            self.imgTwitterIcon.hidden = NO;
            self.txtTwitterName.hidden = NO;
            
            self.imgTwitterIcon.image = [[NSImage alloc] initWithContentsOfURL:[NSURL URLWithString:[result valueForKey:@"profile_image_url"]]];
            self.txtTwitterName.stringValue = [NSString stringWithFormat:@"%@ (@%@)", [result valueForKey:@"name"], [result valueForKey:@"screen_name"]];
            
            self.btnTweet.enabled = ![self.txtTitle.stringValue isEqualToString:@""]; // same enabled state on textfield
        }];
    }
    else {
        self.btnTwitterLogin.hidden = NO;
    }
}

- (IBAction)twitterLogout:(id)sender {
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:KEY_TOKEN];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:KEY_SECRET];
    [[NSUserDefaults standardUserDefaults] removeObjectForKey:KEY_USERID];
    [[NSUserDefaults standardUserDefaults] synchronize];
    
    self.btnTwitterLogin.hidden = NO;
    self.btnTwitterLogout.hidden = YES;
    self.imgTwitterIcon.hidden = YES;
    self.txtTwitterName.hidden = YES;
    self.imgTwitterIcon.image = nil;
    self.txtTwitterName.stringValue = @"";
    self.btnTweet.enabled = NO;
}


- (void)viewDidAppear {
    [super viewDidAppear];
    
    [self getCurrentTrack];
    
    if(!self.timer) self.timer = [NSTimer scheduledTimerWithTimeInterval:0.1f target:self selector:@selector(getCurrentTrack) userInfo:nil repeats:YES];
}

- (void)viewWillDisappear {
    [super viewWillDisappear];
    
    if(self.timer && self.timer.isValid) {
        [self.timer invalidate];
        self.timer = nil;
    }
}



- (void)getCurrentTrack {
    if([self.iTunes isRunning]) {
        if(iTunesEPlSPlaying == self.iTunes.playerState) {
            iTunesTrack* track = self.iTunes.currentTrack;
            if(track) {
                if(self.itunesID != track.databaseID) {
                    self.txtArtist.stringValue = track.artist;
                    self.txtTitle.stringValue = track.name;
                    
                    NSString* status = [NSString stringWithFormat:@"%@ by %@", track.name, track.artist];
                    if(status.length > 128) status = [[status substringToIndex:127] stringByAppendingString:@"…"];
                    NSInteger rest = 125 - status.length; // 3: " ()"
                    if(rest > 10) {
                        NSString* album = track.album.length > rest ? [[track.album substringToIndex:rest-1] stringByAppendingString:@"…"] : track.album;
                        status = [status stringByAppendingFormat:@" (%@)", album];
                    }
                    status = [status stringByAppendingString:@" #nowplaying"];
                    self.tweetMsg = status;
                    
                    iTunesArtwork* artwork = track.artworks.count > 0 ? [track.artworks firstObject] : nil;
                    if(artwork && artwork.data) {
                        if([artwork.data class] == [NSImage class]) {
                            self.imgArtwork.image = [artwork.data resizeWidth:800];
                            
                        }
                        else if([artwork.data class] == [NSAppleEventDescriptor class]) {
                            NSAppleEventDescriptor* desc = (NSAppleEventDescriptor*)artwork.data;
                            NSImage* image = [[NSImage alloc] initWithData:desc.data];
                            self.imgArtwork.image = [image resizeWidth:800];
                        }
                    }
                    self.itunesID = track.databaseID;
                    
                    self.txtResult.stringValue = [NSString localizedStringWithFormat:NSLocalizedString(@"status.tweetlength", nil), status.length];
                    self.btnTweet.enabled = !self.btnTwitterLogout.hidden;
                }
            } else {
                [self disableiTunes:NSLocalizedString(@"status.ituneserror", nil)];
            }
        }
        else {
            [self disableiTunes:NSLocalizedString(@"status.itunesnotplaying", nil)];
        }
    }
    else {
        [self disableiTunes:NSLocalizedString(@"status.itunesnotrunning", nil)];
    }
}

- (void)disableiTunes:(NSString*)error {
    self.imgArtwork.image = nil;
    self.txtArtist.stringValue = @"";
    self.txtTitle.stringValue = @"";
    self.btnTweet.enabled = NO;
    self.txtResult.stringValue = @"";
    self.itunesID = -1;
    self.txtResult.stringValue = error;
    self.tweetMsg = nil;
}




- (IBAction)sendTweet:(id)sender {
    self.btnTweet.enabled = NO;
    
    if(self.imgArtwork.image == nil) {
        [[MhTwitter instance] sendUpdate:@{@"status": self.tweetMsg} withHandler:^(NSDictionary* resultDictonary, NSError* error) {
            self.btnTweet.enabled = YES;
            if(resultDictonary) {
                self.txtResult.stringValue = NSLocalizedString(@"status.tweetsuccess",nil);
            } else {
                self.txtResult.stringValue = NSLocalizedString(@"status.tweeterror", nil);
            }
        }];
    }
    else {
        // change to jpeg
        NSArray* representations = [self.imgArtwork.image representations];
        NSNumber* compressionFactor = [NSNumber numberWithFloat:0.7f];
        NSDictionary* imageProps = [NSDictionary dictionaryWithObject:compressionFactor forKey:NSImageCompressionFactor];
        NSData* bitmapData = [NSBitmapImageRep representationOfImageRepsInArray:representations usingType:NSJPEGFileType properties:imageProps];
        
        [[MhTwitter instance] sendBaseEncodedMedia:bitmapData withHandler:^(NSDictionary *resultDictonary, NSError *error) {
            if(resultDictonary) {
                //NSLog(@"Success with media ID : %@", [resultDictonary valueForKey:@"media_id_string"]);
                [[MhTwitter instance] sendUpdate:@{@"status": self.tweetMsg, @"media_ids": [resultDictonary valueForKey:@"media_id_string"]} withHandler:^(NSDictionary* resultDictonary, NSError* error) {
                    self.btnTweet.enabled = YES;
                    if(resultDictonary) {
                        self.txtResult.stringValue = NSLocalizedString(@"status.tweetsuccess", nil);
                    } else {
                        self.txtResult.stringValue = NSLocalizedString(@"status.tweeterror", nil);
                    }
                }];
                
            }
            else {
                //NSLog(@"Failure : %@", [error description]);
                self.txtResult.stringValue = NSLocalizedString(@"status.tweeterror", nil);
                self.btnTweet.enabled = YES;
            }
        }];
    }
}


- (IBAction)clickBtnTerminate:(id)sender {
    [[NSRunningApplication currentApplication] terminate];
}


@end
