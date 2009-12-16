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

#import "FUBookmarkBarButtonCell.h"
#import "FUBookmarkBarButton.h"
#import "NSBezierPath+PXRoundedRectangleAdditions.h"

@interface NSCell (TextAttributes)
- (id)_textAttributes;
@end

@interface FUBookmarkBarButtonCell ()
- (NSColor *)foregroundColor;
- (NSColor *)highlightedForegroundColor;
- (NSColor *)shadowColor;
- (NSColor *)highlightedShadowColor;
- (NSColor *)highlightedBackgroundColor;
- (NSColor *)pressedBackgroundColor;
@end

@implementation FUBookmarkBarButtonCell

- (NSColor *)foregroundColor {
    NSColor *color = nil;
    if ([[[self controlView] window] isMainWindow]) {
        color = [NSColor colorWithCalibratedWhite:.2 alpha:1];
    } else {
        color = [NSColor colorWithCalibratedWhite:.4 alpha:1];
    }
    return color;
}


- (NSColor *)highlightedForegroundColor {
    return [NSColor colorWithCalibratedWhite:.1 alpha:1];
}


- (NSColor *)shadowColor {
    return [NSColor clearColor];
}


- (NSColor *)highlightedShadowColor {
    return [NSColor clearColor];
}


- (NSColor *)highlightedBackgroundColor {
    NSColor *color = nil;
    if ([[[self controlView] window] isMainWindow]) {
        color = [NSColor colorWithCalibratedWhite:.52 alpha:1];
    } else {
        color = [NSColor colorWithCalibratedWhite:.79 alpha:1];
    }
    return color;
}


- (NSColor *)pressedBackgroundColor {
    return [NSColor colorWithCalibratedWhite:.47 alpha:1];
}


- (id)initTextCell:(NSString *)s {
    if (self = [super initTextCell:s]) {
        [self setBordered:NO];
        [self setButtonType:NSMomentaryChangeButton];
        [self setImagePosition:NSImageRight];
        [self setFont:[NSFont boldSystemFontOfSize:11]];
        [self setLineBreakMode:NSLineBreakByTruncatingMiddle];
        [self setWraps:NO];
        [self setControlSize:NSSmallControlSize];
    }
    return self;
}


- (NSDictionary *)_textAttributes {
    NSMutableDictionary *attrs = [[[super _textAttributes] mutableCopy] autorelease];
    
    NSColor *foregroundColor = nil;
    NSColor *shadowColor = nil;
    
    // For highlight on
    if ([self isHighlighted]) {
        foregroundColor = [self highlightedForegroundColor];
        shadowColor = [self highlightedShadowColor];
    } else {
        foregroundColor = [self foregroundColor];
        shadowColor = [self shadowColor];
    }
    
    if (foregroundColor) {
        [attrs setObject:foregroundColor forKey:NSForegroundColorAttributeName];
    }

    NSShadow *shadow = [[[NSShadow alloc] init] autorelease];
    //CGFloat shadowAlpha = ([self state] == NSOnState || self.isHighlighted) ? 1 : 1;
    //[shadow setShadowColor:[shadowColor colorWithAlphaComponent:shadowAlpha]];
    [shadow setShadowColor:shadowColor];
    [shadow setShadowOffset:NSMakeSize(0, 1)];
    [shadow setShadowBlurRadius:0];
    [attrs setObject:shadow forKey:NSShadowAttributeName];
    
    return attrs;
}


- (void)drawWithFrame:(NSRect)cellFrame inView:(NSView *)controlView {
    // Check dragging event
    NSEventType eventType = [[NSApp currentEvent] type];
    if (eventType == NSLeftMouseDragged || eventType == NSRightMouseDragged) {
        // Clear hovered
        [(FUBookmarkBarButton*)controlView setHovered:NO];
    } else {
        // Draw hoverd background
        NSPoint point = [[controlView window] mouseLocationOutsideOfEventStream];
        point = [controlView convertPoint:point fromView:nil];

        id path = [NSBezierPath bezierPathWithRoundedRect:NSInsetRect(cellFrame, 0, 1)
                                             cornerRadius:2.0
                                                inCorners:OSTopLeftCorner|OSTopRightCorner|OSBottomLeftCorner|OSBottomRightCorner];
        if (NSPointInRect(point, cellFrame)) {
            if ([self isHighlighted] || [self isSelected]) {
                [[self pressedBackgroundColor] set];
            } else {
                [[self highlightedBackgroundColor] set];
            }
            [path fill];
            
            // Set hovered
            [(FUBookmarkBarButton*)controlView setHovered:YES];
        } else {
            // Clear hovered
            [(FUBookmarkBarButton*)controlView setHovered:NO];
        }
    }

    // Draw title and image
    cellFrame.origin.y -= 1;
    cellFrame.origin.x += 4;
    cellFrame.size.width -= 8;
    [self drawInteriorWithFrame:cellFrame inView:controlView];
}

@end
