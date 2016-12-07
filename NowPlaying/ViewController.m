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
#import "NSImage+Resize.h"
#import "AppDelegate.h"


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
    
    if ([AppDelegate appDelegate].twitterSession.account != nil) {
        STWUserSessionTask *task = [[AppDelegate appDelegate].twitterSession fetchUserTaskForCurrentAccountAndReturnError:nil completionHandler:^(STWUser * _Nullable user, NSError * _Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if(error) {
                    // error
                    [self twitterLogout:nil];
                    return;
                }
                
                self.btnTwitterLogout.hidden = NO;
                self.imgTwitterIcon.hidden = NO;
                self.txtTwitterName.hidden = NO;
                
                self.imgTwitterIcon.image = [[NSImage alloc] initWithContentsOfURL:user.profileImageURL];
                self.txtTwitterName.stringValue = [NSString stringWithFormat:@"%@ (@%@)", user.name, user.screenName];
                
                self.btnTweet.enabled = ![self.txtTitle.stringValue isEqualToString:@""]; // same enabled state on textfield
            });
        }];
        [task resume];
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
        STWStatusSessionTask *task = [[AppDelegate appDelegate].twitterSession statusUpdateTaskWithStatus:self.tweetMsg possiblySensitive:false mediae:nil error:nil completionHandler:^(STWStatus * _Nullable status, NSError * _Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                self.btnTweet.enabled = YES;
                
                if (error != nil) {
                    self.txtResult.stringValue = NSLocalizedString(@"status.tweeterror", nil);
                    return;
                }
                
                self.txtResult.stringValue = NSLocalizedString(@"status.tweetsuccess",nil);
            });
        }];
        [task resume];
    }
    else {
        // change to jpeg
        NSArray* representations = [self.imgArtwork.image representations];
        NSNumber* compressionFactor = [NSNumber numberWithFloat:0.7f];
        NSDictionary* imageProps = [NSDictionary dictionaryWithObject:compressionFactor forKey:NSImageCompressionFactor];
        NSData* bitmapData = [NSBitmapImageRep representationOfImageRepsInArray:representations usingType:NSJPEGFileType properties:imageProps];
        
        STWMediaSessionTask *task = [[AppDelegate appDelegate].twitterSession uploadPhotoMediaTaskWithPhotoData:bitmapData error:nil completionHandler:^(STWMedia * _Nullable media, NSError * _Nullable error) {
            dispatch_async(dispatch_get_main_queue(), ^{
                if (error != nil) {
                    self.txtResult.stringValue = NSLocalizedString(@"status.tweeterror", nil);
                    return;
                }
                
                STWStatusSessionTask *task = [[AppDelegate appDelegate].twitterSession statusUpdateTaskWithStatus:self.tweetMsg possiblySensitive:false mediae:@[media] error:nil completionHandler:^(STWStatus * _Nullable status, NSError * _Nullable error) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        self.btnTweet.enabled = YES;
                        
                        if (error != nil) {
                            self.txtResult.stringValue = NSLocalizedString(@"status.tweeterror", nil);
                            return;
                        }
                        
                        self.txtResult.stringValue = NSLocalizedString(@"status.tweetsuccess",nil);
                    });
                }];
                [task resume];
            });
        }];
        [task resume];
    }
}


- (IBAction)clickBtnTerminate:(id)sender {
    [[NSRunningApplication currentApplication] terminate];
}


@end
