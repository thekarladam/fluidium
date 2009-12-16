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

#import "FUDocumentController.h"
#import "FUDocument.h"
#import "FUWindowController.h"
#import "FUTabController.h"
#import "FUUserDefaults.h"
#import "FUWebView.h"
#import <WebKit/WebKit.h>

#define OPEN_NEW_TAB 0

NSString *const FUTabBarShownDidChangeNotification = @"FUTabBarShownDidChangeNotification";
NSString *const FUTabBarHiddenForSingleTabDidChangeNotification = @"FUTabBarHiddenForSingleTabDidChangeNotification";
NSString *const FUBookmarkBarShownDidChangeNotification = @"FUBookmarkBarShownDidChangeNotification";
NSString *const FUStatusBarShownDidChangeNotification = @"FUStatusBarShownDidChangeNotification";

@interface FUDocumentController ()
- (void)registerForAppleEventHandling;
- (void)unregisterForAppleEventHandling;
- (void)handleInternetOpenContentsEvent:(NSAppleEventDescriptor *)event replyEvent:(NSAppleEventDescriptor *)replyEvent;
- (void)handleOpenContentsAppleEventWithURL:(NSString *)URLString;

- (void)saveSession;
- (void)restoreSession;
@end

@implementation FUDocumentController

+ (id)instance {
    return [[NSApplication sharedApplication] delegate];
}


- (void)dealloc {
    self.hiddenWindow = nil;
    [super dealloc];
}


- (NSString *)defaultType {
    return @"HTML document";
}


#pragma mark -
#pragma mark Action

- (IBAction)toggleTabBarShown:(id)sender {
    BOOL hidden = ![[FUUserDefaults instance] tabBarHiddenAlways];
    [[FUUserDefaults instance] setTabBarHiddenAlways:hidden];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:FUTabBarShownDidChangeNotification object:nil];
}


- (IBAction)toggleBookmarkBarShown:(id)sender {
    BOOL shown = ![[FUUserDefaults instance] bookmarkBarShown];
    [[FUUserDefaults instance] setBookmarkBarShown:shown];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:FUBookmarkBarShownDidChangeNotification object:nil];
}


- (IBAction)toggleStatusBarShown:(id)sender {
    BOOL shown = ![[FUUserDefaults instance] statusBarShown];
    [[FUUserDefaults instance] setStatusBarShown:shown];
    
    [[NSNotificationCenter defaultCenter] postNotificationName:FUStatusBarShownDidChangeNotification object:nil];
}


// support for opening a new window on <cmd>-T when there are no existing windows
- (IBAction)addNewTabInForeground:(id)sender {
    [self newDocument:sender];
}


#pragma mark -
#pragma mark NSApplicationDelegate

- (void)applicationDidFinishLaunching:(NSNotification *)n {
    [self registerForAppleEventHandling];
    [self restoreSession];
}


- (void)applicationWillTerminate:(NSNotification *)n {
    // is this necessary?
    [self unregisterForAppleEventHandling];
    [self saveSession];
}


- (void)applicationDidBecomeActive:(NSNotification *)n {
    if (hiddenWindow) {
        [hiddenWindow makeKeyAndOrderFront:self];
    }
}


#pragma mark -
#pragma mark NSMenuDelegate

- (BOOL)validateMenuItem:(NSMenuItem *)item {
    SEL action = [item action];
    
    if (@selector(toggleTabBarShown:) == action) {
        BOOL hideAlways = [[FUUserDefaults instance] tabBarHiddenAlways];
        [item setTitle:hideAlways ? NSLocalizedString(@"Show Tab Bar", @"") : NSLocalizedString(@"Hide Tab Bar", @"")];
        
        BOOL tabbedBrowsingEnabled = [[FUUserDefaults instance] tabbedBrowsingEnabled];
        if (!tabbedBrowsingEnabled) {
            return NO;
        }
        
        BOOL onlyOneTab = (1 == [[[self frontWindowController] tabControllers] count]);
        if (!onlyOneTab) {
            return tabbedBrowsingEnabled;
        }
        
        BOOL hideForSingleTab = [[FUUserDefaults instance] tabBarHiddenForSingleTab];
        return !hideForSingleTab;

    } else if (@selector(toggleBookmarkBarShown:) == action) {
        BOOL shown = [[FUUserDefaults instance] bookmarkBarShown];
        [item setTitle:shown ? NSLocalizedString(@"Hide Bookmark Bar", @"") : NSLocalizedString(@"Show Bookmark Bar", @"")];
        return YES;
        
    } else if (@selector(toggleStatusBarShown:) == action) {
        BOOL shown = [[FUUserDefaults instance] statusBarShown];
        [item setTitle:shown ? NSLocalizedString(@"Hide Status Bar", @"") : NSLocalizedString(@"Show Status Bar", @"")];
        return YES;
    } else {
        return YES;
    }
}


#pragma mark -
#pragma mark Public

- (FUDocument *)openDocumentWithRequest:(NSURLRequest *)req makeKey:(BOOL)makeKey {
    FUDocument *oldDoc = [self frontDocument];
    FUDocument *newDoc = [self openUntitledDocumentAndDisplay:makeKey error:nil];
    
    if (!makeKey) {
        [newDoc makeWindowControllers];
    }
    
    if (!makeKey) {
        NSWindow *oldWin = [[oldDoc windowController] window];
        NSWindow *newWin = [[newDoc windowController] window];
        [newWin orderWindow:NSWindowBelow relativeTo:[oldWin windowNumber]];
        
    }
    
    if (req) {
        FUWebView *webView = [[[newDoc windowController] selectedTabController] webView];
        [[webView mainFrame] loadRequest:req];
    }
    
    return newDoc;
}


- (FUTabController *)loadRequest:(NSURLRequest *)req {
    return [self loadRequest:req destinationType:[[FUUserDefaults instance] tabbedBrowsingEnabled] ? FUDestinationTypeTab : FUDestinationTypeWindow];
}


- (FUTabController *)loadRequest:(NSURLRequest *)req destinationType:(FUDestinationType)type {
    return [self loadRequest:req destinationType:type inForeground:[[FUUserDefaults instance] selectNewWindowsOrTabsAsCreated]];
}


- (FUTabController *)loadRequest:(NSURLRequest *)req destinationType:(FUDestinationType)type inForeground:(BOOL)inForeground {
    FUTabController *tc = nil;
    if (FUDestinationTypeWindow == type) {
        FUDocument *doc = [self openDocumentWithRequest:req makeKey:inForeground];
        tc = [[doc windowController] selectedTabController];
    } else {
        FUWindowController *wc = [self frontWindowController];
        tc = [wc loadRequest:req inNewTabInForeground:inForeground];
    }
    return tc;
}


- (FUTabController *)loadHTMLString:(NSString *)s {
    return [self loadHTMLString:s destinationType:[[FUUserDefaults instance] tabbedBrowsingEnabled] ? FUDestinationTypeTab : FUDestinationTypeWindow];
}


- (FUTabController *)loadHTMLString:(NSString *)s destinationType:(FUDestinationType)type {
    return [self loadHTMLString:s destinationType:type inForeground:[[FUUserDefaults instance] selectNewWindowsOrTabsAsCreated]];
}


- (FUTabController *)loadHTMLString:(NSString *)s destinationType:(FUDestinationType)type inForeground:(BOOL)inForeground {
    FUTabController *tc = nil;
    if (FUDestinationTypeWindow == type) {
        FUDocument *doc = [self openDocumentWithRequest:nil makeKey:inForeground];
        tc = [[doc windowController] selectedTabController];
        [[[tc webView] mainFrame] loadHTMLString:s baseURL:nil];
    } else {
        FUWindowController *wc = [self frontWindowController];
        if (inForeground) {
            [wc addNewTabInForeground:self];
        } else {
            [wc addNewTabInBackground:self];
        }
        tc = [wc selectedTabController];
        [[[tc webView] mainFrame] loadHTMLString:s baseURL:nil];
    }
    return tc;
}


- (WebFrame *)findFrameNamed:(NSString *)name outTabController:(FUTabController **)outTabController {
    // look for existing frame in any open browser document with this name.
    WebFrame *existingFrame = nil;
    
    for (FUDocument *doc in [self documents]) {
        for (FUTabController *tc in [[doc windowController] tabControllers]) {
            existingFrame = [[[tc webView] mainFrame] findFrameNamed:name];
            if (existingFrame) {
                if (outTabController) {
                    *outTabController = tc;
                }
                break;
            }
        }
    }
    
    return existingFrame;
}


- (FUDocument *)frontDocument {
    return (FUDocument *)[self currentDocument];
}


- (FUWindowController *)frontWindowController {
    return [[self frontDocument] windowController];
}


- (FUTabController *)frontTabController {
    return [[self frontWindowController] selectedTabController];
}


- (WebView *)frontWebView {
    return [[self frontTabController] webView];
}


#pragma mark -
#pragma mark Private

- (void)registerForAppleEventHandling {
    [[NSAppleEventManager sharedAppleEventManager] setEventHandler:self
                                                       andSelector:@selector(handleInternetOpenContentsEvent:replyEvent:)
                                                     forEventClass:kInternetEventClass
                                                        andEventID:kAEGetURL];
}


- (void)unregisterForAppleEventHandling {
    [[NSAppleEventManager sharedAppleEventManager] removeEventHandlerForEventClass:kInternetEventClass andEventID:kAEGetURL];
}


- (void)handleInternetOpenContentsEvent:(NSAppleEventDescriptor *)event replyEvent:(NSAppleEventDescriptor *)replyEvent {
    NSString *URLString = [[event paramDescriptorForKeyword:keyDirectObject] stringValue];
    [self handleOpenContentsAppleEventWithURL:URLString];
}


- (void)handleOpenContentsAppleEventWithURL:(NSString *)URLString {
    FUWindowController *wc = [self frontWindowController];
    NSWindow *window = [wc window];
    if ([window isMiniaturized]) {
        [window deminiaturize:self];
    }
    
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:URLString]];
    FUDestinationType type = [[FUUserDefaults instance] openLinksFromApplicationsIn];
    if (![[FUUserDefaults instance] tabbedBrowsingEnabled]) {
        type = FUDestinationTypeWindow;
    }
    [self loadRequest:req destinationType:type inForeground:YES];
}


- (void)saveSession {
    if (![[FUUserDefaults instance] sessionsEnabled]) return;
    
    NSArray *docs = [self documents];
    NSMutableArray *wins = [NSMutableArray arrayWithCapacity:[docs count]];
    
    for (FUDocument *doc in docs) {
        FUWindowController *wc = [doc windowController];
        NSArray *tabItems = [wc.tabView tabViewItems];
        NSMutableArray *tabs = [NSMutableArray arrayWithCapacity:[tabItems count]];
        
        for (NSTabViewItem *tabItem in tabItems) {
            [tabs addObject:[[tabItem identifier] URLString]];
        }
        
        NSDictionary *d = [NSDictionary dictionaryWithObjectsAndKeys:
                           [NSNumber numberWithInteger:wc.selectedTabIndex], @"selectedTabIndex",
                           tabs, @"tabs",
                           nil];
        
        [wins addObject:d];
    }
    
    [[FUUserDefaults instance] setSessionInfo:wins];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


- (void)restoreSession {
    if (![[FUUserDefaults instance] sessionsEnabled]) return;

    NSArray *wins = [[FUUserDefaults instance] sessionInfo];
    NSInteger i = 0;
    for (NSDictionary *d in wins) {
        FUDocument *doc = nil;
        
        if (0 == i++ && [[self documents] count]) {
            doc = [[self documents] objectAtIndex:0];
        } else {
            doc = [self openUntitledDocumentAndDisplay:YES error:nil];
        }
        
        FUWindowController *wc = doc.windowController;
        NSArray *tabs = [d objectForKey:@"tabs"];
        
        for (NSString *URLString in tabs) {
            [wc loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:URLString]] inNewTabInForeground:YES];
        }
        
        wc.selectedTabIndex = [[d objectForKey:@"selectedTabIndex"] integerValue];
    }
}

@synthesize hiddenWindow; // weak ref
@end
