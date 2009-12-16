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

#import <Cocoa/Cocoa.h>

@class WebView;
@class TDUberView;
@class PSMTabBarControl;
@class FUViewSourceWindowController;
@class FUTabController;
@class FUProgressComboBox;
@class FUShortcutController;

extern NSString *const FUWindowControllerDidOpenNotification;
extern NSString *const FUWindowControllerWillCloseNotification;

extern NSString *const FUWindowControllerDidOpenTabNotification;
extern NSString *const FUWindowControllerWillCloseTabNotification;
extern NSString *const FUWindowControllerDidChangeSelectedTabNotification;

extern NSString *const FUTabControllerKey;

@interface NSObject (FUWindowControllerNotifications)
- (void)windowControllerDidOpen:(NSNotification *)n;
- (void)windowControllerWillClose:(NSNotification *)n;

- (void)windowControllerDidOpenTab:(NSNotification *)n;
- (void)windowControllerWillCloseTab:(NSNotification *)n;
- (void)windowControllerDidChangeSelectedTab:(NSNotification *)n;
@end

@interface FUWindowController : NSWindowController {
    IBOutlet NSSplitView *locationSplitView;
    IBOutlet FUProgressComboBox *locationComboBox;
    IBOutlet NSSearchField *searchField;
    
    IBOutlet NSView *tabContainerView;
    IBOutlet PSMTabBarControl *tabBar;
    IBOutlet NSView *bookmarkBar;
    IBOutlet TDUberView *uberView;
    IBOutlet NSView *statusBar;
    IBOutlet NSTextField *statusTextField;
    
    IBOutlet NSView *findPanelView;
    IBOutlet NSSearchField *findPanelSearchField;
    NSTabView *tabView;
    FUTabController *departingTabController;
 
    BOOL typingInFindPanel;
    NSString *findTerm;
    
    FUViewSourceWindowController *viewSourceController;
    FUShortcutController *shortcutController;

    NSMutableSet *tabControllers;
    FUTabController *selectedTabController;
    
    NSString *currentTitle;
    
    BOOL suppressNextFrameStringSave;
    BOOL displayingMatchingRecentURLs;
    
    NSInteger closingSelectedTabIndex;    
}

- (IBAction)goBack:(id)sender;
- (IBAction)goForward:(id)sender;
- (IBAction)reload:(id)sender;
- (IBAction)stopLoading:(id)sender;
- (IBAction)goHome:(id)sender;

- (IBAction)zoomIn:(id)sender;
- (IBAction)zoomOut:(id)sender;
- (IBAction)actualSize:(id)sender;

- (IBAction)goToLocation:(id)sender;
- (IBAction)openLocation:(id)sender;
- (IBAction)search:(id)sender;
- (IBAction)openSearch:(id)sender;

- (IBAction)viewSource:(id)sender;
- (IBAction)emptyCache:(id)sender;
- (IBAction)toggleToolbarShown:(id)sender;

- (IBAction)addNewTabInForeground:(id)sender;
- (IBAction)addNewTabInBackground:(id)sender;
- (IBAction)closeTab:(id)sender;
- (IBAction)performClose:(id)sender;
- (IBAction)selectNextTab:(id)sender;
- (IBAction)selectPreviousTab:(id)sender;

- (IBAction)showFindPanel:(id)sender;
- (IBAction)hideFindPanel:(id)sender;
- (IBAction)find:(id)sender;
- (IBAction)useSelectionForFind:(id)sender;
- (IBAction)jumpToSelection:(id)sender;

- (IBAction)addBookmark:(id)sender;
- (IBAction)bookmarkClicked:(id)sender;

- (FUTabController *)loadRequestInSelectedTab:(NSURLRequest *)req;
- (FUTabController *)loadRequestInLastTab:(NSURLRequest *)req;
- (FUTabController *)loadRequest:(NSURLRequest *)req inNewTabInForeground:(BOOL)inForeground;

- (FUTabController *)lastTabController;
- (FUTabController *)tabControllerAtIndex:(NSInteger)i;
- (FUTabController *)tabControllerForWebView:(WebView *)wv;

- (void)orderTabControllerFront:(FUTabController *)tc;
- (BOOL)removeTabController:(FUTabController *)tc;

- (BOOL)isFindPanelVisible;

@property (nonatomic) NSInteger selectedTabIndex;

@property (nonatomic, retain) IBOutlet NSSplitView *locationSplitView;
@property (nonatomic, retain) IBOutlet FUProgressComboBox *locationComboBox;
@property (nonatomic, retain) IBOutlet NSSearchField *searchField;
@property (nonatomic, retain) IBOutlet NSView *tabContainerView;
@property (nonatomic, retain) IBOutlet PSMTabBarControl *tabBar;
@property (nonatomic, retain) IBOutlet NSView *bookmarkBar;
@property (nonatomic, retain) IBOutlet TDUberView *uberView;
@property (nonatomic, retain) IBOutlet NSView *statusBar;
@property (nonatomic, retain) IBOutlet NSTextField *statusTextField;
@property (nonatomic, retain) IBOutlet NSView *findPanelView;
@property (nonatomic, retain) IBOutlet NSSearchField *findPanelSearchField;
@property (nonatomic, retain) NSTabView *tabView;
@property (nonatomic, assign) FUTabController *departingTabController; // weak ref
@property (nonatomic, retain) FUViewSourceWindowController *viewSourceController;
@property (nonatomic, retain) FUShortcutController *shortcutController;
@property (nonatomic, retain) NSMutableSet *tabControllers;
@property (nonatomic, retain) FUTabController *selectedTabController;
@property (nonatomic, copy) NSString *currentTitle;
@property (nonatomic, copy) NSString *findTerm;

@property (nonatomic) BOOL suppressNextFrameStringSave;
@end
