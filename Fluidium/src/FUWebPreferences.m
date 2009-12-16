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

#import "FUWebPreferences.h"
#import "FUUserDefaults.h"

NSString * FUWebPreferencesDidChangeNotification = @"FUWebPreferencesDidChangeNotification";

@implementation FUWebPreferences

+ (id)instance {
    static FUWebPreferences *instance = nil;
    @synchronized (self) {
        if (!instance) {
            instance = [[FUWebPreferences alloc] initWithIdentifier:@"FUWebPreferences"];
        }
    }  
    return instance;
}


- (id)initWithIdentifier:(NSString *)s {
    if (self = [super initWithIdentifier:s]) {
        
        NSInteger i = [[FUUserDefaults instance] cookieAcceptPolicy];
        [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookieAcceptPolicy:i];
        
        // on first run, set WebKit default fonts
        if (![[NSUserDefaults standardUserDefaults] objectForKey:kFUStandardFontFamilyKey]) {
            [self setStandardFontFamily:[super standardFontFamily]];
            [self setDefaultFontSize:[super defaultFontSize]];
            [self setFixedFontFamily:[super fixedFontFamily]];
            [self setDefaultFixedFontSize:[super defaultFixedFontSize]];
        }
        
        [self setAllowsAnimatedImages:YES];
        [self setAllowsAnimatedImageLooping:YES];
        
        [self setCacheModel:WebCacheModelPrimaryWebBrowser];
        [self setAutosaves:YES];
        [self setPrivateBrowsingEnabled:NO];
        [self setShouldPrintBackgrounds:NO];
        [self setTabsToLinks:NO];
        [self setUsesPageCache:YES];

        [self setUserStyleSheetEnabled:NO];
        //[self setUserStyleSheetLocation:nil];
    }
    return self;
}


- (void)postDidChangeNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:FUWebPreferencesDidChangeNotification object:self];
}


- (BOOL)isJavaScriptEnabled {
    return [[FUUserDefaults instance] javaScriptEnabled];
}


- (void)setJavaScriptEnabled:(BOOL)yn {
    [super setJavaScriptEnabled:yn];
    [[FUUserDefaults instance] setJavaScriptEnabled:yn];
}


- (BOOL)javaScriptCanOpenWindowsAutomatically {
    return [[FUUserDefaults instance] javaScriptCanOpenWindowsAutomatically];
}


- (void)setJavaScriptCanOpenWindowsAutomatically:(BOOL)yn {
    [super setJavaScriptCanOpenWindowsAutomatically:yn];
    [[FUUserDefaults instance] setJavaScriptCanOpenWindowsAutomatically:yn];
}


- (BOOL)isJavaEnabled {
    return [[FUUserDefaults instance] javaEnabled];
}


- (void)setJavaEnabled:(BOOL)yn {
    [super setJavaEnabled:yn];
    [[FUUserDefaults instance] setJavaEnabled:yn];
}


- (BOOL)arePlugInsEnabled {
    return [[FUUserDefaults instance] plugInsEnabled];
}


- (void)setPlugInsEnabled:(BOOL)yn {
    [super setPlugInsEnabled:yn];
    [[FUUserDefaults instance] setPlugInsEnabled:yn];
}


- (BOOL)loadsImagesAutomatically {
    return [[FUUserDefaults instance] loadsImagesAutomatically];
}


- (void)setLoadsImagesAutomatically:(BOOL)yn {
    [[FUUserDefaults instance] setLoadsImagesAutomatically:yn];
}


- (NSString *)standardFontFamily {
    return [[FUUserDefaults instance] standardFontFamily];
}


- (void)setStandardFontFamily:(NSString *)s {
    [super setStandardFontFamily:s];
    [[FUUserDefaults instance] setStandardFontFamily:s];
}


- (int)defaultFontSize {
    return [[FUUserDefaults instance] defaultFontSize];
}


- (void)setDefaultFontSize:(int)i {
    [super setDefaultFontSize:i];
    [[FUUserDefaults instance] setDefaultFontSize:i];
}


- (NSString *)fixedFontFamily {
    return [[FUUserDefaults instance] fixedFontFamily];
}


- (void)setFixedFontFamily:(NSString *)s {
    [super setFixedFontFamily:s];
    [[FUUserDefaults instance] setFixedFontFamily:s];
}


- (int)defaultFixedFontSize {
    return [[FUUserDefaults instance] defaultFixedFontSize];
}


- (void)setDefaultFixedFontSize:(int)i {
    [super setDefaultFixedFontSize:i];
    [[FUUserDefaults instance] setDefaultFixedFontSize:i];
}

@end
