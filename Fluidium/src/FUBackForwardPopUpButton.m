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

#import "FUBackForwardPopUpButton.h"
#import "FUDocumentController.h"
#import "FUWindowController.h"
#import "NSArray+FUAdditions.h"
#import "WebKitPrivate.h"
#import "WebIconDatabase+FUAdditions.h"

#define BACK_FWD_ITEM_LIMIT 16
#define MENU_FUDGE_Y 3

@interface FUBackForwardPopUpButton ()
- (void)killTimer;
- (NSMenu *)menu;

@property (nonatomic, retain) NSTimer *timer;
@end

@implementation FUBackForwardPopUpButton

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self killTimer];
    [super dealloc];
}


- (void)killTimer {
    if (timer) {
        [self.timer invalidate];
        self.timer = nil;
    }
}


- (void)mouseDown:(NSEvent *)evt {
    didShowMenu = NO;
    if ([self isEnabled]) {
        self.timer = [NSTimer scheduledTimerWithTimeInterval:.3 target:self selector:@selector(showMenu:) userInfo:nil repeats:NO];
        [self highlight:YES];
    }
}


- (void)mouseUp:(NSEvent *)evt {
    [self killTimer];
    
    if (!didShowMenu) {
        [super mouseDown:evt];
        [super mouseUp:evt];
    } else {
        [self highlight:NO];
    }
}


- (void)menuDidEndTracking:(NSNotification *)n {
    [self highlight:NO];

    [[NSNotificationCenter defaultCenter] removeObserver:self name:NSMenuDidEndTrackingNotification object:[n object]];    
}


- (IBAction)showMenu:(id)sender {
    didShowMenu = YES;
    NSMenu *menu = [self menu];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(menuDidEndTracking:) name:NSMenuDidEndTrackingNotification object:menu];
    
    NSPoint point = NSZeroPoint;
    if ([self isFlipped]) {
        point.y = NSHeight([self frame]) + MENU_FUDGE_Y;
    } else {
        point.y = - MENU_FUDGE_Y;
    }
    point = [self convertPoint:point toView:nil];
    
    NSEvent *evt = [NSEvent mouseEventWithType:NSLeftMouseDown
                                      location:point
                                 modifierFlags:0
                                     timestamp:0
                                  windowNumber:[[self window] windowNumber]
                                       context:[NSGraphicsContext currentContext]
                                   eventNumber:0
                                    clickCount:1
                                      pressure:1];
    
    [NSMenu popUpContextMenu:menu withEvent:evt forView:self];
}


- (NSMenu *)menu {
    WebBackForwardList *list = [[[FUDocumentController instance] frontWebView] backForwardList];
    
    NSArray *historyItems = nil;
    
    BOOL isBackButton = (@selector(goBack:) == [self action]);
    if (isBackButton) {
        historyItems = [[list backListWithLimit:BACK_FWD_ITEM_LIMIT] FU_reversedArray];
    } else {
        historyItems = [list forwardListWithLimit:BACK_FWD_ITEM_LIMIT];
    }
    
    NSMenu *menu = [[[NSMenu alloc] initWithTitle:@""] autorelease];

    for (WebHistoryItem *historyItem in historyItems) {
        NSImage *icon = [[WebIconDatabase sharedIconDatabase] FU_faviconForURL:[historyItem URLString]];

        NSMenuItem *menuItem = [[[NSMenuItem alloc] initWithTitle:[historyItem title]
                                                           action:@selector(menuItemClick:)
                                                    keyEquivalent:@""] autorelease];
        [menuItem setTarget:self];
        [menuItem setImage:icon];
        [menuItem setRepresentedObject:historyItem];
        [menu addItem:menuItem];
    }
    
    return menu;
}


- (void)menuItemClick:(id)sender {
    WebView *webView = [[FUDocumentController instance] frontWebView];
    [webView goToBackForwardItem:[sender representedObject]];
}


@synthesize timer;
@end

