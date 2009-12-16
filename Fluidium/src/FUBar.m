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

#import "FUBar.h"
#import "FUUtils.h"

@implementation FUBar

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.mainBgGradient = nil;
    self.nonMainBgGradient = nil;
    self.mainTopBorderColor = nil;
    self.nonMainTopBorderColor = nil;
    self.mainTopBevelColor = nil;
    self.nonMainTopBevelColor = nil;
    self.mainBottomBevelColor = nil;
    self.nonMainBottomBevelColor = nil;
    [super dealloc];
}


- (void)awakeFromNib {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(windowDidBecomeMain:) name:NSWindowDidBecomeMainNotification object:[self window]];
    [nc addObserver:self selector:@selector(windowDidResignMain:) name:NSWindowDidResignMainNotification object:[self window]];
    
    NSColor *bgColor = [NSColor colorWithDeviceWhite:.77 alpha:1];
    self.mainBgGradient = [[[NSGradient alloc] initWithStartingColor:[bgColor colorWithAlphaComponent:.7] endingColor:bgColor] autorelease];
    bgColor = [NSColor colorWithDeviceWhite:.93 alpha:1];
    self.nonMainBgGradient = [[[NSGradient alloc] initWithStartingColor:[bgColor colorWithAlphaComponent:.7] endingColor:bgColor] autorelease];
    self.mainTopBorderColor = [NSColor colorWithDeviceWhite:.53 alpha:1];
    self.nonMainTopBorderColor = [NSColor colorWithDeviceWhite:.78 alpha:1];
    self.mainTopBevelColor = [NSColor colorWithDeviceWhite:.88 alpha:1];
    self.nonMainTopBevelColor = [NSColor colorWithDeviceWhite:.99 alpha:1];
    self.mainBottomBevelColor = [NSColor lightGrayColor];
    self.nonMainBottomBevelColor = [NSColor colorWithDeviceWhite:.99 alpha:1];
}


- (void)windowDidBecomeMain:(NSNotification *)n {
    [self setNeedsDisplay:YES];
}


- (void)windowDidResignMain:(NSNotification *)n {
    [self setNeedsDisplay:YES];
}


- (void)drawRect:(NSRect)rect {
    //NSDrawWindowBackground(rect);

    NSGradient *bgGradient = nil;
    NSColor *topBorderColor = nil;
    NSColor *topBevelColor = nil;
    NSColor *bottomBevelColor = nil;
    if ([[self window] isMainWindow]) {
        bgGradient = mainBgGradient;
        topBorderColor = mainTopBorderColor;
        topBevelColor = mainTopBevelColor;
        bottomBevelColor = mainBottomBevelColor;
    } else {
        bgGradient = nonMainBgGradient;
        topBorderColor = nonMainTopBorderColor;
        topBevelColor = nonMainTopBevelColor;
        bottomBevelColor = nonMainBottomBevelColor;
    }

    // background
    if (bgGradient) {
        [bgGradient drawInRect:rect angle:270];
    }
    
    CGFloat y = NSMaxY([self bounds]) - 1.5;
    NSPoint p1 = NSMakePoint(0.0, y);
    NSPoint p2 = NSMakePoint(NSWidth(rect), y);

    NSBezierPath *path = [NSBezierPath bezierPath];
    [path setLineWidth:1.0];

    // top bevel
    if (topBevelColor) {
        [topBevelColor set];
        [path moveToPoint:p1];
        [path lineToPoint:p2];
        [path stroke];
    }

    // top border
    if (topBorderColor) {
        [topBorderColor set];
        p1.y += 1.0;
        p2.y += 1.0;
        [path removeAllPoints];
        [path moveToPoint:p1];
        [path lineToPoint:p2];
        [path stroke];
    }

    // bottom bevel
    if (bottomBevelColor) {
        [bottomBevelColor set];
        p1 = NSMakePoint(0.0, 0.5);
        p2 = NSMakePoint(NSWidth(rect), 0.5);
        [path removeAllPoints];
        [path moveToPoint:p1];
        [path lineToPoint:p2];
        [path stroke];
    }
}

@synthesize mainBgGradient;
@synthesize nonMainBgGradient;
@synthesize mainTopBorderColor;
@synthesize nonMainTopBorderColor;
@synthesize mainTopBevelColor;
@synthesize nonMainTopBevelColor;
@synthesize mainBottomBevelColor;
@synthesize nonMainBottomBevelColor;
@end
