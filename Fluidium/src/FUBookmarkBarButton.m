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

#import "FUBookmarkBarButton.h"
#import "FUBookmarkBar.h"
#import "FUBookmark.h"
#import "FUBookmarkBarButtonCell.h"
#import "WebKitPrivate.h"
#import "WebIconDatabase+FUAdditions.h"
#import "WebURLsWithTitles.h"
#import <WebKit/WebKit.h>

#define ICON_SIDE 16

@interface NSToolbarPoofAnimator
+ (void)runPoofAtPoint:(NSPoint)p;
@end

@implementation FUBookmarkBarButton

+ (Class)cellClass {
    return [FUBookmarkBarButtonCell class];
}


- (id)initWithBookmarkBar:(FUBookmarkBar *)bar item:(id)anItem {
    if (self = [super init]) {
        self.bookmarkBar = bar;
        self.item = anItem;
        //if ([[FUUserDefaults instance] showIconsInBookmarkBar]) {
        //    [self setImagePosition:NSImageLeft];
        //    [self setImage:[[WebIconDatabase sharedIconDatabase] FU_faviconForURL:item.content]];
        //}
        [self setTitle:[item valueForKey:@"title"]];
        [self setBezelStyle:NSRecessedBezelStyle];
        [self setShowsBorderOnlyWhileMouseInside:YES];
    }
    return self;
}


- (void)dealloc {
    self.bookmarkBar = nil;
    self.item = nil;
    [super dealloc];
}


- (void)mouseDown:(NSEvent *)evt {
    [[self cell] setHighlighted:YES];
    
    BOOL keepOn = YES;
    NSPoint p = [evt locationInWindow];
    NSInteger radius = 20;
    NSRect r = NSMakeRect(p.x - radius, p.y - radius, radius * 2, radius * 2);
    
    while (keepOn) {
        evt = [[self window] nextEventMatchingMask:NSLeftMouseUpMask|NSLeftMouseDraggedMask];
        
        switch ([evt type]) {
            case NSLeftMouseDragged:
                if (NSPointInRect([evt locationInWindow], r)) {
                    break;
                }
                [self mouseDragged:evt];
                keepOn = NO;
                break;
            case NSLeftMouseUp:
                keepOn = NO;
                [super mouseDown:evt];
                break;
            default:
                break;
        }
    }
    return;
}


- (void)mouseDragged:(NSEvent *)evt {    
    [bookmarkBar startedDraggingButton:self];

    NSArray *types = [NSArray arrayWithObject:WebURLsWithTitlesPboardType];
    NSPasteboard *pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
    [pboard declareTypes:types owner:nil];
    
    [WebURLsWithTitles writeURLs:[NSArray arrayWithObject:[NSURL URLWithString:item.content]]
                       andTitles:[NSArray arrayWithObject:item.title]
                    toPasteboard:pboard];
        
    NSImage *dragImage = [[WebIconDatabase sharedIconDatabase] FU_defaultFavicon];
    NSPoint dragPosition = [self convertPoint:[evt locationInWindow] fromView:nil];

    CGFloat delta = ICON_SIDE / 2;
    dragPosition.x -= delta;
    dragPosition.y += delta;

    [self dragImage:dragImage
                 at:dragPosition
             offset:NSZeroSize
              event:evt
         pasteboard:pboard
             source:self
          slideBack:NO];
}


- (NSDragOperation)draggingSourceOperationMaskForLocal:(BOOL)isLocal {
    return (NSDragOperationMove|NSDragOperationDelete);
}


- (void)draggedImage:(NSImage *)image endedAt:(NSPoint)endPoint operation:(NSDragOperation)op {
    NSPoint p = [[bookmarkBar window] convertScreenToBase:endPoint];
    CGFloat delta = ICON_SIDE / 2;
    p.x += delta;
    p.y += delta;
    NSRect frame = [bookmarkBar frame];

    // had to add this when i manually implemented a toolbar. dunno why.
    frame.origin.y += 18;
    //frame.origin.y += 23;
    
    if (!NSPointInRect(p, frame)) {
        endPoint.x += delta;
        endPoint.y += delta;
        [NSToolbarPoofAnimator runPoofAtPoint:endPoint];
    }
    [bookmarkBar startedDraggingButton:nil];
}

@synthesize hovered;
@synthesize bookmarkBar;
@synthesize item;
@end
