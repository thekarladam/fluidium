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

@class FUDocument;
@class FUWindowController;
@class FUTabController;
@class WebView;
@class WebFrame;

typedef enum {
    FUDestinationTypeWindow,
    FUDestinationTypeTab
} FUDestinationType;

extern NSString *const FUTabBarShownDidChangeNotification;
extern NSString *const FUTabBarHiddenForSingleTabDidChangeNotification;
extern NSString *const FUBookmarkBarShownDidChangeNotification;
extern NSString *const FUStatusBarShownDidChangeNotification;

@interface FUDocumentController : NSDocumentController {
    NSWindow *hiddenWindow;
}

+ (id)instance;

- (IBAction)toggleTabBarShown:(id)sender;
- (IBAction)toggleBookmarkBarShown:(id)sender;
- (IBAction)toggleStatusBarShown:(id)sender;

- (IBAction)addNewTabInForeground:(id)sender;


- (FUDocument *)openDocumentWithRequest:(NSURLRequest *)req makeKey:(BOOL)makeKey;

- (FUTabController *)loadRequest:(NSURLRequest *)req; // prefers tabs
- (FUTabController *)loadRequest:(NSURLRequest *)req destinationType:(FUDestinationType)type; // respects FUSelectNewWindowsOrTabsAsCreated
- (FUTabController *)loadRequest:(NSURLRequest *)req destinationType:(FUDestinationType)type inForeground:(BOOL)inForeground;

- (FUTabController *)loadHTMLString:(NSString *)s; // prefers tabs
- (FUTabController *)loadHTMLString:(NSString *)s destinationType:(FUDestinationType)type; // respects FUSelectNewWindowsOrTabsAsCreated
- (FUTabController *)loadHTMLString:(NSString *)s destinationType:(FUDestinationType)type inForeground:(BOOL)inForeground;

- (WebFrame *)findFrameNamed:(NSString *)name outTabController:(FUTabController **)outTabController;

- (FUDocument *)frontDocument;
- (FUWindowController *)frontWindowController;
- (FUTabController *)frontTabController;
- (WebView *)frontWebView;

@property (nonatomic, assign) NSWindow *hiddenWindow; // weak ref
@end
