//
//  CRBarButtonItemView.m
//  TwitterPlugIn
//
//  Created by Todd Ditchendorf on 10/22/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import "CRBarButtonItemView.h"
#import <UMEKit/UMEBarButtonItem.h>

static NSImage *sLeftImagePlain = nil;
static NSImage *sCenterImagePlain = nil;
static NSImage *sRightImagePlain = nil;

@implementation CRBarButtonItemView

+ (void)initialize {
    if ([CRBarButtonItemView class] == self) {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
        
        NSBundle *b = [NSBundle bundleForClass:[UMEBarButtonItem class]];
        
        sLeftImagePlain     = [[NSImage alloc] initWithContentsOfFile:[b pathForImageResource:@"barbuttonitem_plain_bg_01"]];
        sCenterImagePlain   = [[NSImage alloc] initWithContentsOfFile:[b pathForImageResource:@"barbuttonitem_plain_bg_02"]];
        sRightImagePlain    = [[NSImage alloc] initWithContentsOfFile:[b pathForImageResource:@"barbuttonitem_plain_bg_03"]];
        
        [pool release];
    }
}


- (BOOL)isFlipped {
    return YES;
}


- (void)drawRect:(NSRect)r {
    // draw bg image
    NSImage *leftImage = sLeftImagePlain;
    NSImage *centerImage = sCenterImagePlain;
    NSImage *rightImage = sRightImagePlain;

    [leftImage setFlipped:[self isFlipped]];
    [centerImage setFlipped:[self isFlipped]];
    [rightImage setFlipped:[self isFlipped]];
    
    NSDrawThreePartImage(r, leftImage, centerImage, rightImage, NO, NSCompositeSourceOver, 1.0, NO);
}
    
@end
