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

#import "FUBookmarkButtonSeparator.h"


@implementation FUBookmarkButtonSeparator

- (id)init {
    if (self = [super initWithFrame:NSMakeRect(0, 0, 8, 20)]) {

    }
    return self;
}


- (void)drawRect:(NSRect)inRect {
    CGRect rect = NSRectToCGRect(inRect);
    CGContextRef c = [[NSGraphicsContext currentContext] graphicsPort];
    
    //clear
    CGContextSetRGBFillColor(c, 0, 0, 0, 0);
    CGContextFillRect(c, rect);

    CGContextSaveGState(c);

    CGFloat y = 4, x = rect.size.width / 2;
    
    NSInteger i;
    for (i = 0; i < 2; i++) {
        if (0 == i) {
            CGContextTranslateCTM(c, 1, -1);
            CGContextSetRGBFillColor(c, .7, .7, .7, 1);
        } else {
            CGContextRestoreGState(c);
            CGContextSetRGBFillColor(c, .3, .3, .3, 1);
        }

        // draw bar
        CGRect r = CGRectMake(rect.size.width / 2 - 1, 2, 2, rect.size.height - 4);
        CGContextFillRect(c, r);
                
        // draw circle
        CGContextBeginPath(c);
        CGContextMoveToPoint(c, x, y);
        CGContextAddArc(c, x, y, 3, 0, 2*M_PI, 0);
        CGContextClosePath(c);
        CGContextFillPath(c);
    }
    
    // center of circle
    CGContextSetRGBFillColor(c, 150.0/255.0, 150.0/255.0, 150.0/255.0, 1);
    CGContextBeginPath(c);
    CGContextMoveToPoint(c, x, y);
    CGContextAddArc(c, x, y, 1, 0, 2*M_PI, 0);
    CGContextClosePath(c);
    CGContextFillPath(c);
}

@end
