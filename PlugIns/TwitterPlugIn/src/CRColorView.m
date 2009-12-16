//
//  CRColorView.m
//  TwitterPlugIn
//
//  Created by Todd Ditchendorf on 11/4/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import "CRColorView.h"

@implementation CRColorView

- (id)initWithFrame:(NSRect)r {
    if (self = [super initWithFrame:r]) {
        self.color = [NSColor colorWithDeviceWhite:.9 alpha:1];
    }
    return self;
}


- (void)dealloc {
    self.color = nil;
    [super dealloc];
}


- (void)drawRect:(NSRect)r {
    [color set];
    NSRectFill(r);
}

@synthesize color;
@end
