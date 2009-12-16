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

#import "FUWhitelistController.h"
#import "FUUserDefaults.h"
#import "FUWildcardPattern.h"

#define MIN_INF_LOOP_DELAY .5

@interface FUWhitelistController ()
- (void)homeURLStringDidChange:(NSNotification *)n;
- (void)loadSpecialCases;
@end

@implementation FUWhitelistController

+ (id)instance {
    static FUWhitelistController *instance = nil;
    @synchronized (self) {
        if (!instance) {
            instance = [[FUWhitelistController alloc] init];
        }
    }
    return instance;
}


- (id)init {
    if (self = [super init]) {
        [self loadURLPatterns];
        [self loadSpecialCases];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(homeURLStringDidChange:) name:FUHomeURLStringDidChangeNotification object:nil];
    }
    return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.URLPatternStrings = nil;
    self.URLPatterns = nil;
    self.specialCaseURLPatterns = nil;
    self.lastDate = nil;
    self.lastURLString = nil;
    [super dealloc];
}


- (void)save {
    [[FUUserDefaults instance] setWhitelistURLPatternStrings:URLPatternStrings];
    [[NSUserDefaults standardUserDefaults] synchronize];
}


- (void)loadURLPatterns {
    self.URLPatternStrings = [NSMutableArray arrayWithArray:[[FUUserDefaults instance] whitelistURLPatternStrings]];
    self.URLPatterns = [NSMutableArray arrayWithCapacity:[URLPatternStrings count]];
    for (NSDictionary *d in URLPatternStrings) {
        NSString *patternString = [d objectForKey:@"value"];
        [URLPatterns addObject:[FUWildcardPattern patternWithString:patternString]];
    }    
}


- (BOOL)processRequest:(NSURLRequest *)req {
    if (!req) return YES; // req wil be nil for javascript popups. always allow here. popup blocking prefs handled by WebPreferences
    
    if ([self isRequestWhitelisted:req]) {
        return YES;
    } else {
        NSString *URLString = [[req URL] absoluteString];
        
        // detect infinite loops
        BOOL isInfiniteLoop = [lastDate timeIntervalSinceNow] < MIN_INF_LOOP_DELAY && [URLString isEqualToString:lastURLString];
        if (isInfiniteLoop) {
            NSRunAlertPanel(NSLocalizedString(@"Infinite Loop Detected", @""), 
                            NSLocalizedString(@"This SSB is set as your default browser, but you have disallowed browsing to %@", @""),
                            NSLocalizedString(@"OK", @""),
                            nil,
                            nil,
                            URLString);
        } else {
            self.lastURLString = URLString;
            self.lastDate = [NSDate date];
            
            [self makeSystemHandleRequest:req];
        }

        return NO;
    }
}


- (BOOL)isRequestWhitelisted:(NSURLRequest *)req {
    if ([[FUUserDefaults instance] allowBrowsingToAnyDomain]) {
        return YES;
    } else {
        NSString *URLString = [[req URL] absoluteString];

        if ([URLString hasPrefix:@"about:"] || [URLString hasPrefix:@"javascript:"]) {
            return YES;
        }

        BOOL isAllowed = NO;
        BOOL invert = [[FUUserDefaults instance] invertWhitelist];
        
        for (FUWildcardPattern *pat in URLPatterns) {
            isAllowed = [pat isMatch:URLString];
            if (isAllowed) break;
        }
        
        // only apply invert to user-specified url patterns. (not special cases)
        isAllowed = invert ? !isAllowed : isAllowed;

        if (!isAllowed) {
            for (FUWildcardPattern *pat in specialCaseURLPatterns) {
                isAllowed = [pat isMatch:URLString];
                if (isAllowed) break;
            }
        }
        
        return isAllowed;
    }
}


- (void)makeSystemHandleRequest:(NSURLRequest *)req {
    [[NSWorkspace sharedWorkspace] openURL:[req URL]];
    if ([[FUUserDefaults instance] linksSentToOtherApplicationsOpenInBackground]) {
        [NSApp activateIgnoringOtherApps:YES];
    }
}


- (void)loadSpecialCases {
    self.specialCaseURLPatterns = [NSMutableArray array];
    NSString *path = [[NSBundle mainBundle] pathForResource:@"SpecialCases" ofType:@"plist"];
    NSDictionary *d = [NSDictionary dictionaryWithContentsOfFile:path];
    
    NSString *homeURLString = [[FUUserDefaults instance] homeURLString];
    for (NSString *URLStringKey in d) {
        BOOL isMatch = [homeURLString rangeOfString:URLStringKey].location != NSNotFound;
        if (isMatch) {
            for (NSString *URLPatternStr in [d objectForKey:URLStringKey]) {
                FUWildcardPattern *pat = [FUWildcardPattern patternWithString:URLPatternStr];
                [specialCaseURLPatterns addObject:pat];
            }
        }
    }
}


#pragma mark -
#pragma mark Notifications

- (void)homeURLStringDidChange:(NSNotification *)n {
    [self loadSpecialCases];
}

@synthesize URLPatternStrings;
@synthesize URLPatterns;
@synthesize specialCaseURLPatterns;
@synthesize lastDate;
@synthesize lastURLString;
@end
