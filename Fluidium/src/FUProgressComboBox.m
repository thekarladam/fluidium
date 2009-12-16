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

#import "FUProgressComboBox.h"
#import "HMImageComboBoxCell.h"
#import "FURecentURLController.h"
#import "WebKitPrivate.h"
#import "WebIconDatabase+FUAdditions.h"

#define MAX_VISIBLE_ITEMS 10
#define ESC 53
#define DOWN_ARROW 125
#define UP_ARROW 126

@implementation FUProgressComboBox

- (void)dealloc {
    self.progressImage = nil;
    [super dealloc];
}


- (void)awakeFromNib {
    self.progressImage = [NSImage imageNamed:@"location_field_progress_indicator"];
    self.font = [NSFont controlContentFontOfSize:12];
    [self showDefaultIcon];
}


// click thru support
- (BOOL)acceptsFirstMouse:(NSEvent *)evt {
    return YES;
}


// click thru support
- (BOOL)shouldDelayWindowOrderingForEvent:(NSEvent *)evt {
    return YES;
}


//- (NSArray *)namesOfPromisedFilesDroppedAtDestination:(NSURL *)dest {
//    NSString *title = [[[[self window] windowController] webView] mainFrameTitle];
//    return [NSArray arrayWithObject:title];
//}


- (void)drawRect:(NSRect)inRect {
    [super drawRect:inRect];
    
    NSRect bounds = [self bounds];
    NSSize size = bounds.size;
    
    NSSize pSize = NSMakeSize((size.width - 19) * progress, size.height);
    NSRect pRect = NSMakeRect(bounds.origin.x + 1,
                              bounds.origin.y + 3,
                              pSize.width - 2,
                              pSize.height - 7);
    
    NSRect imageRect = NSZeroRect;
    imageRect.size = [progressImage size];
    imageRect.origin = NSZeroPoint;
    
    [progressImage drawInRect:pRect
                     fromRect:imageRect 
                    operation:NSCompositePlusDarker
                     fraction:1];
    
    NSRect cellRect = [[self cell] drawingRectForBounds:self.bounds];
    cellRect.origin.x -= 2;
    cellRect.origin.y -= 1;
    [[self cell] drawInteriorImageOnlyWithFrame:cellRect inView:self];
}


- (void)setProgress:(CGFloat)p {
    progress = p;
    [self setNeedsDisplay:YES];
}


- (void)showDefaultIcon {
    [self setImage:[[WebIconDatabase sharedIconDatabase] FU_defaultFavicon]];
}


- (void)showPopUpWithItemCount:(NSInteger)count {
    NSWindow *popUp = [(HMImageComboBoxCell *)[self cell] popUp];
    [popUp makeKeyAndOrderFront:self];
    [popUp setOpaque:NO];
    [popUp setAlphaValue:.88];
    
    NSRect winRect = [[self window] frame];
    NSRect textRect = [self convertRect:[self frame] toView:nil];
    
    CGFloat w = textRect.size.width - 7.;
    count++; // add 1 for "clear recent items" item
    count = (count > MAX_VISIBLE_ITEMS) ? MAX_VISIBLE_ITEMS : count;
    CGFloat h = 20 * count;
    CGFloat x = textRect.origin.x + textRect.size.height + winRect.origin.x - 30;
    CGFloat y = textRect.origin.y + winRect.origin.y - h + 3;
    [popUp setFrame:NSMakeRect(x, y, w, h) display:YES];
    
    NSTableView *table = (NSTableView *)[popUp firstResponder];
    [table selectRowIndexes:[NSIndexSet indexSetWithIndex:0] byExtendingSelection:NO];
    showingPopUp = YES;
    firstDownKeyStrokeHasHappened = NO;
}


#pragma mark -
#pragma mark NSTableViewDelegate

- (void)hidePopUp {
    NSWindow *popUp = [(HMImageComboBoxCell *)self.cell popUp];
    [popUp orderOut:nil];
    firstDownKeyStrokeHasHappened = NO;
    showingPopUp = NO;
}


- (void)keyUp:(NSEvent *)evt {
    if (![[self stringValue] length]) {
        [self hidePopUp];
        [super keyUp:evt];
        return;
    }
    
    NSWindow *popUp = [(HMImageComboBoxCell *)[self cell] popUp];
    NSInteger keyCode = [evt keyCode];
    
    if (ESC == keyCode) { // esc
        if (showingPopUp) {
            [self hidePopUp];
        } else {
            [super keyUp:evt];
        }
    } else if (DOWN_ARROW == keyCode || UP_ARROW == keyCode) { // down arrow || up arrow
        NSTableView *table = (NSTableView *)[popUp firstResponder];
        NSInteger i = [table selectedRow];
        if (DOWN_ARROW == keyCode && !firstDownKeyStrokeHasHappened) {
            firstDownKeyStrokeHasHappened = YES;
            [table selectRowIndexes:[NSIndexSet indexSetWithIndex:++i] byExtendingSelection:NO];
        }
        
        NSArray *matchingRecentURLs = [[FURecentURLController instance] matchingRecentURLs];
        if (i < [matchingRecentURLs count]) {
            NSString *URLString = [matchingRecentURLs objectAtIndex:i];
            [self setStringValue:URLString];
            NSRange r = [[self currentEditor] selectedRange];
            r.length = [URLString length] - r.location;
            [[self currentEditor] setSelectedRange:r];
        }        
    }
}

@synthesize progress;
@synthesize progressImage;
@end
