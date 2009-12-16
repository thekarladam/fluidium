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

#import "FUUserstyleController.h"
#import "FUWindowController.h"
#import "FUTabController.h"
#import "FUWebView.h"
#import "FUApplication.h"
#import "FUWildcardPattern.h"
#import <WebKit/WebKit.h>

@interface FUUserstyleController ()
- (void)loadUserstyles;
- (NSString *)newUUIDString;
- (NSString *)userstyleSourceForURLString:(NSString *)URLString;
- (void)setUserstyleToDefault:(WebPreferences *)webPreferences;
- (WebPreferences *)copyPreferences:(WebPreferences *)oldPreferences;
@end

@implementation FUUserstyleController

+ (id)instance {
    static FUUserstyleController *instance = nil;
    @synchronized (self) {
        if (!instance) {
            instance = [[FUUserstyleController alloc] init];
        }
    }
    return instance;
}


- (id)init {
    if (self = [super init]) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"default" ofType:@"css"];
        self.defaultCSSURL = [NSURL fileURLWithPath:path];
        self.defaultCSSText = [NSString stringWithContentsOfURL:defaultCSSURL encoding:NSUTF8StringEncoding error:nil];
        
        [self loadUserstyles];
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(tabControllerDidCommitLoad:)
                                                     name:FUTabControllerDidCommitLoadNotification 
                                                   object:nil];
    }
    return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.userstyles = nil;
    self.defaultCSSURL = nil;
    self.tempCSSURL = nil;
    self.tempCSSPath = nil;
    self.defaultCSSText = nil;
    [super dealloc];
}


#pragma mark -
#pragma mark Public

- (void)save {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    [dict setObject:[NSArray arrayWithArray:userstyles] forKey:@"FUUserstyles"];
    NSURL *furl = [NSURL fileURLWithPath:[[FUApplication instance] userstyleFilePath]];
    [dict writeToURL:furl atomically:YES];    
}


#pragma mark -
#pragma mark Notifications

- (void)tabControllerDidCommitLoad:(NSNotification *)n {
    FUTabController *tc = [[n userInfo] objectForKey:FUTabControllerKey];
    WebView *wv = [tc webView];
    WebPreferences *oldPrefs = [wv preferences];
    
    NSString *userstyleSrc = [self userstyleSourceForURLString:[wv mainFrameURL]];
    
    if (![userstyleSrc length]) {
        [self setUserstyleToDefault:oldPrefs];
        return;
    }
    
    WebPreferences *newPrefs = [[self copyPreferences:oldPrefs] autorelease];

    userstyleSrc = [NSString stringWithFormat:@"%@%@", defaultCSSText, userstyleSrc];
    
    NSString *appName = [[FUApplication instance] appName];
    NSString *uid = [[self newUUIDString] autorelease];
    NSArray *tmpPathComps = [NSArray arrayWithObjects:NSTemporaryDirectory(), [NSString stringWithFormat:@"%@-%@", appName, uid], nil];
    self.tempCSSPath = [[NSString pathWithComponents:tmpPathComps] stringByAppendingPathExtension:@"css"];
    self.tempCSSURL = [NSURL fileURLWithPath:tempCSSPath];
    
    NSError *err = nil;
    if ([userstyleSrc writeToFile:tempCSSPath atomically:YES encoding:NSUTF8StringEncoding error:&err]) {
        [newPrefs setUserStyleSheetEnabled:YES];
        [newPrefs setUserStyleSheetLocation:tempCSSURL];
    } else {
        NSLog(@"%@", err);
        [self setUserstyleToDefault:newPrefs];
    }
    
    [wv setPreferences:newPrefs];
}


#pragma mark -
#pragma mark Private

- (void)loadUserstyles {
    NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:[[FUApplication instance] userstyleFilePath]];
    self.userstyles = [NSMutableArray arrayWithArray:[dict objectForKey:@"FUUserstyles"]];
}


- (NSString *)newUUIDString {
    CFUUIDRef uuid = CFUUIDCreate(kCFAllocatorDefault);
    NSString *s = (NSString *)CFUUIDCreateString(kCFAllocatorDefault, uuid);
    CFRelease(uuid);
    return s;
}


- (void)setUserstyleToDefault:(WebPreferences *)webPreferences {
    if (defaultCSSURL) {
        [webPreferences setUserStyleSheetEnabled:YES];
        [webPreferences setUserStyleSheetLocation:defaultCSSURL];
    } else {
        [webPreferences setUserStyleSheetEnabled:NO];
        [webPreferences setUserStyleSheetLocation:nil];
    }    
}


static NSInteger FUSortMatchedUserstyles(NSDictionary *a, NSDictionary *b, void *ctx) {
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


- (NSString *)userstyleSourceForURLString:(NSString *)URLString {
    if (![userstyles count]) return nil;
    
    NSMutableArray *matchedUserstyles = [NSMutableArray array];
    
    for (id userstyleDict in userstyles) {
        FUWildcardPattern *pattern = [FUWildcardPattern patternWithString:[userstyleDict objectForKey:@"URLPattern"]];
        if ([pattern isMatch:URLString]) {
            if ([[userstyleDict objectForKey:@"enabled"] boolValue]) {
                [matchedUserstyles addObject:userstyleDict];
            }
        }
    }
    
    if ([matchedUserstyles count]) {
        [matchedUserstyles sortUsingFunction:FUSortMatchedUserstyles context:NULL];
        return [[matchedUserstyles objectAtIndex:0] objectForKey:@"source"];
    } else {
        return nil;
    }
}


- (WebPreferences *)copyPreferences:(WebPreferences *)oldPreferences {
    WebPreferences *newPreferences = [[WebPreferences alloc] init];
    [newPreferences setStandardFontFamily:[oldPreferences standardFontFamily]];
    [newPreferences setFixedFontFamily:[oldPreferences fixedFontFamily]];
    [newPreferences setSerifFontFamily:[oldPreferences serifFontFamily]];
    [newPreferences setSansSerifFontFamily:[oldPreferences sansSerifFontFamily]];
    [newPreferences setCursiveFontFamily:[oldPreferences cursiveFontFamily]];
    [newPreferences setFantasyFontFamily:[oldPreferences fantasyFontFamily]];
    [newPreferences setDefaultFontSize:[oldPreferences defaultFontSize]];
    [newPreferences setDefaultFixedFontSize:[oldPreferences defaultFixedFontSize]];
    [newPreferences setMinimumFontSize:[oldPreferences minimumFontSize]];
    [newPreferences setMinimumLogicalFontSize:[oldPreferences minimumLogicalFontSize]];
    [newPreferences setDefaultTextEncodingName:[oldPreferences defaultTextEncodingName]];
    [newPreferences setJavaEnabled:[oldPreferences isJavaEnabled]];
    [newPreferences setJavaScriptEnabled:[oldPreferences isJavaScriptEnabled]];
    [newPreferences setJavaScriptCanOpenWindowsAutomatically:[oldPreferences javaScriptCanOpenWindowsAutomatically]];
    [newPreferences setPlugInsEnabled:[oldPreferences arePlugInsEnabled]];
    [newPreferences setAllowsAnimatedImages:[oldPreferences allowsAnimatedImages]];
    [newPreferences setAllowsAnimatedImageLooping:[oldPreferences allowsAnimatedImageLooping]];
    [newPreferences setLoadsImagesAutomatically:[oldPreferences loadsImagesAutomatically]];
    [newPreferences setAutosaves:[oldPreferences autosaves]];
    [newPreferences setShouldPrintBackgrounds:[oldPreferences shouldPrintBackgrounds]];
    [newPreferences setPrivateBrowsingEnabled:[oldPreferences privateBrowsingEnabled]];
    [newPreferences setTabsToLinks:[oldPreferences tabsToLinks]];
    [newPreferences setUsesPageCache:[oldPreferences usesPageCache]];
    [newPreferences setCacheModel:[oldPreferences cacheModel]];
    return newPreferences;
}

@synthesize userstyles;
@synthesize defaultCSSURL;
@synthesize tempCSSURL;
@synthesize tempCSSPath;
@synthesize defaultCSSText;
@end
