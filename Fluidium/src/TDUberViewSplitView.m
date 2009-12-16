//  Copyright 2009 Todd Ditchendorf
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

#import "TDUberViewSplitView.h"

@implementation TDUberViewSplitView

- (id)initWithFrame:(NSRect)frame {
    self = [super initWithFrame:frame];
    if (self != nil) {
        self.borderColor = [NSColor colorWithDeviceWhite:.4 alpha:1.];
        
        NSColor *startColor = [NSColor colorWithDeviceWhite:.95 alpha:1.];
        NSColor *endColor = [NSColor colorWithDeviceWhite:.8 alpha:1.];
        self.gradient = [[NSGradient alloc] initWithStartingColor:startColor endingColor:endColor];
        [gradient release];
    }
    return self;
}


- (void)dealloc {
    self.gradient = nil;
    self.borderColor = nil;
    [super dealloc];
}


- (void)drawDividerInRect:(NSRect)rect {
    BOOL isVert = self.isVertical;
    [gradient drawInRect:rect angle:isVert ? 0. : 90.];
    
    [borderColor set];
    NSRect borderRect;
    if (isVert) {
        borderRect = NSOffsetRect(rect, 0., -1.);
        borderRect.size.height += 2.;
    } else {
        borderRect = NSOffsetRect(rect, -1., 0);
        borderRect.size.width += 2.;
    }
    [NSBezierPath strokeRect:borderRect];
}


- (CGFloat)dividerThickness {
    CGFloat result = [super dividerThickness];
    if (result > 2.) {
        result -= 2.;
    }
    return result;
}

@synthesize borderColor;
@synthesize gradient;
@end
