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

#import "FURecentURLController.h"
#import "FUUserDefaults.h"
#import "NSString+FUAdditions.h"

#define URL_LIMIT 800

@interface FURecentURLController () 
- (void)addBaseURLForURLString:(NSString *)URLString;
- (void)checkForOverTheLimit;
@end

@implementation FURecentURLController

+ (id)instance {
    static FURecentURLController *instance = nil;
    @synchronized (self) {
        if (!instance) {
            instance = [[FURecentURLController alloc] init];
        }
    }
    return instance;
}


- (id)init {    
    if (self = [super init]) {
        [self resetRecentURLs];
        
        NSArray *storedURLs = [[FUUserDefaults instance] recentURLStrings];
        [recentURLs addObjectsFromArray:storedURLs];
        
        [self resetMatchingRecentURLs];
    }
    return self;
}


- (void)dealloc {
    self.recentURLs = nil;
    self.matchingRecentURLs = nil;
    [super dealloc];
}


#pragma mark -
#pragma mark Public

- (void)resetRecentURLs {
    self.recentURLs = [NSMutableArray arrayWithCapacity:URL_LIMIT + 1];
}


- (void)resetMatchingRecentURLs {
    self.matchingRecentURLs = [NSMutableArray array];
}


- (void)addRecentURL:(NSString *)URLString {
    if ([URLString length]) {
        
        BOOL hasDot = NSNotFound != [URLString rangeOfString:@"."].location;
        BOOL hasSpace = NSNotFound != [URLString rangeOfString:@" "].location;
        if (!hasDot && !hasSpace) {
            return;
        }
        
        // remove fragments
        NSInteger i = [URLString rangeOfString:@"#"].location;
        if (NSNotFound != i) { 
            URLString = [URLString substringToIndex:i];
        }
        
        // cannonicalize the url by removing trailing slash (prevents a lot of dupes that differ only by trailing slash)
        if ([URLString hasSuffix:@"/"]) { 
            URLString = [URLString substringToIndex:[URLString length] - 1];
        }
        
        // remove leading http:// or https://
        URLString = [URLString FU_stringByTrimmingURLSchemePrefix];
        
        // remove leading www.
        NSString *prefix = @"www.";
        if ([URLString hasPrefix:prefix]) URLString = [URLString substringFromIndex:[prefix length]];
        
        //NSLog(@"will add if not present: %@", URLString);
        if (![recentURLs containsObject:URLString]) {
            [self checkForOverTheLimit];
            //NSLog(@"adding: %@", URLString);
            [recentURLs addObject:URLString];
            [self addBaseURLForURLString:URLString];
        }
    }
}


- (void)addBaseURLForURLString:(NSString *)URLString {
    NSInteger i = [URLString rangeOfString:@"/"].location;
    if (NSNotFound == i) return;
    
    URLString = [URLString substringToIndex:i];
    if ([URLString length]) {
        //NSLog(@"adding baseURL: %@", URLString);
        [self addRecentURL:URLString];
    }
}


- (void)checkForOverTheLimit {
    if (recentURLs.count > URL_LIMIT) {
        //NSLog(@"over the limit!!!!");
        NSInteger i = 0;
        for ( ; i < 30; i++) {
            //NSLog(@"evicting: %@", [recentURLs objectAtIndex:0]);
            [recentURLs removeObjectAtIndex:0];
        }
    }
}


- (void)removeRecentURL:(NSString *)URLString {
    if ([URLString length]) {
        [recentURLs removeObject:URLString];
    }
}


- (void)addMatchingRecentURL:(NSString *)URLString {
    if ([URLString length] && ![matchingRecentURLs containsObject:URLString]) {
        [matchingRecentURLs addObject:URLString];
        [matchingRecentURLs sortUsingSelector:@selector(caseInsensitiveCompare:)];
    }
}


- (void)save {
    [[FUUserDefaults instance] setRecentURLStrings:recentURLs];
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@synthesize recentURLs;
@synthesize matchingRecentURLs;
@end
