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

#import "FUPlugInController.h"
#import "FUPlugIn.h"
#import "FUPlugInWrapper.h"
#import "FUPlugInController.h"
#import "FUPlugInAPIImpl.h"
#import "FUWindowController.h"
#import "FUDocumentController.h"
#import "FUApplication.h"
#import "FUUserDefaults.h"
#import "FUPlugInPreferences.h"
#import "TDUberView.h"
#import "NSFileManager+FUAdditions.h"
#import <WebKit/WebKit.h>
#import <OmniAppKit/OmniAppKit.h>
#import <OmniAppKit/OAPreferenceController.h>
#import <OmniAppKit/OAPreferenceClient.h>

#define PLUGIN_MENU_INDEX 6
#define MIN_PREFS_VIEW_WIDTH 427
#define PREFS_VIEW_VERTICAL_FUDGE 47

NSString *const FUPlugInViewControllerWillAppearNotifcation = @"FUPlugInViewControllerWillAppearNotifcation";
NSString *const FUPlugInViewControllerDidAppearNotifcation = @"FUPlugInViewControllerDidAppearNotifcation";
NSString *const FUPlugInViewControllerWillDisappearNotifcation = @"FUPlugInViewControllerWillDisappearNotifcation";
NSString *const FUPlugInViewControllerDidDisappearNotifcation = @"FUPlugInViewControllerDidDisappearNotifcation";

NSString *const FUPlugInCurrentViewPlacementMaskKey = @"FUPlugInCurrentViewPlacementMaskKey";
NSString *const FUPlugInKey = @"FUPlugInKey";
NSString *const FUPlugInViewControllerKey = @"FUPlugInViewControllerKey";
NSString *const FUPlugInViewControllerDrawerKey = @"FUPlugInViewControllerDrawerKey";

@interface OAPreferenceController (FUShutUpCompiler)
+ (void)registerItemName:(NSString *)itemName bundle:(NSBundle *)bundle description:(NSDictionary *)description;
@end

@interface NSObject (FUAdditions) 
- (id)initWithPlugInAPI:(id <FUPlugInAPI>)api tag:(NSInteger)inTag;
@end

@interface FUPlugInController ()
- (void)windowControllerDidOpen:(NSNotification *)n;
- (void)showVisiblePlugInsInWindow:(NSWindow *)win;

- (void)loadPlugIn:(id <FUPlugIn>)plugIn;
- (void)loadPlugInAtPath:(NSString *)path;
- (void)loadPlugInsAtPath:(NSString *)path;
- (void)registerNotificationsOnPlugInWrapper:(FUPlugInWrapper *)wrap;
- (void)createMenuItemsForPlugInWrapper:(FUPlugInWrapper *)wrap;
- (void)createPrefPanesForPlugInWrappers;
- (void)createPrefPaneForPlugInWrapper:(FUPlugInWrapper *)wrap;
- (void)copyIconImageNamed:(NSString *)iconImageName forPlugInWrapper:(FUPlugInWrapper *)wrap;
- (void)toggleDrawerPlugInWrapper:(FUPlugInWrapper *)plugInWrapper inWindow:(NSWindow *)window;
- (void)toggleUtilityPanelPlugInWrapper:(FUPlugInWrapper *)wrap;
- (void)toggleFloatingUtilityPanelPlugInWrapper:(FUPlugInWrapper *)wrap;
- (void)toggleHUDPanelPlugInWrapper:(FUPlugInWrapper *)wrap;
- (void)toggleFloatingHUDPanelPlugInWrapper:(FUPlugInWrapper *)wrap;
- (void)togglePanelPluginWrapper:(FUPlugInWrapper *)plugInWrapper isFloating:(BOOL)isFloating isHUD:(BOOL)isHUD;
- (NSPanel *)newPanelWithContentView:(NSView *)contentView isHUD:(BOOL)isHUD;
- (void)toggleSplitViewTopPlugInWrapper:(FUPlugInWrapper *)plugInWrapper inWindow:(NSWindow *)window;
- (void)toggleSplitViewBottomPlugInWrapper:(FUPlugInWrapper *)plugInWrapper inWindow:(NSWindow *)window;
- (void)toggleSplitViewLeftPlugInWrapper:(FUPlugInWrapper *)plugInWrapper inWindow:(NSWindow *)window;
- (void)toggleSplitViewRightPlugInWrapper:(FUPlugInWrapper *)plugInWrapper inWindow:(NSWindow *)window;
- (void)toggleSplitViewPluginWrapper:(FUPlugInWrapper *)plugInWrapper isVertical:(BOOL)isVertical isFirst:(BOOL)isFirst inWindow:(NSWindow *)window;
- (void)postNotificationName:(NSString *)name forPlugInWrapper:(FUPlugInWrapper *)plugInWrapper viewController:(NSViewController *)vc;
- (void)postNotificationName:(NSString *)name forPlugInWrapper:(FUPlugInWrapper *)plugInWrapper viewController:(NSViewController *)vc userInfo:(NSMutableDictionary *)userInfo;
@end

@implementation FUPlugInController

+ (id)instance {
    static FUPlugInController *instance = nil;
    @synchronized (self) {
        if (!instance) {
            instance = [[FUPlugInController alloc] init];
        }
    }
    return instance;
}


- (id)init {    
    if (self = [super init]) {
        self.windowsForPlugInIdentifier = [NSMutableDictionary dictionary];
        self.plugInAPI = [[[FUPlugInAPIImpl alloc] init] autorelease];
        self.plugInWrappers = [NSMutableArray array];
        self.allPlugInIdentifiers = [NSMutableArray array];
        
        [self loadPlugIns];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowControllerDidOpen:) name:FUWindowControllerDidOpenNotification object:nil];
    }
    return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.plugInMenu = nil;
    self.windowsForPlugInIdentifier = nil;
    self.plugInAPI = nil;
    self.plugInWrappers = nil;
    self.allPlugInIdentifiers = nil;
    [super dealloc];
}


#pragma mark -
#pragma mark Notifications

- (void)windowControllerDidOpen:(NSNotification *)n {
    NSWindow *win = [[n object] window];
    
    if ([[FUUserDefaults instance] showVisiblePlugInsInNewWindows]) {
        // do it in the next run loop. avoids problem where NSWindows have a windowNumber of -1 until the next runloop
        [self performSelector:@selector(showVisiblePlugInsInWindow:) withObject:win afterDelay:0];
    }
}


- (void)showVisiblePlugInsInWindow:(NSWindow *)win {
    for (NSString *identifier in [[FUUserDefaults instance] visiblePlugInIdentifiers]) {
        [self showPlugInWrapper:[self plugInWrapperForIdentifier:identifier] inWindow:win];
    }
}


#pragma mark -

- (void)loadPlugIns {
    [self loadPlugInsAtPath:[[FUApplication instance] plugInPrivateDirPath]];
    [self loadPlugInsAtPath:[[FUApplication instance] plugInDirPath]];
    [self createPrefPanesForPlugInWrappers];
    [self createMenuItemsForPlugIns];
}


- (void)loadPlugInsAtPath:(NSString *)path {
    NSFileManager *mgr = [NSFileManager defaultManager];
    [mgr createDirectoryAtPath:path attributes:nil];
    
    NSMutableArray *filenames = [NSMutableArray array];    
    [filenames addObjectsFromArray:[mgr FU_directoryContentsAtPath:path havingExtension:@"fluidplugin" error:nil]];
    
    BOOL foundPlugIns = [filenames count];
    
    if (foundPlugIns) {
        for (NSString *filename in filenames) {
            path = [path stringByAppendingPathComponent:filename];
            @try {
                [self loadPlugInAtPath:path];
            } @catch (NSException *e) {
                NSLog(@"Fluidium couldn't load Plug-in at path: %@\n%@", path, [e reason]);
            }
        }
    }
}


- (void)loadPlugInAtPath:(NSString *)path {    
    NSBundle *bundle = [NSBundle bundleWithPath:path];

    id <FUPlugIn>plugIn = nil;

    if ([[bundle bundleIdentifier] hasPrefix:@"com.fluidapp.BrowsaPlugIn"]) {
        NSInteger count = [[FUUserDefaults instance] numberOfBrowsaPlugIns];
        NSInteger i = 0;
        for ( ; i < count; i++) {
            plugIn = [[[bundle principalClass] alloc] initWithPlugInAPI:plugInAPI tag:i];
            [self loadPlugIn:plugIn];
        }
    } else {
        plugIn = [[[[bundle principalClass] alloc] initWithPlugInAPI:plugInAPI] autorelease];
        [self loadPlugIn:plugIn];
    }
}


- (void)loadPlugIn:(id <FUPlugIn>)plugIn {
    NSString *identifier = [plugIn identifier];
    if ([allPlugInIdentifiers containsObject:identifier]) {
        NSLog(@"already loaded plugin with identifier: %@, ignoring", identifier);
        return;
    }
    
    [allPlugInIdentifiers addObject:identifier];
    
    FUPlugInWrapper *wrap = [[[FUPlugInWrapper alloc] initWithPlugIn:plugIn] autorelease];
    
    [plugInWrappers addObject:wrap];
    
    [self registerNotificationsOnPlugInWrapper:wrap];
}


- (void)createMenuItemsForPlugIns {
    plugInMenu = [[[NSApp mainMenu] itemAtIndex:PLUGIN_MENU_INDEX] submenu];
    
    for (FUPlugInWrapper *wrap in plugInWrappers) {
        [self createMenuItemsForPlugInWrapper:wrap];
    }
}


- (void)registerNotificationsOnPlugInWrapper:(FUPlugInWrapper *)wrap {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    SEL selector = nil;
    
    selector = @selector(plugInViewControllerWillAppear:);
    if ([wrap respondsToSelector:selector]) {
        [nc addObserver:wrap 
               selector:selector
                   name:FUPlugInViewControllerWillAppearNotifcation
                 object:wrap];
    }
    
    selector = @selector(plugInViewControllerDidAppear:);
    if ([wrap respondsToSelector:selector]) {
        [nc addObserver:wrap 
               selector:selector
                   name:FUPlugInViewControllerDidAppearNotifcation
                 object:wrap];
    }
    
    selector = @selector(plugInViewControllerWillDisappear:);
    if ([wrap respondsToSelector:selector]) {
        [nc addObserver:wrap 
               selector:selector
                   name:FUPlugInViewControllerWillDisappearNotifcation
                 object:wrap];
    }
    
    selector = @selector(plugInViewControllerDidDisappear:);
    if ([wrap respondsToSelector:selector]) {
        [nc addObserver:wrap 
               selector:selector
                   name:FUPlugInViewControllerDidDisappearNotifcation
                 object:wrap];    
    }
}


- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    if (@selector(plugInAboutMenuItemAction:) == [menuItem action]) {
        NSMenu *menu = [menuItem menu];
        NSInteger i = [[menu itemArray] indexOfObject:menuItem];
        FUPlugInWrapper *wrap = [plugInWrappers objectAtIndex:i];
        
        return (nil != wrap.aboutInfoDictionary);
    } else {
        return YES;
    }
}


- (void)createMenuItemsForPlugInWrapper:(FUPlugInWrapper *)wrap {
    static NSInteger tag = 0;
    
    NSString *title = [NSString stringWithFormat:NSLocalizedString(@"%@ Plug-in", @""), wrap.localizedTitle];
    
    NSMenuItem *aboutMenuItem = [[[NSMenuItem alloc] initWithTitle:title
                                                            action:@selector(plugInAboutMenuItemAction:)
                                                     keyEquivalent:@""] autorelease];
    [aboutMenuItem setTarget:self];
    [[[plugInMenu itemAtIndex:0] submenu] addItem:aboutMenuItem];
    
    NSMenuItem *menuItem = [[[NSMenuItem alloc] initWithTitle:title
                                                       action:@selector(plugInMenuItemAction:)
                                                keyEquivalent:wrap.preferredMenuItemKeyEquivalent] autorelease];
    [menuItem setKeyEquivalentModifierMask:wrap.preferredMenuItemKeyEquivalentModifierMask];
    [menuItem setTarget:self];
    [menuItem setTag:tag++];
    //[menuItem setImage:[NSImage imageNamed:[plugIn iconImageName]]];
    [plugInMenu addItem:menuItem];
}


- (void)createPrefPanesForPlugInWrappers {
    //[OAPreferenceController sharedPreferenceController];
    
    for (FUPlugInWrapper *wrap in plugInWrappers) {
        [self createPrefPaneForPlugInWrapper:wrap];
    }
    
    for (FUPlugInWrapper *wrap in plugInWrappers) {
        NSString *identifier = wrap.identifier;
        FUPlugInPreferences *client = (FUPlugInPreferences *)[[OAPreferenceController sharedPreferenceController] clientWithIdentifier:identifier];
        client.plugInWrapper = wrap;
        
        NSView *contentView = [client contentView];
        NSView *preferencesView = wrap.preferencesViewController.view;
        NSSize prefSize = [preferencesView bounds].size;
        
        if (prefSize.width < MIN_PREFS_VIEW_WIDTH) {
            prefSize.width = MIN_PREFS_VIEW_WIDTH;
        }
        NSView *controlBox = [client controlBox];
        NSSize boxSize = prefSize;
        boxSize.height += PREFS_VIEW_VERTICAL_FUDGE;
        [controlBox setFrameSize:boxSize];
        
        [contentView addSubview:preferencesView];
        
        [client updatePopUpMenu];
    }
}


- (void)createPrefPaneForPlugInWrapper:(FUPlugInWrapper *)wrap {
    NSString *identifier = wrap.identifier;
    NSString *title = wrap.localizedTitle;
    if ([title hasPrefix:@"BrowsaBrowsa"]) {
        title = @"Browsa";
    }
    
    [self copyIconImageNamed:wrap.toolbarIconImageName forPlugInWrapper:wrap];
    [self copyIconImageNamed:wrap.preferencesIconImageName forPlugInWrapper:wrap];
    
    NSString *path = [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"PlugInClientRecord"] stringByAppendingPathExtension:@"plist"];
    
    NSMutableDictionary *description = [NSMutableDictionary dictionary];
    [description addEntriesFromDictionary:[NSDictionary dictionaryWithContentsOfFile:path]];
    [description setObject:wrap.preferencesIconImageName forKey:@"icon"];
    [description setObject:identifier forKey:@"identifier"];
    [description setObject:title forKey:@"shortTitle"];
    [description setObject:[NSString stringWithFormat:NSLocalizedString(@"%@ Plug-in", @""), title] forKey:@"title"];

    // hardcode ordering for mulitple BrowsaBrowsa plugins. ensures they show up in prefpane in order we want. otherwise the get jumbled. :0[
    if ([identifier hasPrefix:@"com.fluidapp.BrowsaBrowsaPlugIn"]) {
        NSInteger ordering = 0;
        if ([identifier isEqualToString:@"com.fluidapp.BrowsaBrowsaPlugIn0"]) {
            ordering = 200;
        } else if ([identifier isEqualToString:@"com.fluidapp.BrowsaBrowsaPlugIn1"]) {
            ordering = 210;
        } else if ([identifier isEqualToString:@"com.fluidapp.BrowsaBrowsaPlugIn2"]) {
            ordering = 220;
        } else if ([identifier isEqualToString:@"com.fluidapp.BrowsaBrowsaPlugIn3"]) {
            ordering = 230;
        } else if ([identifier isEqualToString:@"com.fluidapp.BrowsaBrowsaPlugIn4"]) {
            ordering = 240;
        }
        [description setObject:[NSNumber numberWithInteger:ordering] forKey:@"ordering"];
    }

    
    NSDictionary *defaultsDictionary = [NSDictionary dictionaryWithDictionary:wrap.defaultsDictionary];
    [description setObject:defaultsDictionary forKey:@"defaultsDictionary"];
    
    [OAPreferenceController registerItemName:@"FUPlugInPreferences" bundle:[NSBundle mainBundle] description:[[description copy] autorelease]];
}


- (void)copyIconImageNamed:(NSString *)iconImageName forPlugInWrapper:(FUPlugInWrapper *)wrap {
    NSString *imageStartPath = [[NSBundle bundleForClass:[wrap.plugIn class]] pathForResource:iconImageName ofType:@"png"];
    NSString *imageEndPath = [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:iconImageName] stringByAppendingPathExtension:@"png"];
    
    NSFileManager *mgr = [NSFileManager defaultManager];
    BOOL exists = [mgr fileExistsAtPath:imageEndPath];
    
    if (!exists) {        
        [mgr copyItemAtPath:imageStartPath toPath:imageEndPath error:nil];
        // on first run, this generic app icon will have to do. on second run, icon will appear
        //iconImageName = @"NSApplicationIcon";
    }
}


- (FUPlugInWrapper *)plugInWrapperForIdentifier:(NSString *)identifier {
    for (FUPlugInWrapper *wrap in plugInWrappers) {
        if ([wrap.identifier isEqualToString:identifier]) {
            return wrap;
        }
    }
    return nil;
}


- (void)plugInMenuItemAction:(id)sender {
    BOOL isToolbarItem = [sender isKindOfClass:[NSToolbarItem class]];
    
    FUPlugInWrapper *wrap = nil;
    if (isToolbarItem) {
        wrap = [self plugInWrapperForIdentifier:[sender itemIdentifier]];
    } else {
        wrap = [plugInWrappers objectAtIndex:[sender tag]];
    }
    
    FUPlugInViewPlacementMask mask = wrap.currentViewPlacementMask;
    
    NSWindow *window = nil;
    if (!FUPlugInViewPlacementIsPanel(mask)) {
        window = [[[FUDocumentController instance] frontWindowController] window];
    }

    for (FUPlugInWrapper *visibleWrap in [self visiblePlugInWrappers]) {
        if (visibleWrap != wrap && visibleWrap.currentViewPlacementMask == mask) {
            if ([visibleWrap isVisibleInWindowNumber:[window windowNumber]]) {
                [self toggleVisibilityOfPlugInWrapper:visibleWrap inWindow:window];
            }
        }
    }
    //[self hidePlugInWrapperWithViewPlacementMask:plugInWrapper.currentViewPlacementMask inWindow:window];
    [self toggleVisibilityOfPlugInWrapper:wrap inWindow:window];
}


- (void)plugInAboutMenuItemAction:(id)sender {
    NSMenu *menu = [sender menu];
    NSInteger i = [menu indexOfItem:sender];
    FUPlugInWrapper *wrap = [plugInWrappers objectAtIndex:i];
    [NSApp orderFrontStandardAboutPanelWithOptions:wrap.aboutInfoDictionary];
}


- (void)toggleVisibilityOfPlugInWrapper:(FUPlugInWrapper *)wrap {
    NSUInteger mask = wrap.currentViewPlacementMask;
    if (FUPlugInViewPlacementIsPanel(mask)) {
        [self toggleVisibilityOfPlugInWrapper:wrap inWindow:nil];
    } else {
        NSArray *docs = [[FUDocumentController instance] documents];
        for (FUDocument *doc in docs) {
            [self toggleVisibilityOfPlugInWrapper:wrap inWindow:[[doc windowController] window]];
        }
    }
}


- (void)hidePlugInWrapperInAllWindows:(FUPlugInWrapper *)wrap {
    NSUInteger mask = wrap.currentViewPlacementMask;
    if (FUPlugInViewPlacementIsPanel(mask)) {
        if ([wrap isVisibleInWindowNumber:-1]) {
            [self toggleVisibilityOfPlugInWrapper:wrap inWindow:nil];
        }
    } else {
        NSArray *docs = [[FUDocumentController instance] documents];
        for (FUDocument *doc in docs) {
            NSWindow *win = [[doc windowController] window];
            if ([wrap isVisibleInWindowNumber:[win windowNumber]]) {
                [self toggleVisibilityOfPlugInWrapper:wrap inWindow:win];
            }
        }
    }
}


- (void)showPlugInWrapper:(FUPlugInWrapper *)wrap inWindow:(NSWindow *)win {
    NSUInteger mask = wrap.currentViewPlacementMask;
    if (FUPlugInViewPlacementIsPanel(mask)) {
        if (![wrap isVisibleInWindowNumber:-1]) {
            [self toggleVisibilityOfPlugInWrapper:wrap inWindow:nil];
        }
    } else {
        [self hidePlugInWrapperWithViewPlacementMask:wrap.currentViewPlacementMask inWindow:win];

        if (![wrap isVisibleInWindowNumber:[win windowNumber]]) {
            [self toggleVisibilityOfPlugInWrapper:wrap inWindow:win];
        }
    }
}


- (NSArray *)visiblePlugInWrappers {
    NSArray *ids = [[FUUserDefaults instance] visiblePlugInIdentifiers];
    
    NSMutableArray *result = nil;

    if ([ids count]) {
        result = [NSMutableArray arrayWithCapacity:[ids count]];
        
        NSSet *visiblePlugIns = [NSSet setWithArray:ids];
        FUPlugInController *mgr = [FUPlugInController instance];
        if (visiblePlugIns.count) {
            for (NSString *identifier in visiblePlugIns) {
                FUPlugInWrapper *wrap = [mgr plugInWrapperForIdentifier:identifier];
                if (wrap) { // if a plugin has been removed, this could be nil causing crash
                    [result addObject:wrap];
                }
            }
        }    
    }
    
    return result;
}


- (void)hidePlugInWrapperWithViewPlacementMask:(FUPlugInViewPlacementMask)mask inWindow:(NSWindow *)win {
    for (FUPlugInWrapper *wrap in [self visiblePlugInWrappers]) {
        if (mask == wrap.currentViewPlacementMask) {
            if ([wrap isVisibleInWindowNumber:[win windowNumber]]) {
                [self toggleVisibilityOfPlugInWrapper:wrap inWindow:win];
            }
        }
    }
}


- (void)toggleVisibilityOfPlugInWrapper:(FUPlugInWrapper *)wrap inWindow:(NSWindow *)win {
    NSInteger mask = wrap.currentViewPlacementMask;
    BOOL isPanelMask = FUPlugInViewPlacementIsPanel(mask);

    if (!isPanelMask && !win) {
        NSBeep();
        return;
    }
    
    switch (mask) {
        case FUPlugInViewPlacementUtilityPanelMask:
            [self toggleUtilityPanelPlugInWrapper:wrap];
            break;
        case FUPlugInViewPlacementFloatingUtilityPanelMask:
            [self toggleFloatingUtilityPanelPlugInWrapper:wrap];
            break;
        case FUPlugInViewPlacementHUDPanelMask:
            [self toggleHUDPanelPlugInWrapper:wrap];
            break;
        case FUPlugInViewPlacementFloatingHUDPanelMask:
            [self toggleFloatingHUDPanelPlugInWrapper:wrap];
            break;
        case FUPlugInViewPlacementSplitViewBottomMask:
            [self toggleSplitViewBottomPlugInWrapper:wrap inWindow:win];
            break;
        case FUPlugInViewPlacementSplitViewLeftMask:
            [self toggleSplitViewLeftPlugInWrapper:wrap inWindow:win];
            break;
        case FUPlugInViewPlacementSplitViewRightMask:
            [self toggleSplitViewRightPlugInWrapper:wrap inWindow:win];
            break;
        case FUPlugInViewPlacementSplitViewTopMask:
            [self toggleSplitViewTopPlugInWrapper:wrap inWindow:win];
            break;
        default:
            //case FUPlugInViewPlacementDrawerMask:
            [self toggleDrawerPlugInWrapper:wrap inWindow:win];
            break;
    }
}


- (NSSize)drawerWillResizeContents:(NSDrawer *)sender toSize:(NSSize)contentSize {
    [[FUUserDefaults instance] setPlugInDrawerContentSizeString:NSStringFromSize(contentSize)];
    [[NSUserDefaults standardUserDefaults] synchronize];
    return contentSize;
}


- (void)toggleDrawerPlugInWrapper:(FUPlugInWrapper *)wrap inWindow:(NSWindow *)win {    
    NSViewController *vc = [wrap plugInViewControllerForWindowNumber:[win windowNumber]];
    
    NSDrawer *drawer = [[win drawers] objectAtIndex:0];
    if (!drawer) return;
    
    if (![drawer delegate]) {
        [drawer setDelegate:self];        
    }

    if (NSDrawerOpeningState == [drawer state] || NSDrawerClosingState == [drawer state]) {
        NSBeep();
        return;
    }
    
    [[NSNotificationCenter defaultCenter] addObserver:wrap
                                             selector:@selector(windowWillClose:)
                                                 name:NSWindowWillCloseNotification
                                               object:win];
    
    
    NSString *identifier = [wrap identifier];
    NSMutableSet *visiblePlugIns = [NSMutableSet setWithArray:[[FUUserDefaults instance] visiblePlugInIdentifiers]];

    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    [userInfo setObject:drawer forKey:FUPlugInViewControllerDrawerKey];
    
    if (NSDrawerOpenState == [drawer state]) {
        //[viewController.view removeFromSuperview];
        [[drawer contentView] setNeedsDisplay:YES];

        [self postNotificationName:FUPlugInViewControllerWillDisappearNotifcation
                  forPlugInWrapper:wrap
                    viewController:vc
                          userInfo:userInfo];
        [drawer close:self];
        [wrap setVisible:NO inWindowNumber:[win windowNumber]];
        [self postNotificationName:FUPlugInViewControllerDidDisappearNotifcation
                  forPlugInWrapper:wrap
                    viewController:vc
                          userInfo:userInfo];
        [visiblePlugIns removeObject:identifier];
    } else {
        NSString *contentSizeString = [[FUUserDefaults instance] plugInDrawerContentSizeString];
        if ([contentSizeString length]) {
            [drawer setContentSize:NSSizeFromString(contentSizeString)];
        }
        [[drawer contentView] addSubview:vc.view];
        [vc.view setFrameSize:[drawer contentSize]];
        [[drawer contentView] setNeedsDisplay:YES];
        
        [self postNotificationName:FUPlugInViewControllerWillAppearNotifcation
                  forPlugInWrapper:wrap
                    viewController:vc
                          userInfo:userInfo];
        [drawer open:self];
        [wrap setVisible:YES inWindowNumber:[win windowNumber]];
        [self postNotificationName:FUPlugInViewControllerDidAppearNotifcation
                  forPlugInWrapper:wrap
                    viewController:vc
                          userInfo:userInfo];
        [visiblePlugIns addObject:identifier];
    }

    [[FUUserDefaults instance] setVisiblePlugInIdentifiers:[visiblePlugIns allObjects]];
}


- (void)toggleUtilityPanelPlugInWrapper:(FUPlugInWrapper *)wrap {
    [self togglePanelPluginWrapper:wrap isFloating:NO isHUD:NO];
}


- (void)toggleFloatingUtilityPanelPlugInWrapper:(FUPlugInWrapper *)wrap {
    [self togglePanelPluginWrapper:wrap isFloating:YES isHUD:NO];
}


- (void)toggleHUDPanelPlugInWrapper:(FUPlugInWrapper *)wrap {
    [self togglePanelPluginWrapper:wrap isFloating:NO isHUD:YES];    
}


- (void)toggleFloatingHUDPanelPlugInWrapper:(FUPlugInWrapper *)wrap {
    [self togglePanelPluginWrapper:wrap isFloating:YES isHUD:YES];    
}


- (void)togglePanelPluginWrapper:(FUPlugInWrapper *)wrap isFloating:(BOOL)isFloating isHUD:(BOOL)isHUD {
    NSString *identifier = wrap.identifier;
    NSViewController *vc = [wrap plugInViewControllerForWindowNumber:-1];
    NSView *plugInView = vc.view;

    NSPanel *panel = [windowsForPlugInIdentifier objectForKey:identifier];
    
    if (!panel) {
        panel = [self newPanelWithContentView:plugInView isHUD:isHUD];
        [panel setFloatingPanel:isFloating];
        [panel setReleasedWhenClosed:YES];
        
        [windowsForPlugInIdentifier setObject:panel forKey:wrap.identifier];
    }
    
    BOOL visible = [wrap isVisibleInWindowNumber:-1];
    
    if (visible) {
        [self postNotificationName:FUPlugInViewControllerWillDisappearNotifcation 
                  forPlugInWrapper:wrap
                    viewController:vc];
        
        [wrap setVisible:NO inWindowNumber:-1];
        [panel close];

        [self postNotificationName:FUPlugInViewControllerDidDisappearNotifcation 
                  forPlugInWrapper:wrap
                    viewController:vc];
    } else {

        [self postNotificationName:FUPlugInViewControllerWillAppearNotifcation
                  forPlugInWrapper:wrap
                    viewController:vc];
        
        [wrap setVisible:YES inWindowNumber:-1];
        [panel setIsVisible:YES];
        [panel makeKeyAndOrderFront:self];
        
        [self postNotificationName:FUPlugInViewControllerDidAppearNotifcation
                  forPlugInWrapper:wrap
                    viewController:vc];
        
    }
}


- (void)windowWillClose:(NSNotification *)n {
    NSWindow *window = [n object];
    if (![window isKindOfClass:[NSPanel class]]) {
        return;
    }
    
//    NSPanel *panel = (NSPanel *)window;
//    NSInteger windowNumber = [panel windowNumber];
    
    for (FUPlugInWrapper *wrap in plugInWrappers) {
        NSViewController *vc = [wrap plugInViewControllerForWindowNumber:-1];
        if (vc) {
            if (![wrap isVisibleInWindowNumber:-1]) {
                continue;
            }
            [self toggleVisibilityOfPlugInWrapper:wrap];
            return;
        }
    }
}


- (NSPanel *)newPanelWithContentView:(NSView *)contentView isHUD:(BOOL)isHUD {
    NSRect contentRect = NSMakeRect(0, 0, 200, 300);
    NSInteger mask = (NSUtilityWindowMask|NSTitledWindowMask|NSClosableWindowMask|NSMiniaturizableWindowMask|NSResizableWindowMask);
    if (isHUD) {
        mask = (mask|NSHUDWindowMask);
    }
    NSPanel *panel = [[NSPanel alloc] initWithContentRect:contentRect
                                                styleMask:mask
                                                  backing:NSBackingStoreBuffered
                                                    defer:YES];
    [panel setHasShadow:YES];
    [panel setReleasedWhenClosed:NO];
    [panel setHidesOnDeactivate:YES];
    [contentView setFrame:contentRect];
    [panel setContentView:contentView];
    [panel setBecomesKeyOnlyIfNeeded:YES];
    [panel setDelegate:self];
    
    FUWindowController *wc = [[FUDocumentController instance] frontWindowController];
    if (wc) {
        NSWindow *window = [wc window];
        NSRect frame = [window frame];
        NSPoint p = NSMakePoint(frame.origin.x + frame.size.width - 30,
                                frame.origin.y + frame.size.height - (40 + contentRect.size.height));
        [panel setFrameOrigin:p];
    } else {
        [panel center];
    }
    return panel;
}


- (void)toggleSplitViewTopPlugInWrapper:(FUPlugInWrapper *)wrap inWindow:(NSWindow *)win {
    [self toggleSplitViewPluginWrapper:wrap isVertical:NO isFirst:YES inWindow:win];
}


- (void)toggleSplitViewBottomPlugInWrapper:(FUPlugInWrapper *)wrap inWindow:(NSWindow *)win {
    [self toggleSplitViewPluginWrapper:wrap isVertical:NO isFirst:NO inWindow:win];
}


- (void)toggleSplitViewLeftPlugInWrapper:(FUPlugInWrapper *)wrap inWindow:(NSWindow *)win {
    [self toggleSplitViewPluginWrapper:wrap isVertical:YES isFirst:YES inWindow:win];
}


- (void)toggleSplitViewRightPlugInWrapper:(FUPlugInWrapper *)wrap inWindow:(NSWindow *)win {
    [self toggleSplitViewPluginWrapper:wrap isVertical:YES isFirst:NO inWindow:win];
}


- (void)toggleSplitViewPluginWrapper:(FUPlugInWrapper *)wrap isVertical:(BOOL)isVertical isFirst:(BOOL)isFirst inWindow:(NSWindow *)win {
    FUWindowController *wc = (FUWindowController *)[win windowController];
    
    NSViewController *vc = [wrap plugInViewControllerForWindowNumber:[win windowNumber]];
    NSView *plugInView = vc.view;
    
    [[NSNotificationCenter defaultCenter] addObserver:wrap
                                             selector:@selector(windowWillClose:)
                                                 name:NSWindowWillCloseNotification
                                               object:win];
    
    TDUberView *uberView = wc.uberView;
    
    NSString *identifier = wrap.identifier;
    NSMutableSet *visiblePlugIns = [NSMutableSet setWithArray:[[FUUserDefaults instance] visiblePlugInIdentifiers]];
    
    BOOL isLeft   = (isVertical && isFirst);
    BOOL isRight  = (isVertical && !isFirst);
    BOOL isTop    = (!isVertical && isFirst);
    BOOL isBottom = (!isVertical && !isFirst);
    
    BOOL isAppearing = NO;
    if      (isLeft)   isAppearing = !uberView.isLeftViewOpen;
    else if (isRight)  isAppearing = !uberView.isRightViewOpen;
    else if (isTop)    isAppearing = !uberView.isTopViewOpen;
    else if (isBottom) isAppearing = !uberView.isBottomViewOpen;
    
    NSString *name = isAppearing ? FUPlugInViewControllerWillAppearNotifcation : FUPlugInViewControllerWillDisappearNotifcation;
    [self postNotificationName:name forPlugInWrapper:wrap viewController:vc];
    [wrap setVisible:isAppearing inWindowNumber:[win windowNumber]];
    
    if (isLeft)    {
        uberView.preferredLeftSplitWidth = wrap.preferredVerticalSplitPosition;
        uberView.leftView = isAppearing ? plugInView : nil;
        [uberView toggleLeftView:self];
    } else if (isRight) {
        uberView.preferredRightSplitWidth = wrap.preferredVerticalSplitPosition;
        uberView.rightView = isAppearing ? plugInView : nil;
        [uberView toggleRightView:self];
    } else if (isTop) {
        uberView.preferredTopSplitHeight = wrap.preferredHorizontalSplitPosition;
        uberView.topView = isAppearing ? plugInView : nil;
        [uberView toggleTopView:self];
    } else if (isBottom) {
        uberView.preferredBottomSplitHeight = wrap.preferredHorizontalSplitPosition;
        uberView.bottomView = isAppearing ? plugInView : nil;
        [uberView toggleBottomView:self];
    }

    name = isAppearing ? FUPlugInViewControllerDidAppearNotifcation : FUPlugInViewControllerDidDisappearNotifcation;
    [self postNotificationName:name forPlugInWrapper:wrap viewController:vc];
    
    if (isAppearing) {
        [visiblePlugIns addObject:identifier];
    } else {
        [visiblePlugIns removeObject:identifier];
    }

    [[FUUserDefaults instance] setVisiblePlugInIdentifiers:[visiblePlugIns allObjects]];
}


- (void)postNotificationName:(NSString *)name forPlugInWrapper:(FUPlugInWrapper *)wrap viewController:(NSViewController *)vc {
    NSMutableDictionary *userInfo = [NSMutableDictionary dictionary];
    [self postNotificationName:name forPlugInWrapper:wrap viewController:vc userInfo:userInfo];
}


- (void)postNotificationName:(NSString *)name forPlugInWrapper:(FUPlugInWrapper *)wrap viewController:(NSViewController *)vc userInfo:(NSMutableDictionary *)userInfo {
    [userInfo setObject:wrap.plugIn forKey:FUPlugInKey];
    [userInfo setObject:vc forKey:FUPlugInViewControllerKey];
    [userInfo setObject:[NSNumber numberWithInteger:wrap.currentViewPlacementMask] forKey:FUPlugInCurrentViewPlacementMaskKey];

    [[NSNotificationCenter defaultCenter] postNotificationName:name object:vc userInfo:[[userInfo copy] autorelease]];
}

@synthesize plugInMenu;
@synthesize windowsForPlugInIdentifier;
@synthesize plugInAPI;
@synthesize plugInWrappers;
@synthesize allPlugInIdentifiers;
@end
