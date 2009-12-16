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

#import "FUUserscriptController.h"
#import "FUWindowController.h"
#import "FUTabController.h"
#import "FUWebView.h"
#import "FUApplication.h"
#import "FUWildcardPattern.h"
#import <WebKit/WebKit.h>

#define KEY_USERSCRIPT_SRC @"userscriptSrc"
#define KEY_TABCONTROLLER @"tabController"
#define KEY_COUNT @"count"

#define MAX_TRIES 5

#define IS_JS_UNDEF(obj) ([(obj) isKindOfClass:[WebUndefined class]])

@interface FUUserscriptController ()
- (void)loadUserscripts;
- (NSString *)userscriptSourceForURLString:(NSString *)URLString;
- (void)tryToExecuteUserscript:(NSMutableDictionary *)args;
- (void)executeUserscript:(NSString *)userscriptSrc inWebView:(WebView *)wv;
@end

@implementation FUUserscriptController

+ (id)instance {
    static FUUserscriptController *instance = nil;
    @synchronized (self) {
        if (!instance) {
            instance = [[FUUserscriptController alloc] init];
        }
    }
    return instance;
}


- (id)init {
    if (self = [super init]) {
        [self loadUserscripts];
        
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(tabControllerDidClearWindowObject:) name:FUTabControllerDidClearWindowObjectNotification object:nil];
    }
    return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    self.userscripts = nil;
    [super dealloc];
}


#pragma mark -
#pragma mark Public

- (void)save {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:[NSArray arrayWithArray:userscripts] forKey:@"FUUserscripts"];
    NSURL *furl = [NSURL fileURLWithPath:[[FUApplication instance] userscriptFilePath]];
    [dict writeToURL:furl atomically:YES];    
}


#pragma mark -
#pragma mark Notifications

- (void)tabControllerDidClearWindowObject:(NSNotification *)n {
    FUTabController *tc = [[n userInfo] objectForKey:FUTabControllerKey];
    WebView *wv = [tc webView];
    NSString *userscriptSrc = [self userscriptSourceForURLString:[wv mainFrameURL]];
    
    if (![userscriptSrc length]) {
        return;
    }
    
    // don't use a format string. this is safer
    NSMutableString *ms = [NSMutableString stringWithString:@"(function (document) {\n"];
    [ms appendString:userscriptSrc];
    [ms appendString:@"\n});"];
    
    userscriptSrc = [[ms copy] autorelease];
    
    NSMutableDictionary *args = [NSMutableDictionary dictionaryWithObjectsAndKeys:
                                 userscriptSrc, KEY_USERSCRIPT_SRC,
                                 [n object], KEY_TABCONTROLLER,
                                 [NSNumber numberWithInteger:0], KEY_COUNT,
                                 nil];

    [self performSelector:@selector(tryToExecuteUserscript:) withObject:args afterDelay:0];
}


#pragma mark -
#pragma mark Private

- (void)loadUserscripts {
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:[[FUApplication instance] userscriptFilePath]];
    self.userscripts = [NSMutableArray arrayWithArray:[dict objectForKey:@"FUUserscripts"]];
}


static NSInteger FUSortMatchedUserscripts(NSDictionary *a, NSDictionary *b, void *ctx) {
    NSInteger lenA = [(NSString *)[a objectForKey:@"URLPattern"] length];
    NSInteger lenB = [(NSString *)[b objectForKey:@"URLPattern"] length];
    
    if (lenA > lenB) {
        return NSOrderedAscending;
    } else if (lenB > lenA) {
        return NSOrderedDescending;
    } else {
        return NSOrderedSame;
    }
}


- (NSString *)userscriptSourceForURLString:(NSString *)URLString {
    if (![userscripts count] || ![URLString length]) return nil;
    
    NSMutableArray *matchedUserscripts = [NSMutableArray array];
    
    for (id userscriptDict in userscripts) {
        FUWildcardPattern *pattern = [FUWildcardPattern patternWithString:[userscriptDict objectForKey:@"URLPattern"]];
        if ([pattern isMatch:URLString]) {
            if ([[userscriptDict objectForKey:@"enabled"] boolValue]) {
                [matchedUserscripts addObject:userscriptDict];
            }
        }
    }
    
    if ([matchedUserscripts count]) {
        [matchedUserscripts sortUsingFunction:FUSortMatchedUserscripts context:NULL];
        return [[matchedUserscripts objectAtIndex:0] objectForKey:@"source"];
    } else {
        return nil;
    }
}


- (void)tryToExecuteUserscript:(NSMutableDictionary *)args {
    WebView *wv = [[args objectForKey:KEY_TABCONTROLLER] webView];
    
    NSString *readyState = [[wv mainFrameDocument] valueForKey:@"readyState"];
    if ([readyState isEqualToString:@"loaded"] || [readyState isEqualToString:@"complete"]) {

        [self executeUserscript:[args objectForKey:KEY_USERSCRIPT_SRC] inWebView:wv];

    } else {
        NSInteger count = [[args objectForKey:KEY_COUNT] integerValue];
        //NSLog(@"tried %d times to run userscript for URL: %@", count, [wv mainFrameURL]);
        if (count < MAX_TRIES) {
            [args setObject:[NSNumber numberWithInteger:++count] forKey:KEY_COUNT];
            [self performSelector:@selector(tryToExecuteUserscript:) withObject:args afterDelay:0.3];
        } else {
            NSLog(@"maxed out trying to run userscript for URL: %@", [wv mainFrameURL]);
        }
    }
}


- (void)executeUserscript:(NSString *)userscriptSrc inWebView:(WebView *)wv {
    WebScriptObject *func = [[wv windowScriptObject] evaluateWebScript:userscriptSrc];
    if (!func || IS_JS_UNDEF(func)) {
        return;
    }
    
    WebScriptObject *jsThis = [func evaluateWebScript:@"this"];
    if (!jsThis || IS_JS_UNDEF(jsThis)) {
        return;
    } else {
        DOMDocument *doc = [wv mainFrameDocument];
        [func callWebScriptMethod:@"call" withArguments:[NSArray arrayWithObjects:jsThis, doc, nil]];
    }
}

@synthesize userscripts;
@end
