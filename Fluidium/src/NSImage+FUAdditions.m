//
//  NSImage+FUAdditions.m
//  Fluidium
//
//  Created by Todd Ditchendorf on 12/5/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import "NSImage+FUAdditions.h"

@implementation NSImage (FUAdditions)

- (NSImage *)FU_scaledImageOfSize:(NSSize)size {
    NSImage *result = [[[NSImage alloc] initWithSize:size] autorelease];
    [result lockFocus];
    NSGraphicsContext *currentContext = [NSGraphicsContext currentContext];
    NSImageInterpolation savedInterpolation = [currentContext imageInterpolation];
    [currentContext setImageInterpolation:NSImageInterpolationHigh];
    NSSize fromSize = [self size];
    [self drawInRect:NSMakeRect(0, 0, size.width, size.height) fromRect:NSMakeRect(0, 0, fromSize.width, fromSize.height) operation:NSCompositeSourceOver fraction:1];
    [currentContext setImageInterpolation:savedInterpolation];
    [result unlockFocus];
    return result;
}

@end
