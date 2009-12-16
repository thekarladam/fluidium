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

#import "FUWindowController.h"
#import "FUWindowController+NSToolbarDelegate.h"
#import "FUDocumentController.h"
#import "FUTabController.h"
#import "FUWindow.h"
#import "FUUserDefaults.h"
#import "FUProgressComboBox.h"
#import "FURecentURLController.h"
#import "FUViewSourceWindowController.h"
#import "FUShortcutController.h"
#import "FUShortcutCommand.h"
#import "FUBookmarkController.h"
#import "FUBookmark.h"
#import "FUActivation.h"
#import "FUUtils.h"
#import "FUWebView.h"
#import "FUPlugInController.h"
#import "NSString+FUAdditions.h"
#import "NSEvent+FUAdditions.h"
#import "TDUberView.h"
#import "WebURLsWithTitles.h"
#import "WebViewPrivate.h"
#import <WebKit/WebKit.h>
#import <PSMTabBarControl/PSMTabBarControl.h>

#define MIN_COMBOBOX_WIDTH 100

NSString *const FUWindowControllerDidOpenNotification = @"FUWindowControllerDidOpenNotification";
NSString *const FUWindowControllerWillCloseNotification = @"FUWindowControllerWillCloseNotification";

NSString *const FUWindowControllerDidOpenTabNotification = @"FUWindowControllerDidOpenTabNotification";
NSString *const FUWindowControllerWillCloseTabNotification = @"FUWindowControllerWillCloseTabNotification";
NSString *const FUWindowControllerDidChangeSelectedTabNotification = @"FUWindowControllerDidChangeSelectedTabNotification";

NSString *const FUTabControllerKey = @"FUTabController";

@interface NSObject (FUAdditions)
- (void)noop:(id)sender;
@end

@interface FUWindowController (FUTabBarDragging) // Don't use these for anything else
- (void)tabControllerWasDroppedOnTabBar:(FUTabController *)tc;
@end

@interface FUWindowController ()
- (void)setUpTabBar;
- (void)addNewTab;
- (BOOL)removeTabViewItem:(NSTabViewItem *)tabItem;
- (void)tabControllerWasRemovedFromTabBar:(FUTabController *)tc;
- (void)performWindowClose:(id)sender;
- (void)saveFrameString;
- (void)startObservingTabController:(FUTabController *)tc;
- (void)stopObservingTabController:(FUTabController *)tc;
- (NSTabViewItem *)tabViewItemForTabController:(FUTabController *)tc;

- (void)handleCommandClick:(FUActivation *)act request:(NSURLRequest *)req;

- (void)removeDocumentIconButton;
- (void)displayEstimatedProgress;
- (void)clearProgressInFuture;
- (void)clearProgress;

- (NSArray *)recentURLs;
- (NSArray *)matchingRecentURLs;
- (void)addRecentURL:(NSString *)s;
- (void)addMatchingRecentURL:(NSString *)s;

- (void)tabBarShownDidChange:(NSNotification *)n;
- (void)tabBarHiddenForSingleTabDidChange:(NSNotification *)n;
- (void)bookmarkBarShownDidChange:(NSNotification *)n;
- (void)statusBarShownDidChange:(NSNotification *)n;

- (void)toggleFindPanel:(BOOL)show;
- (BOOL)findPanelSearchField:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor;
@end

@implementation FUWindowController

- (id)init {
    return [self initWithWindowNibName:@"FUWindow"];
}


- (id)initWithWindowNibName:(NSString *)name {
    if (self = [super initWithWindowNibName:name]) {
        self.tabControllers = [NSMutableSet set];
        self.shortcutController = [[[FUShortcutController alloc] init] autorelease];
    }
    return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    for (FUTabController *tc in tabControllers) {
        [self stopObservingTabController:tc];
    }

    self.locationSplitView = nil;
    self.locationComboBox = nil;
    self.searchField = nil;
    self.tabContainerView = nil;
    self.tabBar = nil;
    self.bookmarkBar = nil;
    self.uberView = nil;
    self.statusBar = nil;
    self.statusTextField = nil;
    self.findPanelView = nil;
    self.findPanelSearchField = nil;
    self.tabView = nil;
    self.departingTabController = nil;
    self.viewSourceController = nil;
    self.shortcutController = nil;
    self.tabControllers = nil;
    self.selectedTabController = nil;
    self.currentTitle = nil;
    self.findTerm = nil;
    [super dealloc];
}


- (NSString *)description {
    return [NSString stringWithFormat:@"<FUWindowController %@ %p>", [[self selectedTabController] URLString], self];
}


- (void)awakeFromNib {    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    
    [nc addObserver:self
           selector:@selector(comboBoxWillDismiss:)
               name:NSComboBoxWillDismissNotification
             object:locationComboBox];
    
    [nc addObserver:self
           selector:@selector(controlTextDidBeginEditing:)
               name:NSControlTextDidBeginEditingNotification
             object:locationComboBox];
    
    [nc addObserver:self
           selector:@selector(windowDidResignKey:)
               name:NSWindowDidResignKeyNotification
             object:[self window]];

    [nc addObserver:self
           selector:@selector(bookmarkBarShownDidChange:)
               name:FUBookmarkBarShownDidChangeNotification
             object:nil];
    
    [nc addObserver:self
           selector:@selector(tabBarShownDidChange:)
               name:FUTabBarShownDidChangeNotification
             object:nil];
    
    [nc addObserver:self
           selector:@selector(tabBarHiddenForSingleTabDidChange:)
               name:FUTabBarHiddenForSingleTabDidChangeNotification
             object:nil];    
    
    [nc addObserver:self
           selector:@selector(statusBarShownDidChange:)
               name:FUStatusBarShownDidChangeNotification
             object:nil];
}


- (void)windowDidLoad {
    [self setUpToolbar];
    [self tabBarShownDidChange:nil];
    [self bookmarkBarShownDidChange:nil];
    [self statusBarShownDidChange:nil];
    [self setUpTabBar];

    [[self window] makeFirstResponder:locationComboBox];
    [[self window] setFrameFromString:[[FUUserDefaults instance] windowFrameString]];
    
    [self addNewTabInForeground:self];

    if ([[FUUserDefaults instance] newWindowsOpenWith]) {
        [self goHome:self];
    }
    
    [[NSNotificationCenter defaultCenter] postNotificationName:FUWindowControllerDidOpenNotification object:self userInfo:nil];
}


#pragma mark -
#pragma mark Actions

- (IBAction)goBack:(id)sender {
    [[self selectedTabController] goBack:sender];
}


- (IBAction)goForward:(id)sender {
    [[self selectedTabController] goForward:sender];
}


- (IBAction)reload:(id)sender {
    [[self selectedTabController] reload:sender];
}


- (IBAction)stopLoading:(id)sender {
    [[self selectedTabController] stopLoading:sender];
}


- (IBAction)goHome:(id)sender {
    [locationComboBox setStringValue:[[FUUserDefaults instance] homeURLString]];
    [self goToLocation:self];
}


- (IBAction)zoomIn:(id)sender {
    [[self selectedTabController] zoomIn:sender];
}


- (IBAction)zoomOut:(id)sender {
    [[self selectedTabController] zoomOut:sender];
}


- (IBAction)actualSize:(id)sender {
    [[self selectedTabController] actualSize:sender];
}


- (IBAction)goToLocation:(id)sender {
    NSMutableString *ms = [[[locationComboBox stringValue] mutableCopy] autorelease];
    CFStringTrimWhitespace((CFMutableStringRef)ms);
    
    if (![ms length]) {
        return;
    }
    
    NSString *s = [[ms copy] autorelease];
    FUShortcutCommand *cmd = [shortcutController commandForInput:s];
    
    if (cmd) {
        s = cmd.firstURLString;
    }
    
    [[self selectedTabController] setURLString:s];
    [[self selectedTabController] goToLocation:sender];

    if (cmd.isTabbed) {
        for (NSString *URLString in cmd.moreURLStrings) {
            [self loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:URLString]] inNewTabInForeground:YES];
        }
    }
}


- (IBAction)openSearch:(id)sender {
    NSWindow *win = [self window];
    if (![[win toolbar] isVisible]) {
        [win toggleToolbarShown:self];
    }
    
    [win makeFirstResponder:searchField];
}


- (IBAction)search:(id)sender {
    if (![[searchField stringValue] length]) {
        return;
    }
    
    NSMutableString *q = [[[searchField stringValue] mutableCopy] autorelease];
    CFStringTrimWhitespace((CFMutableStringRef)q);
    NSString *URLString = [NSString stringWithFormat:FUDefaultWebSearchFormatString(), [q stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]];
        
    FUActivation *act = [FUActivation activationFromEvent:[[self window] currentEvent]];
    
    if (act.isCommandKeyPressed) {
        NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:URLString]];
        [self handleCommandClick:act request:req];
    } else {
        [locationComboBox setStringValue:URLString];
        [self goToLocation:self];
    }    
}


- (IBAction)openLocation:(id)sender {
    NSWindow *win = [self window];
    if (![[win toolbar] isVisible]) {
        [win toggleToolbarShown:self];
    }
    
    [win performSelector:@selector(makeFirstResponder:) withObject:locationComboBox];
}


- (IBAction)viewSource:(id)sender {
    if (!viewSourceController) {
        self.viewSourceController = [[[FUViewSourceWindowController alloc] init] autorelease];
    }
    
    viewSourceController.URLString = [[self selectedTabController] URLString];

    NSString *sourceString = [[[[[[self selectedTabController] webView] mainFrame] dataSource] representation] documentSource];
    [viewSourceController displaySourceString:sourceString];
    
    [[self document] addWindowController:viewSourceController];
    [[viewSourceController window] makeKeyAndOrderFront:self];
}


- (IBAction)emptyCache:(id)sender {
    NSInteger result = NSRunAlertPanel(NSLocalizedString(@"Are you sure you want to empty the cache?", @""),
                                       @"",
                                       NSLocalizedString(@"Empty", @""),
                                       NSLocalizedString(@"Cancel", @""),
                                       nil);
    if (NSAlertDefaultReturn == result) {
        [[NSURLCache sharedURLCache] removeAllCachedResponses];
    }
}


- (IBAction)toggleToolbarShown:(id)sender {
    [[self window] toggleToolbarShown:sender];
}


- (IBAction)addNewTabInForeground:(id)sender {
    [self addNewTab];
    self.selectedTabIndex = ([tabControllers count] - 1);
    [[self window] makeFirstResponder:locationComboBox];
}


- (IBAction)addNewTabInBackground:(id)sender {
    [self addNewTab];
}


- (IBAction)closeTab:(id)sender {
    if (1 == [tabView numberOfTabViewItems]) {
        [self performWindowClose:sender];
        return;
    }
    
    NSTabViewItem *tabItem = [tabView selectedTabViewItem];

    if (![self removeTabViewItem:tabItem]) {
        return;
    }
}
    
    
- (IBAction)performClose:(id)sender {
    if (1 == [tabView numberOfTabViewItems]) {
        [self performWindowClose:sender];
    } else {
        [self closeTab:sender];
    }
}


- (IBAction)selectNextTab:(id)sender {
    NSInteger c = [tabView numberOfTabViewItems];
    NSUInteger i = self.selectedTabIndex + 1;
    
    i = (i % c);
    
    self.selectedTabIndex = i;
}


- (IBAction)selectPreviousTab:(id)sender {
    NSInteger c = [tabView numberOfTabViewItems];
    NSUInteger i = self.selectedTabIndex - 1;
    
    i = (i == -1) ? c - 1 : i;
    
    self.selectedTabIndex = i;
}


- (IBAction)hideFindPanel:(id)sender {
    if ([self isFindPanelVisible]) {
        [self toggleFindPanel:NO];
    }
}


- (IBAction)showFindPanel:(id)sender {
    if (![self isFindPanelVisible]) {
        [self toggleFindPanel:YES];
    }

    [[self window] makeFirstResponder:findPanelSearchField];
}


- (IBAction)find:(id)sender {
    WebView *wv = [[self selectedTabController] webView];
    if ([wv canMarkAllTextMatches]) {
        [wv unmarkAllTextMatches];
        [wv markAllMatchesForText:findTerm caseSensitive:NO highlight:YES limit:0];
    }
    BOOL forward = (NSFindPanelActionNext == [sender tag]);
    BOOL found = [wv searchFor:findTerm direction:forward caseSensitive:NO wrap:YES];
    
    if (!found && [findTerm length]) {
        NSBeep();
    }
}


- (IBAction)useSelectionForFind:(id)sender {
    self.findTerm = [[[[self selectedTabController] webView] selectedDOMRange] toString];
    [self find:sender];
}


- (IBAction)jumpToSelection:(id)sender {
    DOMElement *el = (DOMElement *)[[[[self selectedTabController] webView] selectedDOMRange] commonAncestorContainer];
    [el scrollIntoView:YES];
}


- (IBAction)addBookmark:(id)sender {
    NSString *URLString = [[self selectedTabController] URLString];
    if (![URLString length]) {
        NSBeep();
        return;
    }
    
    NSString *title = [[self selectedTabController] title];
    if (![title length]) {
        title = [URLString FU_stringByTrimmingURLSchemePrefix];
    }
    
    FUBookmark *b = [[[FUBookmark alloc] init] autorelease];
    b.title = title;
    b.content = URLString;
    
    [[FUBookmarkController instance] appendBookmark:b];
}


- (IBAction)bookmarkClicked:(id)sender {
    FUBookmark *bookmark = nil;
    if (sender && [sender isKindOfClass:[NSMenuItem class]]) {
        bookmark = [sender representedObject];
    } else if (sender && [sender isKindOfClass:[FUBookmark class]]) {
        bookmark = sender;
    } else {
        return;
    }
    
    NSString *URLString = [bookmark.content FU_stringByEnsuringURLSchemePrefix];    
    
    if ([bookmark.content hasPrefix:@"javascript:"]) {
        NSString *script = [NSString stringWithUTF8String:[bookmark.content UTF8String]];
        script = [script stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        
        [[[[self selectedTabController] webView] windowScriptObject] evaluateWebScript:script];
    } else {
        FUActivation *act = [FUActivation activationFromEvent:[[self window] currentEvent]];
        
        NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:URLString]];
        if (act.isCommandKeyPressed) {
            [self handleCommandClick:act request:req];
        } else {
            [self loadRequestInSelectedTab:req];
        }
    }
}


#pragma mark -
#pragma mark Public

- (FUTabController *)loadRequestInSelectedTab:(NSURLRequest *)req {
    FUTabController *tc = [self selectedTabController];
    [tc loadRequest:req];
    return tc;
}


- (FUTabController *)loadRequestInLastTab:(NSURLRequest *)req {
    FUTabController *tc = [self lastTabController];
    [tc loadRequest:req];
    return tc;
}


- (FUTabController *)loadRequest:(NSURLRequest *)req inNewTabInForeground:(BOOL)inForeground {
    FUTabController *tc = nil;
    if (inForeground) {
        // if the selected tab is empty, use it
        if ([[[self selectedTabController] URLString] length]) {
            [self addNewTabInForeground:self];
        }
        tc = [self loadRequestInSelectedTab:req];
    } else {
        [self addNewTabInBackground:self];
        tc = [self loadRequestInLastTab:req];
    }
    return tc;
}


- (FUTabController *)lastTabController {
    return [self tabControllerAtIndex:[tabView numberOfTabViewItems] - 1];
}


- (FUTabController *)tabControllerAtIndex:(NSInteger)i {
    if (i > [tabView numberOfTabViewItems] - 1) {
        return nil;
    }
    NSTabViewItem *tabItem = [tabView tabViewItemAtIndex:i];
    return [tabItem identifier];
}


- (FUTabController *)tabControllerForWebView:(WebView *)wv {
    for (FUTabController *tc in tabControllers) {
        if (wv == [tc webView]) {
            return tc;
        }
    }
    return nil;
}


- (void)orderTabControllerFront:(FUTabController *)tc {
    self.selectedTabIndex = [tabView indexOfTabViewItem:[self tabViewItemForTabController:tc]];
}


- (BOOL)removeTabController:(FUTabController *)tc {
    return [self removeTabViewItem:[self tabViewItemForTabController:tc]];
}


- (NSInteger)selectedTabIndex {
    return [tabView indexOfTabViewItem:[tabView selectedTabViewItem]];
}


- (void)setSelectedTabIndex:(NSInteger)i {
    [tabView selectTabViewItemAtIndex:i];
}


#pragma mark -
#pragma mark NSMenuValidation

- (BOOL)validateMenuItem:(NSMenuItem *)item {
    SEL action = [item action];
    
    if (action == @selector(setDisplayMode:) || action == @selector(setSizeMode:)) { // no changing the toolbar modes
        return NO;
    } else if (action == @selector(closeTab:) || action == @selector(addNewTabInForeground:)) {
        return [[FUUserDefaults instance] tabbedBrowsingEnabled];
    } else if (action == @selector(selectNextTab:) || action == @selector(selectPreviousTab:)) {
        id responder = [[self window] firstResponder];
        return ![responder isKindOfClass:[NSTextView class]];
    } else if (action == @selector(viewSource:)) {
        return ![[[self selectedTabController] webView] isLoading] && [[[self selectedTabController] URLString] length];
    } else if (action == @selector(stopLoading:)) {
        return [[[self selectedTabController] webView] isLoading];
    } else if (action == @selector(reload:) || action == @selector(showFindPanel:) || action == @selector(addBookmark:)) {
        return [[[self selectedTabController] URLString] length];
    } else if (action == @selector(goBack:)) {
        return [[[self selectedTabController] webView] canGoBack];
    } else if (action == @selector(goForward:)) {
        return [[[self selectedTabController] webView] canGoForward];
    } else if (action == @selector(goHome:)) {
        return [[[FUUserDefaults instance] homeURLString] length];
    } else if (action == @selector(zoomIn:)) {
        return [[self selectedTabController] canZoomIn];
    } else if (action == @selector(zoomOut:)) {
        return [[self selectedTabController] canZoomOut];
    } else if (action == @selector(actualSize:)) {
        return [[self selectedTabController] canActualSize];
    } else {
        return YES;
    }
}


#pragma mark -
#pragma mark NSSplitViewDelegate

- (CGFloat)splitView:(NSSplitView *)sv constrainMinCoordinate:(CGFloat)proposedMin ofSubviewAt:(NSInteger)offset {
    return MIN_COMBOBOX_WIDTH;
}


- (CGFloat)splitView:(NSSplitView *)sv constrainMaxCoordinate:(CGFloat)proposedMax ofSubviewAt:(NSInteger)offset {
    return NSWidth([sv frame]) - MIN_COMBOBOX_WIDTH;
}


#pragma mark -
#pragma mark NSControl Text

- (void)controlTextDidBeginEditing:(NSNotification *)n {
    NSControl *control = [n object];
    
    if (control == locationComboBox) {
        // TODO ? use binding instead?
        [locationComboBox showDefaultIcon];
    } else {
        typingInFindPanel = YES;
    }
}


- (BOOL)control:(NSControl *)control textShouldBeginEditing:(NSText *)fieldEditor {
    if (control == locationComboBox) {
        [[FURecentURLController instance] resetMatchingRecentURLs];
        displayingMatchingRecentURLs = YES;
        return YES;
    } else {
        return YES;
    }
}


- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor {
    if (control == locationComboBox) {
        [locationComboBox hidePopUp];
        displayingMatchingRecentURLs = NO;
        return YES;
    } else {
        return [self findPanelSearchField:control textShouldEndEditing:fieldEditor];
    }
}


- (BOOL)findPanelSearchField:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor {
    NSEvent *evt = [NSApp currentEvent];    
    BOOL result = NO;
    
    if (!typingInFindPanel) {
        result = YES;
    } else if (NSKeyUp == [evt type] || NSKeyDown == [evt type]) {
        if ([evt FU_isCommandKeyPressed] ||
            [evt FU_isOptionKeyPressed] ||
            [evt FU_isCommandKeyPressed] ||
            [evt FU_isEscKeyPressed] ||
            [evt FU_isReturnKeyPressed] ||
            [evt FU_isEnterKeyPressed]) {
            result = YES;
        }
    }
    
    return result;
}


// necessary to handle cmd-Return in search field
- (BOOL)control:(NSControl *)control textView:(NSTextView *)tv doCommandBySelector:(SEL)sel {
    if (control == searchField) {
        BOOL isCommandClick = [[[self window] currentEvent] FU_isCommandKeyPressed];
        
        if (@selector(noop:) == sel && isCommandClick) {
            [self search:control];
            return YES;
        }
    }
    
    return NO;
}


- (void)controlTextDidChange:(NSNotification *)n {
    NSControl *control = [n object];
    
    if (control == findPanelSearchField) {
        WebView *wv = [[self selectedTabController] webView];
        DOMRange *r = [wv selectedDOMRange];
        [r collapse:YES];
        [wv setSelectedDOMRange:r affinity:NSSelectionAffinityUpstream];
        [self find:findPanelSearchField];
    }
}


- (void)controlTextDidEndEditing:(NSNotification *)n {
    if (findPanelSearchField == [n object]) {
        typingInFindPanel = NO;
    }
}


#pragma mark -
#pragma mark NSComboBoxDataSource

- (void)comboBoxWillDismiss:(NSNotification *)n {
    if (locationComboBox == [n object]) {
        NSInteger i = [locationComboBox indexOfSelectedItem];
        NSInteger c = [locationComboBox numberOfItems];
        
        // last item (clear url menu) was clicked. clear recentURLs
        if (c && i == c - 1) {
            if (![[NSApp currentEvent] FU_isEscKeyPressed]) {
                NSString *s = [locationComboBox stringValue];
                [locationComboBox deselectItemAtIndex:i];
                
                [[FURecentURLController instance] resetRecentURLs];
                [[FURecentURLController instance] resetMatchingRecentURLs];
                
                [locationComboBox reloadData];
                [locationComboBox setStringValue:s];
            }
        }
    }
}


- (id)comboBox:(NSComboBox *)cb objectValueForItemAtIndex:(NSInteger)i {
    if (locationComboBox == cb) {
        NSArray *URLs = displayingMatchingRecentURLs ? [self matchingRecentURLs] : [self recentURLs];
        
        NSInteger c = [URLs count];
        if (!c) {
            [locationComboBox hidePopUp];
        }
        if (c && i == c) {
            NSDictionary *attrs = [NSDictionary dictionaryWithObject:[NSColor grayColor] forKey:NSForegroundColorAttributeName];
            return [[[NSAttributedString alloc] initWithString:NSLocalizedString(@"Clear Recent URL Menu", @"") attributes:attrs] autorelease];
        } else {
            if (i < c) {
                return [URLs objectAtIndex:i];
            } else {
                return nil;
            }
        }
    } else {
        return nil;
    }
}


- (NSInteger)numberOfItemsInComboBox:(NSComboBox *)cb {
    if (locationComboBox == cb) {
        NSArray *URLs = displayingMatchingRecentURLs ? [self matchingRecentURLs] : [self recentURLs];
        NSInteger c = [URLs count];
        if (c) {
            return c + 1;
        } else {
            [locationComboBox hidePopUp];
        }
        return c;
    } else {
        return 0;
    }
}


- (NSUInteger)comboBox:(NSComboBox *)cb indexOfItemWithStringValue:(NSString *)s {
    if (locationComboBox == cb) {
        if (displayingMatchingRecentURLs) {
            return [[self matchingRecentURLs] indexOfObject:s];
        }
        return [[self recentURLs] indexOfObject:s];
    } else {
        return 0;
    }
}


- (NSString *)comboBox:(NSComboBox *)cb completedString:(NSString *)uncompletedString {
    if (locationComboBox == cb) {
        [[FURecentURLController instance] resetMatchingRecentURLs];
        
        for (NSString *URLString in [self recentURLs]) {
            URLString = [URLString FU_stringByTrimmingURLSchemePrefix];
            if ([URLString hasPrefix:uncompletedString]) {
                [self addMatchingRecentURL:URLString];
            }
        }
        
        if ([[self matchingRecentURLs] count]) {
            [[locationComboBox cell] scrollItemAtIndexToVisible:0];
            [locationComboBox showPopUpWithItemCount:[[self matchingRecentURLs] count]];
            return [[self matchingRecentURLs] objectAtIndex:0];
        }
        return nil;
    } else {
        return nil;
    }
}


// prevent suggestions in locationcombobox on <esc> key
- (NSArray *)control:(NSControl *)control textView:(NSTextView *)tv completions:(NSArray *)words forPartialWordRange:(NSRange)charRange indexOfSelectedItem:(NSInteger *)i {
    return nil;
}


#pragma mark -
#pragma mark HMImageComboBoxDelegate

- (BOOL)hmComboBox:(HMImageComboBox *)cb writeDataToPasteboard:(NSPasteboard *)pboard {
    if (locationComboBox == cb) {
        WebView *wv = [[self selectedTabController] webView];
        
        NSString *URLString = [wv mainFrameURL];
        if (![URLString length]) {
            return NO;
        }
        
        NSString *title = [wv mainFrameTitle];
        if (![title length]) {
            title = [URLString FU_stringByTrimmingURLSchemePrefix];        
        }
        
        NSArray *types = [NSArray arrayWithObjects:WebURLsWithTitlesPboardType, NSURLPboardType, NSStringPboardType, nil];
        [pboard declareTypes:types owner:nil];
        
        NSURL *URL = [NSURL URLWithString:URLString];
        
        // write WebURLsWithTitlesPboardType type
        [WebURLsWithTitles writeURLs:[NSArray arrayWithObject:URL] andTitles:[NSArray arrayWithObject:title] toPasteboard:pboard];
        
        // write NSURLPboardType type
        [URL writeToPasteboard:pboard];
        
        // write NSStringPboardType type
        [pboard setString:URLString forType:NSStringPboardType];
        
        return YES;
    } else {
        return NO;
    }
}



#pragma mark -
#pragma mark NSTabViewDelegate

- (void)tabView:(NSTabView *)tv willSelectTabViewItem:(NSTabViewItem *)tabItem {
    if ([self selectedTabController]) {
        [self stopObservingTabController:[self selectedTabController]];
        self.selectedTabController = nil;
    }
}


- (void)tabView:(NSTabView *)tv didSelectTabViewItem:(NSTabViewItem *)tabItem {    
    FUTabController *tc = [tabItem identifier];
    
    if ([tabControllers containsObject:tc]) { // if the tab was just dragged to this tabBar from another window, we will not have created a tabController yet

        [self clearProgress];
        self.selectedTabController = tc;
        [self startObservingTabController:tc];
        [self clearProgress];
    }

    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:tc forKey:FUTabControllerKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:FUWindowControllerDidChangeSelectedTabNotification object:self userInfo:userInfo];
}


- (BOOL)tabView:(NSTabView *)tv shouldCloseTabViewItem:(NSTabViewItem *)tabItem {
    if (tabItem == [tabView selectedTabViewItem]) {
        closingSelectedTabIndex = [tabView indexOfTabViewItem:tabItem];
    } else {
        closingSelectedTabIndex = -1;
    }
    return YES;
}


- (void)tabView:(NSTabView *)tv didCloseTabViewItem:(NSTabViewItem *)tabItem {
    FUTabController *tc = [tabItem identifier];
    
    [self tabControllerWasRemovedFromTabBar:tc];

    if (closingSelectedTabIndex != -1) {
        // NSTabView behavior on closing a selected tab is to select the tab at the next lower index (prev)
        // However, most browsers instead select the next higher index (next)
        // this changes the NSTabView behavior to match browser behavior expectations
        NSInteger c = [tabView numberOfTabViewItems];
        NSUInteger i = closingSelectedTabIndex;
        BOOL selectNext = i != 0 && i != c;
        
        if (selectNext) {
            [self selectNextTab:self];
        }
    }
}


#pragma mark -
#pragma mark PSMTabBarControl Dragging

- (NSArray *)allowedDraggedTypesForTabView:(NSTabView *)tv {
    return [NSArray arrayWithObjects:WebURLsWithTitlesPboardType, NSURLPboardType, nil];    
}


- (void)tabView:(NSTabView *)tv acceptedDraggingInfo:(id <NSDraggingInfo>)draggingInfo onTabViewItem:(NSTabViewItem *)tabItem {
    NSPasteboard *pboard = [draggingInfo draggingPasteboard];
    NSArray *types = [pboard types];
    
    BOOL hasWebURLs = (NSNotFound != [types indexOfObject:WebURLsWithTitlesPboardType]);
    BOOL hasURLs = (NSNotFound != [types indexOfObject:NSURLPboardType]);
    
    NSArray *URLs = nil;
    if (hasWebURLs) {
        URLs = [WebURLsWithTitles URLsFromPasteboard:pboard];
    } else if (hasURLs) {
        URLs = [pboard propertyListForType:NSURLPboardType];
    }
    
    for (NSURL *URL in URLs) {
        FUTabController *tc = [tabItem identifier];
        [tc loadRequest:[NSURLRequest requestWithURL:URL]];
        break;
    }
}


- (BOOL)tabView:(NSTabView *)tv shouldDragTabViewItem:(NSTabViewItem *)tabItem fromTabBar:(PSMTabBarControl *)tabBarControl {
    return [tabView numberOfTabViewItems] > 1;
}


- (BOOL)tabView:(NSTabView *)tv shouldAllowTabViewItem:(NSTabViewItem *)tabItem toLeaveTabBar:(PSMTabBarControl *)tabBarControl {
    if ([tabView numberOfTabViewItems] < 2) {
        return NO;
    }
    
    departingTabController = [tabItem identifier];

    return YES;
}


- (BOOL)tabView:(NSTabView *)tv shouldDropTabViewItem:(NSTabViewItem *)tabItem inTabBar:(PSMTabBarControl *)tabBarControl {
    return YES;
}


- (void)tabView:(NSTabView *)tv didDropTabViewItem:(NSTabViewItem *)tabItem inTabBar:(PSMTabBarControl *)tabBarControl {
    if (tabBarControl == tabBar) { // dropped on originating window. nothing to do.
        return;
    }

    [self tabControllerWasRemovedFromTabBar:departingTabController];

    FUWindowController *wc = (FUWindowController *)[[tabBarControl window] windowController];
    [wc tabControllerWasDroppedOnTabBar:departingTabController];
    
    // must call this manually
    [wc tabView:wc.tabView didSelectTabViewItem:[wc tabViewItemForTabController:departingTabController]];
}


- (NSImage *)tabView:(NSTabView *)tv imageForTabViewItem:(NSTabViewItem *)tabItem offset:(NSSize *)offset styleMask:(unsigned int *)styleMask {
    if (styleMask) {
        *styleMask = NSTitledWindowMask | NSTexturedBackgroundWindowMask;
    }
    
    FUWebView *wv = [[tabItem identifier] webView];
    
    return [wv FU_imageRepresentation];
}


#pragma mark -
#pragma mark NSWindowNotifications
// dont need to register for these explicity

- (void)windowDidResignKey:(NSNotification *)n {
    [locationComboBox hidePopUp];
}


- (void)windowDidMove:(NSNotification *)n {
    [self saveFrameString];
}


- (void)windowDidResize:(NSNotification *)n {
    [self saveFrameString];
}


- (void)windowDidChangeScreen:(NSNotification *)n {
    NSInteger i = [[NSScreen screens] indexOfObject:[[self window] screen]];
    [[FUUserDefaults instance] setWindowScreenIndex:i];
}


- (void)windowWillClose:(NSNotification *)n {
    [[NSNotificationCenter defaultCenter] postNotificationName:FUWindowControllerWillCloseNotification object:self];
}


#pragma mark -
#pragma mark Private

- (void)setUpTabBar {
    self.tabView = [[[NSTabView alloc] initWithFrame:NSZeroRect] autorelease];
    [tabView setTabViewType:NSNoTabsNoBorder];
    [tabView setDrawsBackground:NO];
    [tabView setDelegate:tabBar];
    [tabView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    
    [tabBar setDelegate:self];
    [tabBar setPartnerView:uberView];
    [tabBar setTabView:tabView];
    
    [tabBar setStyleNamed:@"Adium"];
    [tabBar setTearOffStyle:PSMTabBarTearOffMiniwindow];
    [tabBar setUseOverflowMenu:YES];
    [tabBar setAllowsScrubbing:YES];
    [tabBar setHideForSingleTab:[[FUUserDefaults instance] tabBarHiddenForSingleTab]];
    [tabBar setShowAddTabButton:NO];
    [tabBar setCellOptimumWidth:[[FUUserDefaults instance] tabBarCellOptimumWidth]];
    [[tabBar addTabButton] setTarget:self];
    [[tabBar addTabButton] setAction:@selector(addNewTabInForeground:)];
    
    uberView.midView = tabView;
}


- (void)addNewTab {
    FUTabController *tc = [[[FUTabController alloc] initWithWindowController:self] autorelease];
    [tabControllers addObject:tc];
    
    NSTabViewItem *tabItem = [[[NSTabViewItem alloc] initWithIdentifier:tc] autorelease];
    [tabItem setView:tc.view];
    [tabItem bind:@"label" toObject:tc withKeyPath:@"title" options:nil];
    
    [tabView addTabViewItem:tabItem];
    
    // must set this controller's window as host window or else Flash content won't play in background tabs
    [[tc webView] setHostWindow:[self window]];
    
    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:tc forKey:FUTabControllerKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:FUWindowControllerDidOpenTabNotification object:self userInfo:userInfo];
}


- (BOOL)removeTabViewItem:(NSTabViewItem *)tabItem {
    FUTabController *tc = [tabItem identifier];

    NSDictionary *userInfo = [NSDictionary dictionaryWithObject:tc forKey:FUTabControllerKey];
    [[NSNotificationCenter defaultCenter] postNotificationName:FUWindowControllerWillCloseTabNotification object:self userInfo:userInfo];
    
    // must call this manually
    if (![self tabView:tabView shouldCloseTabViewItem:tabItem]) {
        return NO;
    }
    
    if ([self selectedTabController] == tc) {
        [self stopObservingTabController:tc];
    }
    
    [tabView removeTabViewItem:tabItem];
    
    [[tc retain] autorelease];
    [tabControllers removeObject:tc];
    
    return YES;
}


- (void)tabControllerWasRemovedFromTabBar:(FUTabController *)tc {
    [[tc retain] autorelease];
    
    if (tc == [self selectedTabController]) {
        self.selectedTabController = nil;
        [self stopObservingTabController:tc];
    }
    
    [tabControllers removeObject:tc];
}


- (void)performWindowClose:(id)sender {
    BOOL onlyHide = [[FUUserDefaults instance] hideLastClosedWindow];
    BOOL onlyOneWin = 1 == [[[FUDocumentController instance] documents] count];
    if (onlyHide && onlyOneWin) {
        [[FUDocumentController instance] setHiddenWindow:[self window]];
        [[self window] orderOut:self];
    } else {
        [(FUWindow *)[self window] FU_forcePerformClose:sender];
    }
}


- (void)saveFrameString {
    if (suppressNextFrameStringSave) {
        self.suppressNextFrameStringSave = NO;
    } else {
        NSString *s = [[self window] stringWithSavedFrame];
        [[FUUserDefaults instance] setWindowFrameString:s];
    }
}


- (void)startObservingTabController:(FUTabController *)tc {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(tabControllerProgressDidStart:) name:FUTabControllerProgressDidStartNotification object:tc];
    [nc addObserver:self selector:@selector(tabControllerProgressDidChange:) name:FUTabControllerProgressDidChangeNotification object:tc];
    [nc addObserver:self selector:@selector(tabControllerProgressDidFinish:) name:FUTabControllerProgressDidFinishNotification object:tc];
    [nc addObserver:self selector:@selector(tabControllerDidCommitLoad:) name:FUTabControllerDidCommitLoadNotification object:tc];
    
    // bind title
    [[self window] bind:@"title" toObject:tc withKeyPath:@"title" options:nil];
    
    // bind URLString
    [locationComboBox bind:@"stringValue" toObject:tc withKeyPath:@"URLString" options:nil];
        
    // bind icon
    [locationComboBox bind:@"image" toObject:tc withKeyPath:@"favicon" options:nil];

    // bind status text
    [statusTextField bind:@"stringValue" toObject:tc withKeyPath:@"statusText" options:nil];
}


- (void)stopObservingTabController:(FUTabController *)tc {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc removeObserver:self name:FUTabControllerProgressDidStartNotification object:tc];
    [nc removeObserver:self name:FUTabControllerProgressDidChangeNotification object:tc];
    [nc removeObserver:self name:FUTabControllerProgressDidFinishNotification object:tc];
    [nc removeObserver:self name:FUTabControllerDidCommitLoadNotification object:tc];

    // unbind title
    [[self window] unbind:@"title"];
    
    // unbind URLString
    [locationComboBox unbind:@"stringValue"];
    
    // unbind icon
    [locationComboBox unbind:@"image"];    

    // unbind status text
    [statusTextField unbind:@"stringValue"];
}


- (void)tabControllerWasDroppedOnTabBar:(FUTabController *)tc {
    if (![tabControllers containsObject:tc]) { // TODO is this necessary since this is an NSMutableSet?
        [tabControllers addObject:tc];
    }
}


- (void)handleCommandClick:(FUActivation *)act request:(NSURLRequest *)req {    
    BOOL inTab = [[FUUserDefaults instance] tabbedBrowsingEnabled];
    BOOL inForeground = [[FUUserDefaults instance] selectNewWindowsOrTabsAsCreated];
    
    inForeground = act.isShiftKeyPressed ? !inForeground : inForeground;
    inTab = act.isOptionKeyPressed ? !inTab : inTab;
    
    if (inTab) {
        [self loadRequest:req inNewTabInForeground:inForeground];
    } else {
        [[FUDocumentController instance] openDocumentWithRequest:req makeKey:YES];
    }
}


- (NSTabViewItem *)tabViewItemForTabController:(FUTabController *)tc {
    for (NSTabViewItem *tabItem in [tabView tabViewItems]) {
        if (tc == [tabItem identifier]) {
            return tabItem;
        }
    }
    return nil;
}


- (void)tabControllerProgressDidStart:(NSNotification *)n {
    [self clearProgress];
}


- (void)tabControllerProgressDidChange:(NSNotification *)n {
    FUTabController *tc = [n object];
    if (tc == [self selectedTabController]) {
        [self displayEstimatedProgress];
    }
}


- (void)tabControllerProgressDidFinish:(NSNotification *)n {
    FUTabController *tc = [n object];
    if (tc == [self selectedTabController]) {
        WebView *wv = [tc webView];
        if ([[wv mainFrameURL] hasPrefix:kFUAboutBlank]) {
            [locationComboBox setStringValue:[[[wv backForwardList] currentItem] URLString]];
        } else {
            tc.lastLoadFailed = NO;
        }
        [self clearProgressInFuture];
    }
}


- (void)tabControllerDidCommitLoad:(NSNotification *)n {
    FUTabController *tc = [n object];
    
    NSString *finalURLString = tc.URLString;
    NSString *initialURLString = tc.initialURLString;
    
    [self addRecentURL:finalURLString];
    [self addRecentURL:initialURLString]; // if they are the same, this will not be added
}


- (void)displayEstimatedProgress {
    locationComboBox.progress = [[[self selectedTabController] webView] estimatedProgress];
}


- (void)clearProgressInFuture {
    [NSTimer scheduledTimerWithTimeInterval:.2 target:self selector:@selector(clearProgress) userInfo:nil repeats:NO];
}


- (void)clearProgress {
    locationComboBox.progress = 0;
}


- (void)removeDocumentIconButton {
    [[[self window] standardWindowButton:NSWindowDocumentIconButton] setFrame:NSZeroRect];
}


- (NSArray *)recentURLs {
    return [[FURecentURLController instance] recentURLs];
}


- (NSArray *)matchingRecentURLs {
    return [[FURecentURLController instance] matchingRecentURLs];
}


- (void)addRecentURL:(NSString *)s {
    [[FURecentURLController instance] addRecentURL:s];
    [locationComboBox noteNumberOfItemsChanged];
    [locationComboBox reloadData];
}


- (void)addMatchingRecentURL:(NSString *)s {
    [[FURecentURLController instance] addMatchingRecentURL:s];
    [locationComboBox noteNumberOfItemsChanged];
    [locationComboBox reloadData];
}


- (void)tabBarShownDidChange:(NSNotification *)n {
    BOOL hiddenAlways = [[FUUserDefaults instance] tabBarHiddenAlways];
    NSRect tabBarFrame = [tabBar frame];
    CGFloat tabBarHeight = tabBarFrame.size.height;
    
    NSRect uberFrame = [uberView frame];
    if (hiddenAlways) {
        uberFrame.size.height += tabBarHeight;
    } else {
        uberFrame.size.height -= tabBarHeight;
    }
    
    [uberView setFrame:uberFrame];
    [uberView setNeedsDisplay:YES];
}    


- (void)tabBarHiddenForSingleTabDidChange:(NSNotification *)n {
    [tabBar setHideForSingleTab:[[FUUserDefaults instance] tabBarHiddenForSingleTab]];
}


- (void)bookmarkBarShownDidChange:(NSNotification *)n {
    BOOL hidden = ![[FUUserDefaults instance] bookmarkBarShown];
    
    if (hidden && [bookmarkBar isHidden]) {
        return;
    } else if (!hidden && ![bookmarkBar isHidden]) {
        return;
    }

    CGFloat height = NSHeight([bookmarkBar bounds]);
    [bookmarkBar setHidden:hidden];
    
    NSSize oldContainerSize = [tabContainerView frame].size;
    NSSize newContainerSize = oldContainerSize;
    
    if (hidden) {
        newContainerSize.height += height;
    } else {
        newContainerSize.height -= height;
    }
    
    [tabContainerView setFrameSize:newContainerSize];
    
    [bookmarkBar setNeedsDisplay:YES];
    [tabBar setNeedsDisplay:YES];
    [uberView setNeedsDisplay:YES];
}


- (void)statusBarShownDidChange:(NSNotification *)n {
    [self hideFindPanel:self];
    
    BOOL hidden = ![[FUUserDefaults instance] statusBarShown];
    
    if (hidden && [statusBar isHidden]) {
        return;
    } else if (!hidden && ![statusBar isHidden]) {
        return;
    }
    
    CGFloat height = NSHeight([statusBar bounds]);
    [statusBar setHidden:hidden];
    
    NSPoint oldContainerOrigin = [tabContainerView frame].origin;
    NSPoint newContainerOrigin = oldContainerOrigin;
    
    NSSize oldContainerSize = [tabContainerView frame].size;
    NSSize newContainerSize = oldContainerSize;
    
    if (hidden) {
        newContainerOrigin.y -= height;
        newContainerSize.height += height;
    } else {
        newContainerOrigin.y += height;
        newContainerSize.height -= height;
    }
    
    [tabContainerView setFrameOrigin:newContainerOrigin];
    [tabContainerView setFrameSize:newContainerSize];
    
    [findPanelView setNeedsDisplay:YES];
    [statusBar setNeedsDisplay:YES];
    [tabContainerView setNeedsDisplay:YES];
    [tabBar setNeedsDisplay:YES];
    [bookmarkBar setNeedsDisplay:YES];
    [[[self selectedTabController] webView] setNeedsDisplay:YES];
}


- (BOOL)isFindPanelVisible {
    return (nil != [findPanelView superview]);
}


- (void)toggleFindPanel:(BOOL)show {
    [[[self selectedTabController] webView] unmarkAllTextMatches];
    
    BOOL statusBarShown = [[FUUserDefaults instance] statusBarShown];
    
    CGFloat statusBarHeight = statusBarShown ? NSHeight([statusBar bounds]) : 0;
    CGFloat findPanelHeight = NSHeight([findPanelView bounds]);
    
    NSPoint oldContainerOrigin = [tabContainerView frame].origin;
    NSPoint newContainerOrigin = oldContainerOrigin;
    
    NSSize oldContainerSize = [tabContainerView frame].size;
    NSSize newContainerSize = oldContainerSize;
    
    if (show) {
        NSView *contentView = [[self window] contentView];
        
        newContainerOrigin.y += findPanelHeight;
        newContainerSize.height -= findPanelHeight;
        [findPanelView setFrameSize:NSMakeSize(NSWidth([contentView bounds]), NSHeight([findPanelView bounds]))];
        [findPanelView setFrameOrigin:NSMakePoint(0, statusBarHeight)];
        [contentView addSubview:findPanelView];
        [[self window] makeFirstResponder:findPanelSearchField];
    } else {
        [findPanelView removeFromSuperview];
        newContainerOrigin.y -= findPanelHeight;
        newContainerSize.height += findPanelHeight;
        [[self window] makeFirstResponder:[[self selectedTabController] webView]];
    }
    
    [tabContainerView setFrameOrigin:newContainerOrigin];
    [tabContainerView setFrameSize:newContainerSize];
    
    [findPanelView setNeedsDisplay:YES];
    [statusBar setNeedsDisplay:YES];
    [tabContainerView setNeedsDisplay:YES];
    [tabBar setNeedsDisplay:YES];
    [bookmarkBar setNeedsDisplay:YES];
    [[[self selectedTabController] webView] setNeedsDisplay:YES];
}

@synthesize locationSplitView;
@synthesize locationComboBox;
@synthesize searchField;
@synthesize tabContainerView;
@synthesize tabBar;
@synthesize bookmarkBar;
@synthesize uberView;
@synthesize statusBar;
@synthesize statusTextField;
@synthesize findPanelView;
@synthesize findPanelSearchField;
@synthesize tabView;
@synthesize departingTabController;
@synthesize viewSourceController;
@synthesize shortcutController;
@synthesize tabControllers;
@synthesize selectedTabController;
@synthesize currentTitle;
@synthesize findTerm;
@synthesize suppressNextFrameStringSave;
@end
