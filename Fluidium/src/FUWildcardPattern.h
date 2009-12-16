/*
 * Copyright (c) 2006 KATO Kazuyoshi <kzys@8-p.info>
 * This source code is released under the MIT license.
 */

#import <Cocoa/Cocoa.h>
#include <regex.h>

@interface FUWildcardPattern : NSObject {
    NSString *string;
    regex_t pattern;
}

+ (id)patternWithString:(NSString *)s;

- (id)initWithString:(NSString *)s;
- (BOOL)isMatch:(NSString *)s;

@property (nonatomic, copy) NSString *string;
@end
