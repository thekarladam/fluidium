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

#import "FUFindPanelView.h"

@implementation FUFindPanelView

- (id)initWithFrame:(NSRect)frame {
    if (self = [super initWithFrame:frame]) {
        self.borderColor = [NSColor colorWithCalibratedWhite:.4 alpha:1];
        
        NSColor *startColor = [NSColor colorWithCalibratedWhite:.95 alpha:1];
        NSColor *endColor = [NSColor colorWithCalibratedWhite:.8 alpha:1];
        self.gradient = [[[NSGradient alloc] initWithStartingColor:startColor endingColor:endColor] autorelease];
    }
    return self;
}


- (void)dealloc {
    self.gradient = nil;
    self.borderColor = nil;
    [super dealloc];
}


- (void)drawRect:(NSRect)rect {
    [gradient drawInRect:rect angle:270];

    [borderColor set];
    NSPoint p1 = NSMakePoint(0, rect.size.height);
    NSPoint p2 = NSMakePoint(rect.size.width, rect.size.height);
    [NSBezierPath strokeLineFromPoint:p1 toPoint:p2];
}

@synthesize borderColor;
@synthesize gradient;
@end
