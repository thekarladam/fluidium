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

#import "FUWindow.h"
#import "FUWindowController.h"
#import "FUUserDefaults.h"
#import "NSEvent+FUAdditions.h"

#define CLOSE_CURLY 30
#define OPEN_CURLY 33

NSString *const FUSpacesBehaviorDidChangeNotification = @"FUSpacesBehaviorDidChangeNotification";

@interface FUWindow ()
- (void)spacesBehaviorDidChange:(NSNotification *)n;
- (BOOL)FU_handleCloseSearchPanel:(NSEvent *)evt;
- (BOOL)FU_handleNextPrevTab:(NSEvent *)evt;
@end

@implementation FUWindow

- (id)initWithContentRect:(NSRect)rect styleMask:(NSUInteger)style backing:(NSBackingStoreType)type defer:(BOOL)flag {
    if (self = [super initWithContentRect:rect styleMask:style backing:type defer:flag]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(spacesBehaviorDidChange:) name:FUSpacesBehaviorDidChangeNotification object:nil];
        [self spacesBehaviorDidChange:nil];
    }
    return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}


- (NSString *)description {
    return [NSString stringWithFormat:@"<FUWindow %p %d>", self, [self windowNumber]];
}


// override with a noop. that supresses NSBeep for keyDown events not handled by webview
- (void)keyDown:(NSEvent *)evt {
}


- (void)sendEvent:(NSEvent *)evt {

    if ([evt FU_isKeyUpOrDown]) {
        // handle closing the search panel via <ESC> key
        if ([self FU_handleCloseSearchPanel:evt]) {
            return;
        }
                                                   
        // also handle ⌘-{ and ⌘-} tab switching
        else if ([self FU_handleNextPrevTab:evt]) {
            return;
        }
    }
    
    [super sendEvent:evt];
}


#pragma mark -
#pragma mark Actions

- (IBAction)performClose:(id)sender {
    [(FUWindowController *)[self windowController] performClose:sender];
}


- (IBAction)FU_forcePerformClose:(id)sender {
    [super performClose:sender];
}


#pragma mark -
#pragma mark Notifications

- (void)spacesBehaviorDidChange:(NSNotification *)n {
    NSInteger spacesBehavior = [[FUUserDefaults instance] spacesBehavior];

    NSUInteger flag = NSWindowCollectionBehaviorDefault;
    if (1 == spacesBehavior) {
        flag = NSWindowCollectionBehaviorCanJoinAllSpaces;
    } else if (2 == spacesBehavior) {
        flag = NSWindowCollectionBehaviorMoveToActiveSpace;
    }
    
    [self setCollectionBehavior:flag];
}


#pragma mark -
#pragma mark Private

- (BOOL)FU_handleCloseSearchPanel:(NSEvent *)evt {
    if ([evt FU_isEscKeyPressed]) {
        FUWindowController *wc = (FUWindowController *)[self windowController];
        if ([wc isFindPanelVisible]) {
            [wc hideFindPanel:self];
            return YES;
        }
    }
    return NO;
}


- (BOOL)FU_handleNextPrevTab:(NSEvent *)evt {
    if ([evt FU_isCommandKeyPressed]) {
        NSInteger keyCode = [evt keyCode];
        if (CLOSE_CURLY == keyCode || OPEN_CURLY == keyCode) {
            FUWindowController *wc = (FUWindowController *)[self windowController];
            if (CLOSE_CURLY == keyCode) {
                [wc selectNextTab:self];
            } else if (OPEN_CURLY == keyCode) {
                [wc selectPreviousTab:self];
            }
            return YES;
        }
    }
    return NO;
}

@end
