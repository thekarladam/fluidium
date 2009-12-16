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

#import "FUTabBarControl.h"
#import "FUDocumentController.h"
#import "FUWindowController.h"
#import "FUTabController.h"

@interface PSMTabBarControl ()
- (id)cellForPoint:(NSPoint)point cellFrame:(NSRectPointer)outFrame;
- (void)closeTabClick:(id)sender;
@end

@interface FUTabBarControl ()
- (void)handleRightClick:(NSEvent *)evt;
- (void)displayContextMenu:(NSTimer *)timer;
@end

@interface FUWindowController ()
- (void)tabControllerWasRemovedFromTabBar:(FUTabController *)tc;
- (void)tabControllerWasDroppedOnTabBar:(FUTabController *)tc;
@end

@implementation FUTabBarControl

- (void)dealloc {
    
    [super dealloc];
}


- (void)rightMouseDown:(NSEvent *)evt {
    [self handleRightClick:evt];
}


- (void)handleRightClick:(NSEvent *)evt {
    NSPoint mousePt = [self convertPoint:[evt locationInWindow] fromView:nil];
    NSRect cellFrame;
    PSMTabBarCell *cell = [super cellForPoint:mousePt cellFrame:&cellFrame];
    if (cell) {
        lastRightClickCellIndex = [_cells indexOfObject:cell];
        
        NSTimer *timer = [NSTimer timerWithTimeInterval:0 
                                                 target:self 
                                               selector:@selector(displayContextMenu:) 
                                               userInfo:evt 
                                                repeats:NO];
        [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    }
}


- (void)displayContextMenu:(NSTimer *)timer {
    NSEvent *evt = [timer userInfo];
    
    NSEvent *click = [NSEvent mouseEventWithType:[evt type] 
                                        location:[evt locationInWindow]
                                   modifierFlags:[evt modifierFlags] 
                                       timestamp:[evt timestamp] 
                                    windowNumber:[evt windowNumber] 
                                         context:[evt context]
                                     eventNumber:[evt eventNumber] 
                                      clickCount:[evt clickCount] 
                                        pressure:[evt pressure]]; 
    
    NSTabViewItem *tabViewItem = [tabView tabViewItemAtIndex:lastRightClickCellIndex];
    NSMenu *menu = [[[NSMenu alloc] initWithTitle:@""] autorelease];
    NSMenuItem *item = nil;
    item = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Close Tab", @"")
                                       action:@selector(closeTabClick:) 
                                keyEquivalent:@""] autorelease];
    [item setTarget:self];
    [item setRepresentedObject:tabViewItem];
    [menu addItem:item];    
    
    item = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Move Tab to New Window", @"")
                                       action:@selector(moveTabToNewWindow:) 
                                keyEquivalent:@""] autorelease];
    [item setTarget:self];
    [item setRepresentedObject:tabViewItem];
    [menu addItem:item];    
    
    FUWindowController *wc = [[FUDocumentController instance] frontWindowController];
    FUTabController *tc = [wc tabControllerAtIndex:lastRightClickCellIndex];
    
    if ([tc canReload]) {
        [menu addItem:[NSMenuItem separatorItem]];
        
        item = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Reload Tab", @"")
                                           action:@selector(reloadTab:) 
                                    keyEquivalent:@""] autorelease];
        [item setTarget:self];
        [item setRepresentedObject:tabViewItem];
        [menu addItem:item];
    }
    
    [NSMenu popUpContextMenu:menu withEvent:click forView:self];
    [timer invalidate];
}   


- (IBAction)reloadTab:(id)sender {
    FUWindowController *wc = [[FUDocumentController instance] frontWindowController];
    FUTabController *tc = [wc tabControllerAtIndex:lastRightClickCellIndex];
    [tc reload:sender];
}


- (IBAction)moveTabToNewWindow:(id)sender {
    FUWindowController *oldwc = (FUWindowController *)[[self window] windowController];
    FUTabController *tc = [oldwc tabControllerAtIndex:lastRightClickCellIndex];

    [[FUDocumentController instance] newDocument:sender];
    FUWindowController *newwc = [[FUDocumentController instance] frontWindowController];
    
    [oldwc tabControllerWasRemovedFromTabBar:tc];
    [newwc tabControllerWasDroppedOnTabBar:tc];
}

@end
