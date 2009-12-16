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

#import "FUPlugInWrapper.h"
#import "FUPlugIn.h"
#import "FUDocumentController.h"
#import "FUWindowController.h"
#import "FUTabController.h"

@interface FUPlugInWrapper ()
@property (nonatomic, retain, readwrite) id <FUPlugIn>plugIn;
@property (nonatomic, copy, readwrite) NSString *currentViewPlacementMaskKey;
@property (nonatomic, retain) NSMutableSet *visibleWindowNumbers;
@end

@implementation FUPlugInWrapper

- (id)initWithPlugIn:(id <FUPlugIn>)aPlugIn {
    self = [super init];
    if (self != nil) {
        self.plugIn = aPlugIn;
        self.viewControllers = [NSMutableDictionary dictionary];
        self.visibleWindowNumbers = [NSMutableSet set];
        self.currentViewPlacementMaskKey = [NSString stringWithFormat:@"%@-currentViewPlacement", self.identifier];
        
        id existingValue = [[NSUserDefaults standardUserDefaults] objectForKey:self.currentViewPlacementMaskKey];
        if (!existingValue) {
            self.currentViewPlacementMask = self.preferredViewPlacementMask;
        }
    }
    return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[NSNotificationCenter defaultCenter] removeObserver:plugIn];

    self.plugIn = nil;
    self.viewControllers = nil;
    self.visibleWindowNumbers = nil;
    self.currentViewPlacementMaskKey = nil;
    [super dealloc];
}


- (BOOL)isVisibleInWindowNumber:(NSInteger)num {
    NSString *key = [[NSNumber numberWithInteger:num] stringValue];
    return [visibleWindowNumbers containsObject:key];
}


- (void)setVisible:(BOOL)visible inWindowNumber:(NSInteger)num {
    NSString *key = [[NSNumber numberWithInteger:num] stringValue];
    if (visible) {
        [visibleWindowNumbers addObject:key];
    } else {
        [visibleWindowNumbers removeObject:key];
    }
}


- (NSViewController *)plugInViewControllerForWindowNumber:(NSInteger)num {
    NSString *key = [[NSNumber numberWithInteger:num] stringValue];
    NSViewController *viewController = [viewControllers objectForKey:key];
    if (!viewController) {
        viewController = [[self newViewControllerForWindowNumber:num] autorelease];
    }
    
    return viewController;
}


- (void)addObserver:(id)target for:(NSString *)name object:(id)obj ifRespondsTo:(SEL)sel {
    if ([target respondsToSelector:sel]) {
        [[NSNotificationCenter defaultCenter] addObserver:target selector:sel name:name object:obj];
    }
}


- (NSViewController *)newViewControllerForWindowNumber:(NSInteger)num {
    NSViewController *vc = [plugIn newPlugInViewController];
    [viewControllers setObject:vc forKey:[[NSNumber numberWithInteger:num] stringValue]];
    
    [self addObserver:plugIn for:FUPlugInViewControllerWillAppearNotifcation object:vc ifRespondsTo:@selector(plugInViewControllerWillAppear:)];
    [self addObserver:plugIn for:FUPlugInViewControllerDidAppearNotifcation object:vc ifRespondsTo:@selector(plugInViewControllerDidAppear:)];
    [self addObserver:plugIn for:FUPlugInViewControllerWillDisappearNotifcation object:vc ifRespondsTo:@selector(plugInViewControllerWillDisappear:)];
    [self addObserver:plugIn for:FUPlugInViewControllerDidDisappearNotifcation object:vc ifRespondsTo:@selector(plugInViewControllerDidDisappear:)];

    [self addObserver:plugIn for:FUWindowControllerDidOpenNotification object:nil ifRespondsTo:@selector(windowControllerDidOpen:)];

    if (num > -1) {
        FUWindowController *wc = [[FUDocumentController instance] frontWindowController];
        NSWindow *window = [wc window];

        [self addObserver:vc for:FUWindowControllerWillCloseNotification object:nil ifRespondsTo:@selector(windowControllerWillClose:)];

        [self addObserver:vc for:FUWindowControllerDidOpenTabNotification object:nil ifRespondsTo:@selector(windowControllerDidOpenTab:)];
        [self addObserver:vc for:FUWindowControllerWillCloseTabNotification object:nil ifRespondsTo:@selector(windowControllerWillCloseTab:)];
        [self addObserver:vc for:FUWindowControllerDidChangeSelectedTabNotification object:nil ifRespondsTo:@selector(windowControllerDidChangeSelectedTab:)];

        [self addObserver:vc for:FUTabControllerProgressDidStartNotification object:nil ifRespondsTo:@selector(tabControllerProgressDidStart:)];
        [self addObserver:vc for:FUTabControllerProgressDidChangeNotification object:nil ifRespondsTo:@selector(tabControllerProgressDidChange:)];
        [self addObserver:vc for:FUTabControllerProgressDidFinishNotification object:nil ifRespondsTo:@selector(tabControllerProgressDidFinish:)];

        [self addObserver:vc for:FUTabControllerDidCommitLoadNotification object:nil ifRespondsTo:@selector(tabControllerDidCommitLoad:)];
        [self addObserver:vc for:FUTabControllerDidFinishLoadNotification object:nil ifRespondsTo:@selector(tabControllerDidFinishLoad:)];
        [self addObserver:vc for:FUTabControllerDidFailLoadNotification object:nil ifRespondsTo:@selector(tabControllerDidFailLoad:)];
        [self addObserver:vc for:FUTabControllerDidClearWindowObjectNotification object:nil ifRespondsTo:@selector(tabControllerDidClearWindowObject:)];
        
        [self addObserver:vc for:NSWindowDidResizeNotification object:window ifRespondsTo:@selector(windowDidResize:)];
        [self addObserver:vc for:NSWindowDidExposeNotification object:window ifRespondsTo:@selector(windowDidExpose:)];
        [self addObserver:vc for:NSWindowWillMoveNotification object:window ifRespondsTo:@selector(windowWillMove:)];
        [self addObserver:vc for:NSWindowDidMoveNotification object:window ifRespondsTo:@selector(windowDidMove:)];
        [self addObserver:vc for:NSWindowDidBecomeKeyNotification object:window ifRespondsTo:@selector(windowDidBecomeKey:)];
        [self addObserver:vc for:NSWindowDidResignKeyNotification object:window ifRespondsTo:@selector(windowDidResignKey:)];
        [self addObserver:vc for:NSWindowDidBecomeMainNotification object:window ifRespondsTo:@selector(windowDidBecomeMain:)];
        [self addObserver:vc for:NSWindowDidResignMainNotification object:window ifRespondsTo:@selector(windowDidResignMain:)];
        [self addObserver:vc for:NSWindowWillCloseNotification object:window ifRespondsTo:@selector(windowWillClose:)];
        [self addObserver:vc for:NSWindowWillMiniaturizeNotification object:window ifRespondsTo:@selector(windowWillMiniaturize:)];
        [self addObserver:vc for:NSWindowDidMiniaturizeNotification object:window ifRespondsTo:@selector(windowDidMiniaturize:)];
        [self addObserver:vc for:NSWindowDidDeminiaturizeNotification object:window ifRespondsTo:@selector(windowDidDeminiaturize:)];
        [self addObserver:vc for:NSWindowDidUpdateNotification object:window ifRespondsTo:@selector(windowDidUpdate:)];
        [self addObserver:vc for:NSWindowDidChangeScreenNotification object:window ifRespondsTo:@selector(windowDidChangeScreen:)];
        [self addObserver:vc for:NSWindowDidChangeScreenProfileNotification object:window ifRespondsTo:@selector(windowDidChangeScreenProfile:)];
        [self addObserver:vc for:NSWindowWillBeginSheetNotification object:window ifRespondsTo:@selector(windowWillBeginSheet:)];
        [self addObserver:vc for:NSWindowDidEndSheetNotification object:window ifRespondsTo:@selector(windowDidEndSheet:)];
    }
    
    return vc;
}


- (void)windowWillClose:(NSNotification *)n {
    NSWindow *window = [n object];
    NSString *key = [[NSNumber numberWithInteger:[window windowNumber]] stringValue];
    [self setVisible:NO inWindowNumber:[window windowNumber]];
    
    NSViewController *vc = [viewControllers objectForKey:key];
    [viewControllers removeObjectForKey:key];
    [[NSNotificationCenter defaultCenter] removeObserver:vc];
}

#pragma mark -
#pragma mark accessors

- (NSInteger)currentViewPlacementMask {
    return [[NSUserDefaults standardUserDefaults] integerForKey:self.currentViewPlacementMaskKey];
}


- (void)setCurrentViewPlacementMask:(NSInteger)mask {
    [[NSUserDefaults standardUserDefaults] setInteger:mask forKey:self.currentViewPlacementMaskKey];
}


#pragma mark -
#pragma mark accessors

- (NSViewController *)preferencesViewController {
    return [plugIn preferencesViewController];
}


- (NSString *)identifier {
    return [plugIn identifier];
}


- (NSString *)localizedTitle {
    return [plugIn localizedTitle];
}


- (NSInteger)allowedViewPlacementMask {
    return [plugIn allowedViewPlacementMask];
}


- (NSInteger)preferredViewPlacementMask {
    return [plugIn preferredViewPlacementMask];
}


- (NSString *)preferredMenuItemKeyEquivalent {
    return [plugIn preferredMenuItemKeyEquivalent];
}


- (NSUInteger)preferredMenuItemKeyEquivalentModifierMask {
    return [plugIn preferredMenuItemKeyEquivalentModifierMask];
}


- (NSString *)toolbarIconImageName {
    return [plugIn toolbarIconImageName];
}


- (NSString *)preferencesIconImageName {
    return [plugIn preferencesIconImageName];
}


- (NSDictionary *)defaultsDictionary {
    return [plugIn defaultsDictionary];
}


- (NSDictionary *)aboutInfoDictionary {
    return [plugIn aboutInfoDictionary];
}


- (CGFloat)preferredHorizontalSplitPosition {
    if ([plugIn respondsToSelector:@selector(preferredHorizontalSplitPosition)]) {
        return [plugIn preferredHorizontalSplitPosition];
    } else {
        return 220.;
    }
}


- (CGFloat)preferredVerticalSplitPosition {
    if ([plugIn respondsToSelector:@selector(preferredVerticalSplitPosition)]) {
        return [plugIn preferredVerticalSplitPosition];
    } else {
        return 220.;
    }
}


- (NSInteger)preferredToolbarButtonType {
    if ([plugIn respondsToSelector:@selector(preferredToolbarButtonType)]) {
        return [plugIn preferredVerticalSplitPosition];
    } else {
        return 0;
    }
}


@synthesize plugIn;
@synthesize viewControllers;
@synthesize currentViewPlacementMaskKey;
@dynamic currentViewPlacementMask;
@synthesize visibleWindowNumbers;
@end
