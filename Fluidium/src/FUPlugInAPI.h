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
@protocol FUPlugIn;

typedef enum {
    FUPlugInDestinationTypeWindow,
    FUPlugInDestinationTypeTab
} FUPlugInDestinationType;

@protocol FUPlugInAPI
- (NSString *)version;
- (WebView *)frontWebView;
- (NSArray *)webViews;
- (NSString *)plugInSupportDirPath;

- (void)loadRequest:(NSURLRequest *)request destinationType:(FUPlugInDestinationType)type inForeground:(BOOL)inForeground; // FUDestinationType
- (void)loadHTMLString:(NSString *)htmlString destinationType:(FUPlugInDestinationType)type inForeground:(BOOL)inForeground; // FUDestinationType

- (void)showStatusText:(NSString *)statusText;

- (void)showPreferencePaneForIdentifier:(NSString *)s;
@end
