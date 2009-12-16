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

#import "TDGutterView.h"

@interface TDGutterView ()
@property (nonatomic, retain) NSDictionary *attrs;
@end

@implementation TDGutterView

- (void)awakeFromNib {
    self.attrs = [NSDictionary dictionaryWithObjectsAndKeys:
                  [NSFont userFixedPitchFontOfSize:11.], NSFontAttributeName,
                  [NSColor grayColor], NSForegroundColorAttributeName,
                  nil];
    
    self.borderColor = [NSColor grayColor];
}


- (void)dealloc {
    self.sourceScrollView = nil;
    self.sourceTextView = nil;
    self.lineNumberRects = nil;
    self.attrs = nil;
    self.borderColor = nil;
    [super dealloc];
}


- (BOOL)isFlipped {
    return YES;
}


- (NSUInteger)autoresizingMask {
    return NSViewHeightSizable;
}


- (void)drawRect:(NSRect)rect {
    NSDrawWindowBackground(rect);
    
    CGFloat rectWidth = rect.size.width;
    NSPoint p1 = NSMakePoint(rectWidth, 0);
    NSPoint p2 = NSMakePoint(rectWidth, rect.size.height);
    
    [borderColor set];
    [NSBezierPath strokeLineFromPoint:p1 toPoint:p2];
    
    if (!lineNumberRects.count) {
        return;
    }
    
    NSUInteger i = startLineNumber;
    NSUInteger count = i + lineNumberRects.count;
    
    for ( ; i < count; i++) {
        NSRect r = [[lineNumberRects objectAtIndex:i - startLineNumber] rectValue];

        // set the x origin of the number according to the number of digits it contains
        CGFloat x = 0.;
        if (i < 9) {
            x = rectWidth - 14.;
        } else if (i < 99) {
            x = rectWidth - 21.;
        } else if (i < 999) {
            x = rectWidth - 28.;
        } else if (i < 9999) {
            x = rectWidth - 35.;
        }
        r.origin.x = x;
        
        // center the number vertically for tall lines
        if (r.origin.y) {
            r.origin.y += r.size.height/2. - 7.;
        }
        
        NSString *s = [[NSNumber numberWithInteger:i + 1] stringValue];
        NSAttributedString *as = [[NSAttributedString alloc] initWithString:s attributes:attrs];
        [as drawAtPoint:r.origin];
        [as release];
    }
}

@synthesize sourceScrollView;
@synthesize sourceTextView;
@synthesize lineNumberRects;
@synthesize startLineNumber;
@synthesize attrs;
@synthesize borderColor;
@end
