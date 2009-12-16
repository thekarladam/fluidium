//
//  CRColorView.h
//  TwitterPlugIn
//
//  Created by Todd Ditchendorf on 11/4/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CRColorView : NSView {
    NSColor *color;
}

@property (nonatomic, retain) NSColor *color;
@end
