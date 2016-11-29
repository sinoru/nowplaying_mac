//
//  NSImage+Resize.m
//  NowPlaying
//
//  Created by Muhotchi on 1/16/16.
//  Copyright © 2016 Muhotchi. All rights reserved.
//

#import "NSImage+Resize.h"

@implementation NSImage (Resize)

- (NSImage*)resizeWidth:(NSUInteger)width {
    if(![self isValid]) return nil;
    
    // source width : source height = dest width : dest height
    // source height * dest width / source width = dest height
    
    NSUInteger height = (int)round(self.size.height * (CGFloat)width / self.size.width);
    
    
    NSImage* newImage = [[NSImage alloc] initWithSize:CGSizeMake(width, height)];
    [newImage lockFocus];
    [self setSize:CGSizeMake(width, height)];
    [[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationHigh];
    [self drawAtPoint:NSZeroPoint fromRect:CGRectMake(0, 0, width, height) operation:NSCompositeCopy fraction:1.0];
    [newImage unlockFocus];
    [newImage setSize:CGSizeMake(width, height)];
    return [[NSImage alloc] initWithData:[newImage TIFFRepresentation]];
}

@end
