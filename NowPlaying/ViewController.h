//
//  ViewController.h
//  NowPlaying
//
//  Created by Muhotchi on 1/15/16.
//  Copyright © 2016 Muhotchi. All rights reserved.
//
#import <Cocoa/Cocoa.h>
@import STwitter;


@interface ViewController : NSViewController

@property (weak) IBOutlet NSImageView* imgArtwork;
@property (weak) IBOutlet NSTextField* txtArtist;
@property (weak) IBOutlet NSTextField* txtTitle;
@property (weak) IBOutlet NSButton* btnTweet;
@property (weak) IBOutlet NSTextField* txtResult;

@property (weak) IBOutlet NSButton* btnTwitterLogin;
@property (weak) IBOutlet NSImageView* imgTwitterIcon;
@property (weak) IBOutlet NSTextField* txtTwitterName;
@property (weak) IBOutlet NSButton* btnTwitterLogout;

- (void)initTwitterUI;

@end

