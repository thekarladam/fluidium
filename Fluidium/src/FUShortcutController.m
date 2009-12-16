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

#import "FUShortcutController.h"
#import "FUShortcutCommand.h"
#import "FUUserDefaults.h"
#import <ParseKit/ParseKit.h>

@interface FUShortcutCommand ()
@property (nonatomic, retain, readwrite) NSArray *moreURLStrings;
@property (nonatomic, copy, readwrite) NSString *firstURLString;
@property (nonatomic, readwrite) NSUInteger count;
@property (nonatomic, readwrite, getter=isTabbed) BOOL tabbed;
@property (nonatomic, readwrite, getter=isPiped) BOOL piped;
@end

@interface FUShortcutController ()
- (NSString *)replacementStringForshortcutKey:(NSString *)shortcutKey;
- (NSString *)replacementFormatForshortcutKey:(NSString *)shortcutKey isIndexed:(BOOL *)outIndexed;
- (NSArray *)shortcuts;

- (NSString *)URLStringWithFormat:(NSString *)fmt query:(NSString *)q;
- (NSString *)URLStringWithFormat:(NSString *)fmt queryTokens:(NSArray *)toks;
@end

@implementation FUShortcutController

- (FUShortcutCommand *)commandForInput:(NSString *)commandString {
    NSMutableArray *URLStrings = [NSMutableArray array];

    // fetch non-parameterized replacement (e.g. 'g' for "http://google.com")
    NSString *replacementString = [self replacementStringForshortcutKey:commandString];
    NSString *query = nil;
    

    // fetch parameterized replacement (e.g. 'g xxx' for "http://google.com/q=%@")
    BOOL isIndexed = NO;
    if (![replacementString length]) {
        NSRange r = [commandString rangeOfString:@" "];
        if (NSNotFound == r.location) {
            return nil;
        }
        
        NSInteger index = r.location;
        NSString *shortcutKey = [commandString substringToIndex:index];
        
        replacementString = [self replacementFormatForshortcutKey:shortcutKey isIndexed:&isIndexed];
        if ([commandString length] > index + 1) {
            query = [commandString substringFromIndex:index+1];
        }
    }

    BOOL isTabbed = NO;
    BOOL isPiped = NO;
    
    if ([replacementString length]) {
        // ??
        //replacementString = [replacementString stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
        //
        isTabbed = (NSNotFound != [replacementString rangeOfString:@","].location);
        isPiped = (NSNotFound != [replacementString rangeOfString:@"|"].location);
        
        NSMutableArray *toks = nil;
        if (isIndexed) {
            toks = [NSMutableArray array];
            PKTokenizer *t = [PKTokenizer tokenizerWithString:query];
            PKToken *eof = [PKToken EOFToken];
            PKToken *tok = nil;
            while ((tok = [t nextToken]) != eof) {
                [toks addObject:tok];
            }
        }
        
        if (isTabbed || isPiped) {
            NSArray *replacementStrings = [replacementString componentsSeparatedByString:(isPiped ? @"|" : @",")];
            
            for (NSString *fmt in replacementStrings) {
                if (isIndexed) {
                    [URLStrings addObject:[self URLStringWithFormat:fmt queryTokens:toks]];
                } else {
                    [URLStrings addObject:[self URLStringWithFormat:fmt query:query]];
                }
            }
        } else {
            if (isIndexed) {
                [URLStrings addObject:[self URLStringWithFormat:replacementString queryTokens:toks]];
            } else {
                [URLStrings addObject:[self URLStringWithFormat:replacementString query:query]];
            }
        }
    }
    
    if (![URLStrings count]) {
        return nil;
    }

    FUShortcutCommand *cmd = [[[FUShortcutCommand alloc] init] autorelease];
    cmd.firstURLString = [URLStrings objectAtIndex:0];
    cmd.tabbed = isTabbed;
    cmd.piped = isPiped;
    
    if ([URLStrings count] > 1) {
        cmd.moreURLStrings = [URLStrings subarrayWithRange:NSMakeRange(1, [URLStrings count] - 1)];
    }
    return cmd;
}


- (NSString *)URLStringWithFormat:(NSString *)fmt queryTokens:(NSArray *)toks {
    NSMutableString *mfmt = [[fmt mutableCopy] autorelease];
    CFStringTrimWhitespace((CFMutableStringRef)mfmt);
    
    NSString *result = nil;
    
    if ([toks count]) {
        NSInteger i = 1;
        for (PKToken *tok in toks) {
            NSString *s = [NSString stringWithFormat:@"$%d", i++];
            if (NSNotFound != [fmt rangeOfString:s].location) {
                [mfmt replaceOccurrencesOfString:s
                                      withString:[tok stringValue]
                                         options:0
                                           range:NSMakeRange(0, [mfmt length])];
                result = mfmt;
                break;
            }
        }
        
    } else {
        result = mfmt;
    }
    
    return result;
}


- (NSString *)URLStringWithFormat:(NSString *)fmt query:(NSString *)q {
    NSMutableString *mfmt = [[fmt mutableCopy] autorelease];
    CFStringTrimWhitespace((CFMutableStringRef)mfmt);
    
    NSString *result = nil;

    if ([q length]) {
        result = [NSString stringWithFormat:mfmt, q];
    } else {
        result = mfmt;
    }

    return result;
}


- (NSString *)replacementStringForshortcutKey:(NSString *)shortcutKey {
    NSString *result = nil;
    
    for (NSDictionary *shortcut in [self shortcuts]) {
        if ([[shortcut objectForKey:@"shortcut"] isEqualToString:shortcutKey]) {
            result = [shortcut objectForKey:@"replacement"];
            break;
        }
    }
    
    return result;
}


- (NSString *)replacementFormatForshortcutKey:(NSString *)shortcutKey isIndexed:(BOOL *)outIndexed {
    NSString *result = nil;
    
    for (NSDictionary *shortcut in [self shortcuts]) {
        if ([[shortcut objectForKey:@"shortcut"] isEqualToString:shortcutKey]) {
            NSString *s = [shortcut objectForKey:@"replacement"];
            if (NSNotFound != [s rangeOfString:@"%@"].location) {
                result = s;
                (*outIndexed) = NO;
                break;
            } else if  (NSNotFound != [s rangeOfString:@"$1"].location) {
                result = s;
                (*outIndexed) = YES;
                break;
            }
        }
    }
    
    return result;
}


- (NSArray *)shortcuts {
    NSArray *shortcuts = [[FUUserDefaults instance] shortcuts];
    if (![shortcuts count]) {
        NSString *path = [[NSBundle mainBundle] pathForResource:@"Shortcuts" ofType:@"plist"];
        NSDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:path];
        shortcuts = [dict objectForKey:@"FUShortcuts"];
    }
    return shortcuts;
}

@end
