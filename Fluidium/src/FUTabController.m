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

#import "FUTabController.h"
#import "FUDocumentController.h"
#import "FUWindowController.h"
#import "FUWebPreferences.h"
#import "FUWhitelistController.h"
#import "FUUserDefaults.h"
#import "FUUtils.h"
#import "FUActivation.h"
#import "FUWebView.h"
#import "FUView.h"
#import "FURecentURLController.h"
#import "FUDownloadWindowController.h"
#import "NSString+FUAdditions.h"
#import "DOMNode+FUAdditions.h"
#import "WebIconDatabase+FUAdditions.h"
#import "WebViewPrivate.h"
#import <WebKit/WebKit.h>

NSString *const FUTabControllerProgressDidStartNotification = @"FUTabControllerProgressDidStartNotification";
NSString *const FUTabControllerProgressDidChangeNotification = @"FUTabControllerProgressDidChangeNotification";
NSString *const FUTabControllerProgressDidFinishNotification = @"FUTabControllerProgressDidFinishNotification";

NSString *const FUTabControllerDidCommitLoadNotification = @"FUTabControllerDidCommitLoadNotification";
NSString *const FUTabControllerDidFinishLoadNotification = @"FUTabControllerDidFinishLoadNotification";
NSString *const FUTabControllerDidFailLoadNotification = @"FUTabControllerDidFailLoadNotification";
NSString *const FUTabControllerDidClearWindowObjectNotification = @"FUTabControllerDidClearWindowObjectNotification";

typedef enum {
    WebNavigationTypePlugInRequest = WebNavigationTypeOther + 1
} WebExtraNavigationType;

@interface WebView (FUAdditions)
+ (BOOL)_canHandleRequest:(NSURLRequest *)req;
@end

@interface FUTabController ()
- (void)setUpWebView;
- (void)handleLoadFail:(NSError *)err;
- (BOOL)willRetryWithTLDAdded:(WebView *)wv;
- (NSImage *)defaultFavicon;

- (void)postNotificationName:(NSString *)name;
- (BOOL)shouldHandleRequest:(NSURLRequest *)req;
- (BOOL)insertItem:(NSMenuItem *)item intoMenuItems:(NSMutableArray *)items afterItemWithTag:(NSInteger)tag;
- (NSInteger)indexOfItemWithTag:(NSUInteger)tag inMenuItems:(NSArray *)items;
- (NSString *)currentSelectionFromWebView;

- (void)openPanelDidEnd:(NSSavePanel *)openPanel returnCode:(NSInteger)code contextInfo:(id <WebOpenPanelResultListener>)listener;
- (void)savePanelDidEnd:(NSSavePanel *)savePanel returnCode:(int)code contextInfo:(NSURL *)URL;
@end

@interface FUWindowController ()
- (void)handleCommandClick:(FUActivation *)act request:(NSURLRequest *)req;
@end

@implementation FUTabController

- (id)initWithWindowController:(FUWindowController *)wc {
    if (self = [super init]) {
        self.windowController = wc;
        
        // necessary to prevent bindings exceptions
        self.URLString = @"";
        self.title = NSLocalizedString(@"Untitled", @"");
        self.favicon = [self defaultFavicon];
        self.statusText = @"";
    }
    return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    // taking some extra paranoid steps here with the webView to prevent crashing 
    // on one of the many callbacks/notifications that can be sent to or received by webviews
    // when the tab closes
    [[NSNotificationCenter defaultCenter] removeObserver:webView];
    [webView stopLoading:self];
    [webView setFrameLoadDelegate:nil];
    [webView setResourceLoadDelegate:nil];
    [webView setDownloadDelegate:nil];
    [webView setPolicyDelegate:nil];
    [webView setUIDelegate:nil];
    
    self.view = nil;
    self.webView = nil;
    self.windowController = nil;
    self.URLString = nil;
    self.initialURLString = nil;
    self.title = nil;
    self.favicon = nil;
    self.statusText = nil;
    self.clickElementInfo = nil;
    self.hoverElementInfo = nil;
    [super dealloc];
}


- (NSString *)description {
    return [NSString stringWithFormat:@"<FUTabController %@>", title];
}


#pragma mark -
#pragma mark Actions

- (IBAction)goBack:(id)sender {
    [webView goBack:sender];
}


- (IBAction)goForward:(id)sender {
    [webView goForward:sender];
}


- (IBAction)reload:(id)sender {
    if (self.lastLoadFailed) {
        [self goToLocation:self];
    } else {
        [webView reload:sender];
    }
}


- (IBAction)stopLoading:(id)sender {
    [webView stopLoading:sender];
}


- (IBAction)goToLocation:(id)sender {
    if (![URLString length]) {
        return;
    }
    
    self.title = NSLocalizedString(@"Loading...", @"");
    self.URLString = [URLString FU_stringByEnsuringURLSchemePrefix];
    [webView setMainFrameURL:URLString];
}


- (IBAction)zoomIn:(id)sender {
    if ([[FUUserDefaults instance] zoomTextOnly]) {
        [webView makeTextLarger:sender];
    } else {
        [webView zoomPageIn:sender];
    }
}


- (IBAction)zoomOut:(id)sender {
    if ([[FUUserDefaults instance] zoomTextOnly]) {
        [webView makeTextSmaller:sender];
    } else {
        [webView zoomPageOut:sender];
    }
}


- (IBAction)actualSize:(id)sender {
    if ([[FUUserDefaults instance] zoomTextOnly]) {
        [webView makeTextStandardSize:sender];
    } else {
        [webView resetPageZoom:sender];
    }
}


- (BOOL)canZoomIn {
    if ([[FUUserDefaults instance] zoomTextOnly]) {
        return [webView canMakeTextLarger];
    } else {
        return [webView canZoomPageIn];
    }
}


- (BOOL)canZoomOut {
    if ([[FUUserDefaults instance] zoomTextOnly]) {
        return [webView canMakeTextSmaller];
    } else {
        return [webView canZoomPageOut];
    }
}


- (BOOL)canActualSize {
    if ([[FUUserDefaults instance] zoomTextOnly]) {
        return [webView canMakeTextStandardSize];
    } else {
        return [webView canResetPageZoom];
    }
}


- (IBAction)openLinkInNewTabFromMenu:(id)sender {
    NSURLRequest *req = [NSURLRequest requestWithURL:[clickElementInfo objectForKey:WebElementLinkURLKey]];
    [[FUDocumentController instance] loadRequest:req destinationType:FUDestinationTypeTab];
    self.clickElementInfo = nil;
}


- (IBAction)openLinkInNewWindowFromMenu:(id)sender {
    NSURLRequest *req = [NSURLRequest requestWithURL:[clickElementInfo objectForKey:WebElementLinkURLKey]];
    [[FUDocumentController instance] loadRequest:req destinationType:FUDestinationTypeWindow];
    self.clickElementInfo = nil;
}


- (IBAction)openFrameInNewWindowFromMenu:(id)sender {
    WebFrame *frame = [clickElementInfo objectForKey:WebElementFrameKey];
    NSURLRequest *req = [NSURLRequest requestWithURL:[[[frame dataSource] mainResource] URL]];
    [[FUDocumentController instance] loadRequest:req destinationType:FUDestinationTypeWindow];
    self.clickElementInfo = nil;
}


- (IBAction)openImageInNewWindowFromMenu:(id)sender {
    NSURLRequest *req = [NSURLRequest requestWithURL:[clickElementInfo objectForKey:WebElementImageURLKey]];
    [[FUDocumentController instance] loadRequest:req destinationType:FUDestinationTypeWindow];
    self.clickElementInfo = nil;
}


- (IBAction)searchWebFromMenu:(id)sender {
    NSString *term = [self currentSelectionFromWebView];
    if (![term length]) {
        NSBeep();
        return;
    }
    
    NSString *s = [NSString stringWithFormat:FUDefaultWebSearchFormatString(), term];
    NSURLRequest *req = [NSURLRequest requestWithURL:[NSURL URLWithString:s]];
    [(FUDocumentController *)[FUDocumentController instance] loadRequest:req];
    self.clickElementInfo = nil;
}


- (IBAction)downloadLinkAsFromMenu:(id)sender {
    NSURL *URL = [clickElementInfo objectForKey:WebElementLinkURLKey];
    
    NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setCanCreateDirectories:YES];
    [savePanel setMessage:NSLocalizedString(@"Download Linked File As...", @"")];
    NSString *filename = [[URL absoluteString] lastPathComponent];
    
    [savePanel beginSheetForDirectory:nil 
                                 file:filename 
                       modalForWindow:[self.view window] 
                        modalDelegate:self didEndSelector:@selector(savePanelDidEnd:returnCode:contextInfo:) 
                          contextInfo:[URL retain]]; // retained
}


#pragma mark -
#pragma mark Public

- (NSView *)view {
    if (![self isViewLoaded]) {
        [self loadView];
    }
    return view;
}


- (void)loadView {
    if ([self isViewLoaded]) {
        return;
    }

    NSRect frame = NSMakeRect(0, 0, MAXFLOAT, MAXFLOAT);
    
    self.view = [[[FUView alloc] initWithFrame:frame] autorelease];
    [view setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    
    self.webView = [[[FUWebView alloc] initWithFrame:frame] autorelease];
    [webView setAutoresizingMask:NSViewWidthSizable|NSViewHeightSizable];
    
    [self setUpWebView];
    
    [view addSubview:webView];
}


- (BOOL)isViewLoaded {
    return nil != view;
}


- (void)loadRequest:(NSURLRequest *)req {
    [[webView mainFrame] loadRequest:req];
}


#pragma mark -
#pragma mark WebFrameLoadDelegate

- (void)webView:(WebView *)wv didStartProvisionalLoadForFrame:(WebFrame *)frame {
    if (frame != [webView mainFrame]) return;
    
    self.URLString = [[[[frame provisionalDataSource] request] URL] absoluteString];
    self.title = NSLocalizedString(@"Loading...", @"");
}


- (void)webView:(WebView *)wv didFailProvisionalLoadWithError:(NSError *)err forFrame:(WebFrame *)frame {
    if (frame != [webView mainFrame]) return;
    
    if (![self willRetryWithTLDAdded:wv]) {
        [self handleLoadFail:err];
    }
}


- (void)webView:(WebView *)wv didReceiveServerRedirectForProvisionalLoadForFrame:(WebFrame *)frame {
    if (frame != [webView mainFrame]) return;
    
    if (![initialURLString length]) {
        NSString *s = [[[[frame provisionalDataSource] request] URL] absoluteString];
        self.initialURLString = s;
    }
}


- (void)webView:(WebView *)wv didCommitLoadForFrame:(WebFrame *)frame {
    if (frame != [webView mainFrame]) return;
    
    didReceiveTitle = NO;
    
    NSString *s = [webView mainFrameURL];
    self.URLString = s;
    self.favicon = [self defaultFavicon];
    
    [[self.view window] makeFirstResponder:webView];

    [self postNotificationName:FUTabControllerDidCommitLoadNotification];
}


- (void)webView:(WebView *)wv didReceiveTitle:(NSString *)s forFrame:(WebFrame *)frame {
    if (frame != [webView mainFrame]) return;

    didReceiveTitle = YES;
    self.title = s;
}


- (void)webView:(WebView *)wv didReceiveIcon:(NSImage *)image forFrame:(WebFrame *)frame {
    if (frame != [webView mainFrame]) return;
    
    self.favicon = image;
}


- (void)webView:(WebView *)wv didFinishLoadForFrame:(WebFrame *)frame {
    if (frame != [webView mainFrame]) return;

    if (!didReceiveTitle) {
        self.title = URLString;
    }
    [self setValue:[NSNumber numberWithBool:YES] forKey:@"canReload"];
    [self postNotificationName:FUTabControllerDidFinishLoadNotification];
}


- (void)webView:(WebView *)wv didFailLoadWithError:(NSError *)err forFrame:(WebFrame *)frame {
    if (frame != [webView mainFrame]) return;

    [self handleLoadFail:err];
}


- (void)webView:(WebView *)wv didClearWindowObject:(WebScriptObject *)wso forFrame:(WebFrame *)frame {
    if (frame != [webView mainFrame]) return;

    [self postNotificationName:FUTabControllerDidClearWindowObjectNotification];
}


#pragma mark -
#pragma mark WebPolicyDelegate

- (void)webView:(WebView *)wv decidePolicyForNavigationAction:(NSDictionary *)info request:(NSURLRequest *)req frame:(WebFrame *)frame decisionListener:(id <WebPolicyDecisionListener>)listener {
    WebNavigationType navType = [[info objectForKey:WebActionNavigationTypeKey] integerValue];
    
    if (![self shouldHandleRequest:req]) {
        [listener ignore];
        return;
    }
    
    if ([WebView _canHandleRequest:req]) {
        FUActivation *act = [FUActivation activationFromWebActionInfo:info];
        if (act.isCommandKeyPressed) {
            [listener ignore];
            [windowController handleCommandClick:act request:req];
        } else {
            [listener use];
        }
    } else if (WebNavigationTypePlugInRequest == navType) {
        [listener use];
    } else {
        // A file URL shouldn't fall through to here, but if it did, it would be a security risk to open it.
        if (![[req URL] isFileURL]) {
            [[NSWorkspace sharedWorkspace] openURL:[req URL]];
        }
        [listener ignore];
    }
}


- (void)webView:(WebView *)wv decidePolicyForNewWindowAction:(NSDictionary *)info request:(NSURLRequest *)req newFrameName:(NSString *)name decisionListener:(id<WebPolicyDecisionListener>)listener {

    if (![self shouldHandleRequest:req]) {
        [listener ignore];
        return;
    }

    FUActivation *act = [FUActivation activationFromWebActionInfo:info];
    if (act.isCommandKeyPressed) {
        [listener ignore];
        [windowController handleCommandClick:act request:req];
    } else if ([[FUUserDefaults instance] targetedClicksCreateTabs]) {
        [[[FUDocumentController instance] frontWindowController] loadRequest:req inNewTabInForeground:YES];
    } else {
        // look for existing frame with this name. if found, use it
        FUTabController *tc = nil;
        WebFrame *existingFrame = [[FUDocumentController instance] findFrameNamed:name outTabController:&tc];
        
        if (existingFrame) {
            // found an existing frame with frameName. use it, and suppress new window creation
            [[tc.view window] makeKeyAndOrderFront:self];
            [[[FUDocumentController instance] frontWindowController] orderTabControllerFront:tc];

            [existingFrame loadRequest:req];
            [listener ignore];
        } else {
            // no existing frame for name. allow a new window to be created
            [listener use];
        }
    }
}


- (void)webView:(WebView *)wv decidePolicyForMIMEType:(NSString *)type request:(NSURLRequest *)req frame:(WebFrame *)frame decisionListener:(id <WebPolicyDecisionListener>)listener {
    id response = [[frame provisionalDataSource] response];
    
    if (response && [response respondsToSelector:@selector(allHeaderFields)]) {
        NSDictionary *headers = [response allHeaderFields];
        
        NSString *contentDisposition = [[headers objectForKey:@"Content-Disposition"] lowercaseString];
        if (contentDisposition && NSNotFound != [contentDisposition rangeOfString:@"attachment"].location) {
            if (![[[req URL] absoluteString] hasSuffix:@".user.js"]) { // don't download userscripts
                [listener download];
                return;
            }
        }
        
        NSString *contentType = [[headers objectForKey:@"Content-Type"] lowercaseString];
        if (contentType && NSNotFound != [contentType rangeOfString:@"application/octet-stream"].location) {
            [listener download];
            return;
        }
    }
    
    if ([[req URL] isFileURL]) {
        BOOL isDir = NO;
        [[NSFileManager defaultManager] fileExistsAtPath:[[req URL] path] isDirectory:&isDir];
        
        if (isDir) {
            [listener ignore];
        } else if ([WebView canShowMIMEType:type]) {
            [listener use];
        } else{
            [listener ignore];
        }
    } else if ([WebView canShowMIMEType:type]) {
        [listener use];
    } else {
        [listener download];
    }
}


- (void)webView:(WebView *)sender unableToImplementPolicyWithError:(NSError *)error frame:(WebFrame *)frame {
    NSLog(@"called unableToImplementPolicyWithError:%@ inFrame:%@", error, frame);
}


#pragma mark -
#pragma mark WebUIDelegate

- (WebView *)webView:(WebView *)wv createWebViewWithRequest:(NSURLRequest *)req {
    FUDestinationType type = [[FUUserDefaults instance] targetedClicksCreateTabs] ? FUDestinationTypeTab : FUDestinationTypeWindow;
    FUTabController *tc = [[FUDocumentController instance] loadRequest:req destinationType:type inForeground:YES]; // TODO this is supposed to be created offscreen in the background according to webkit docs
    return [tc webView];
}


- (void)webViewShow:(WebView *)wv {
    NSWindow *win = [wv window];
    FUWindowController *wc = [[[FUDocumentController instance] documentForWindow:win] windowController];
    
    [wc orderTabControllerFront:[wc tabControllerForWebView:wv]];
    [win makeKeyAndOrderFront:wv];
}


- (void)webViewClose:(WebView *)wv {
    FUTabController *tc = [windowController tabControllerForWebView:wv];
    [windowController removeTabController:tc];
}


- (void)webViewFocus:(WebView *)wv {
    FUTabController *tc = [windowController tabControllerForWebView:wv];
    [windowController orderTabControllerFront:tc];
}


- (NSResponder *)webViewFirstResponder:(WebView *)wv {
    return [[wv window] firstResponder];
}


- (void)webView:(WebView *)wv makeFirstResponder:(NSResponder *)responder {
    [[webView window] makeFirstResponder:responder];
}


- (void)webView:(WebView *)wv setStatusText:(NSString *)text {
    self.statusText = text;
}


- (NSString *)webViewStatusText:(WebView *)wv {
    return self.statusText;
}


- (BOOL)webViewAreToolbarsVisible:(WebView *)wv {
    return [[[wv window] toolbar] isVisible];
}


- (void)webView:(WebView *)wv setToolbarsVisible:(BOOL)visible {
    [[[wv window] toolbar] setVisible:visible];
}


- (BOOL)webViewIsStatusBarVisible:(WebView *)wv {
    return [[FUUserDefaults instance] statusBarShown];
}


- (void)webView:(WebView *)wv setStatusBarVisible:(BOOL)visible {
    [[FUUserDefaults instance] setStatusBarShown:visible];
}


- (BOOL)webViewIsResizable:(WebView *)wv {
    // TODO
    return YES;
}


- (void)webView:(WebView *)wv setResizable:(BOOL)resizable {
    // TODO
}


- (void)webView:(WebView *)wv setFrame:(NSRect)frame {
    windowController.suppressNextFrameStringSave = YES;
    [[windowController window] setFrame:frame display:YES];
}


- (NSRect)webViewFrame:(WebView *)wv {
    return [[wv window] frame];
}


- (void)webView:(WebView *)wv runJavaScriptAlertPanelWithMessage:(NSString *)msg initiatedByFrame:(WebFrame *)frame {
    NSRunInformationalAlertPanel(NSLocalizedString(@"JavaScript", @""),  // title
                                 msg,                                    // message
                                 NSLocalizedString(@"OK", @""),          // default button
                                 nil,                                    // alt button
                                 nil);                                   // other button    
}


- (BOOL)webView:(WebView *)wv runJavaScriptConfirmPanelWithMessage:(NSString *)msg initiatedByFrame:(WebFrame *)frame {
    NSInteger result = NSRunInformationalAlertPanel(NSLocalizedString(@"JavaScript", @""),  // title
                                                    msg,                                    // message
                                                    NSLocalizedString(@"OK", @""),          // default button
                                                    NSLocalizedString(@"Cancel", @""),      // alt button
                                                    nil);
    return NSAlertDefaultReturn == result;    
}


- (NSString *)webView:(WebView *)wv runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)text initiatedByFrame:(WebFrame *)frame {
    // TODO
    return nil;
}


- (BOOL)webView:(WebView *)wv runBeforeUnloadConfirmPanelWithMessage:(NSString *)msg initiatedByFrame:(WebFrame *)frame {
    NSInteger result = NSRunInformationalAlertPanel(NSLocalizedString(@"JavaScript", @""),  // title
                                                    msg,                                    // message
                                                    NSLocalizedString(@"OK", @""),          // default button
                                                    NSLocalizedString(@"Cancel", @""),      // alt button
                                                    nil);
    return NSAlertDefaultReturn == result;    
}


- (void)webView:(WebView *)wv runOpenPanelForFileButtonWithResultListener:(id <WebOpenPanelResultListener>)listener {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel beginSheetForDirectory:nil 
                                 file:nil 
                       modalForWindow:[self.view window]
                        modalDelegate:self
                       didEndSelector:@selector(openPanelDidEnd:returnCode:contextInfo:) 
                          contextInfo:[listener retain]];
}


- (NSArray *)webView:(WebView *)wv contextMenuItemsForElement:(NSDictionary *)info defaultMenuItems:(NSArray *)defaultItems {        
    self.clickElementInfo = info;
    NSMutableArray *items = [NSMutableArray arrayWithArray:defaultItems];
    id removeMe = nil;
    
    for (id item in items) {
        NSInteger t = [item tag];
        
        if (WebMenuItemTagOpenLinkInNewWindow == t) {
            [item setTarget:self];
            [item setAction:@selector(openLinkInNewWindowFromMenu:)];
        } else if (WebMenuItemTagOpenFrameInNewWindow == t) {
            [item setTarget:self];
            [item setAction:@selector(openFrameInNewWindowFromMenu:)];
        } else if (WebMenuItemTagOpenImageInNewWindow == t) {
            [item setTarget:self];
            [item setAction:@selector(openImageInNewWindowFromMenu:)];
        } else if (WebMenuItemTagSearchWeb == t) {
            [item setTarget:self];
            [item setAction:@selector(searchWebFromMenu:)];
        } else if ([NSLocalizedString(@"Open Link", @"") isEqualToString:[item title]]) {
            removeMe = item;
        }
    }
    
    if (removeMe) {
        [items removeObject:removeMe];
    }
    
    
    NSString *linkURLString = [[info objectForKey:WebElementLinkURLKey] absoluteString];
    if ([linkURLString length]) {
        
        BOOL tabbedBrowsingEnabled = [[FUUserDefaults instance] tabbedBrowsingEnabled];
        if (tabbedBrowsingEnabled) {
            NSMenuItem *openInNewTabItem = [[[NSMenuItem alloc] init] autorelease];
            [openInNewTabItem setTitle:NSLocalizedString(@"Open Link in New Tab", @"")];
            [openInNewTabItem setTarget:self];
            [openInNewTabItem setAction:@selector(openLinkInNewTabFromMenu:)];
            [items insertObject:openInNewTabItem atIndex:0];
        }
        
        [items insertObject:[NSMenuItem separatorItem] atIndex:2];
        
        NSMenuItem *downloadAsItem = [[[NSMenuItem alloc] init] autorelease];
        [downloadAsItem setTitle:NSLocalizedString(@"Download Linked File As...", @"")];
        [downloadAsItem setTarget:self];
        [downloadAsItem setAction:@selector(downloadLinkAsFromMenu:)];
        [self insertItem:downloadAsItem intoMenuItems:items afterItemWithTag:WebMenuItemTagDownloadLinkToDisk];
    }
    
    return items;
}


- (void)webView:(WebView *)wv mouseDidMoveOverElement:(NSDictionary *)info modifierFlags:(NSUInteger)flags {    
    self.hoverElementInfo = info;
    
    NSURL *URL = [info valueForKey:WebElementLinkURLKey];
    
    if (URL) {
        WebFrame *sourceFrame = [info valueForKey:WebElementFrameKey];
        WebFrame *targetFrame = [info valueForKey:WebElementLinkTargetFrameKey];
        DOMNode  *targetNode  = [info valueForKey:WebElementDOMNodeKey];
        DOMElement *anchorEl  = [targetNode FU_firstAncestorOrSelfByTagName:@"a"];
        NSString *targetStr   = [anchorEl getAttribute:@"target"];
        NSString *format = nil;
        
        if (sourceFrame != targetFrame) {
            if ([targetStr length] && ([targetStr isEqualToString:@"_new"] || [targetStr isEqualToString:@"_blank"])) {
                format = NSLocalizedString(@"Open \"%@\" in a new window", @"");
            } else {
                format = NSLocalizedString(@"Open \"%@\" in a new frame", @"");
            }
        } else if ([[URL scheme] hasPrefix:@"javascript"]) {
            format = NSLocalizedString(@"Run script \"%@\"", @"");
        } else {
            format = NSLocalizedString(@"Go to \"%@\"", @"");
        }
        
        self.statusText = [NSString stringWithFormat:format, [URL absoluteString]];
    } else {
        self.statusText = @"";
    }
}

#pragma mark -
#pragma mark WebProgressNotifications

- (void)webViewProgressStarted:(NSNotification *)n {
    [self setValue:[NSNumber numberWithBool:YES] forKey:@"isProcessing"];
    self.statusText = NSLocalizedString(@"Loading...", @"");
    [self postNotificationName:FUTabControllerProgressDidStartNotification];
}


- (void)webViewProgressEstimateChanged:(NSNotification *)n {
    if ([URLString length]) {
        self.statusText = [NSString stringWithFormat:NSLocalizedString(@"Loading \"%@\"", @""), URLString];
    } else {
        self.statusText = NSLocalizedString(@"Loading...", @"");
    }
    
    [self postNotificationName:FUTabControllerProgressDidChangeNotification];
}


- (void)webViewProgressFinished:(NSNotification *)n {
    [self setValue:[NSNumber numberWithBool:NO] forKey:@"isProcessing"];
    [self postNotificationName:FUTabControllerProgressDidFinishNotification];
    self.statusText = @"";
}


#pragma mark -
#pragma mark Private

- (void)setUpWebView {
    [webView setShouldCloseWithWindow:YES];
    [webView setMaintainsBackForwardList:YES];
    [webView setDrawsBackground:YES];
    [webView setPreferences:[FUWebPreferences instance]];
    
    // delegates
    [webView setResourceLoadDelegate:self];
    [webView setFrameLoadDelegate:self];
    [webView setPolicyDelegate:self];
    [webView setUIDelegate:self];
    [webView setDownloadDelegate:[FUDownloadWindowController instance]];

    BOOL spellCheckEnabled = [[FUUserDefaults instance] continuousSpellCheckingEnabled];
    [webView setContinuousSpellCheckingEnabled:spellCheckEnabled];
    
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(webViewProgressStarted:) name:WebViewProgressStartedNotification object:webView];
    [nc addObserver:self selector:@selector(webViewProgressEstimateChanged:) name:WebViewProgressEstimateChangedNotification object:webView];
    [nc addObserver:self selector:@selector(webViewProgressFinished:) name:WebViewProgressFinishedNotification object:webView];
}


- (BOOL)willRetryWithTLDAdded:(WebView *)wv {
    NSURL *URL = [NSURL URLWithString:[wv mainFrameURL]];
    NSString *host = [URL host];
    
    if (NSNotFound == [host rangeOfString:@"."].location) {
        self.URLString = [NSString stringWithFormat:@"%@.com", host];
        [self goToLocation:self];
        return YES;
    } else {
        return NO;
    }
}


- (void)handleLoadFail:(NSError *)err {
    [self postNotificationName:FUTabControllerDidFailLoadNotification];

    NSInteger code = [err code];
    
    // WebKitErrorPlugInWillHandleLoad 204
    if (NSURLErrorCancelled == code || WebKitErrorFrameLoadInterruptedByPolicyChange == code || 204 == code) {
        return;
    }
    
    self.lastLoadFailed = YES;
    
    [self setValue:[NSNumber numberWithBool:NO] forKey:@"isProcessing"];
    self.title = NSLocalizedString(@"Load Failed", @"");
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"LoadFailed" ofType:@"html"];
    NSString *source = [NSString stringWithContentsOfURL:[NSURL fileURLWithPath:path] encoding:NSUTF8StringEncoding error:nil];
    source = [NSString stringWithFormat:source, [err localizedDescription]];
    
    NSURL *failingURL = [[[[webView mainFrame] provisionalDataSource] initialRequest] URL];
    NSString *failingURLString = [failingURL absoluteString];
    
    [[webView mainFrame] loadAlternateHTMLString:source baseURL:nil forUnreachableURL:failingURL];
    [self performSelector:@selector(setURLString:) withObject:failingURLString afterDelay:0];
    
    [[FURecentURLController instance] removeRecentURL:failingURLString];
}


- (NSImage *)defaultFavicon {
    return [[WebIconDatabase sharedIconDatabase] FU_defaultFavicon];
}

                 
- (void)postNotificationName:(NSString *)name {
    [[NSNotificationCenter defaultCenter] postNotificationName:name object:self];
}


- (BOOL)shouldHandleRequest:(NSURLRequest *)req {
    return [[FUWhitelistController instance] processRequest:req];
}


- (BOOL)insertItem:(NSMenuItem *)item intoMenuItems:(NSMutableArray *)items afterItemWithTag:(NSInteger)tag {
    NSInteger i = [self indexOfItemWithTag:tag inMenuItems:items];
    if (NSNotFound == i) {
        [items addObject:item];
        return NO;
    } else {
        [items insertObject:item atIndex:i + 1];
        return YES;
    }
}


- (NSInteger)indexOfItemWithTag:(NSUInteger)tag inMenuItems:(NSArray *)items {
    NSInteger i = 0;
    for (NSMenuItem *item in items) {
        if ([item tag] == tag) return i; 
        i++;
    }
    return NSNotFound;
}


- (NSString *)currentSelectionFromWebView {
    DOMRange *r = [webView selectedDOMRange];
    return [r text];
}


- (void)openPanelDidEnd:(NSSavePanel *)openPanel returnCode:(NSInteger)code contextInfo:(id <WebOpenPanelResultListener>)listener {
    [listener autorelease]; // released

    if (NSOKButton == code) {
        [listener chooseFilename:[openPanel filename]];
    }
}


- (void)savePanelDidEnd:(NSSavePanel *)savePanel returnCode:(int)code contextInfo:(NSURL *)URL {
    [URL autorelease]; // released
    
    if (NSFileHandlingPanelCancelButton == code) {
        return;
    }
    
    NSURLRequest *req = [NSURLRequest requestWithURL:URL];
    
    FUDownloadWindowController *dc = [FUDownloadWindowController instance];
    
    [dc setNextDestinationDirPath:[[savePanel directory] stringByExpandingTildeInPath]];
    [dc setNextDestinationFilename:[[savePanel filename] lastPathComponent]];
    
    [[[NSURLDownload alloc] initWithRequest:req delegate:dc] autorelease]; // start
}

@synthesize windowController;
@synthesize view;
@synthesize webView;
@synthesize title;
@synthesize URLString;
@synthesize initialURLString;
@synthesize favicon;
@synthesize clickElementInfo;
@synthesize hoverElementInfo;
@synthesize statusText;
@synthesize lastLoadFailed;
@synthesize isProcessing;
@synthesize canReload;
@end
