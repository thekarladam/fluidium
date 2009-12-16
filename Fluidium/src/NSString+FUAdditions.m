//
//  NSString+FUAdditions.m
//  Fluidium
//
//  Created by Todd Ditchendorf on 6/12/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import "NSString+FUAdditions.h"
#import "FUUtils.h"

@implementation NSString (FUAdditions)

- (NSString *)FU_stringByEnsuringURLSchemePrefix {
    if (![self FU_hasSupportedSchemePrefix]) {
        return [NSString stringWithFormat:@"%@%@", kFUHTTPSchemePrefix, self];
    }
    return self;
}


- (NSString *)FU_stringByTrimmingURLSchemePrefix {
    NSString *s = [[self copy] autorelease];
    
    if ([s hasPrefix:kFUHTTPSchemePrefix]) {
        s = [s substringFromIndex:[kFUHTTPSchemePrefix length]];
    } else if ([s hasPrefix:kFUHTTPSSchemePrefix]) {
        s = [s substringFromIndex:[kFUHTTPSSchemePrefix length]];
    } else if ([s hasPrefix:kFUFileSchemePrefix]) {
        s = [s substringFromIndex:[kFUFileSchemePrefix length]];
    }
 
    return s;
}


- (BOOL)FU_hasHTTPSchemePrefix {
    return [self hasPrefix:kFUHTTPSchemePrefix] || [self hasPrefix:kFUHTTPSSchemePrefix];
}


- (BOOL)FU_hasSupportedSchemePrefix {
    return [self FU_hasHTTPSchemePrefix] 
        || [self hasPrefix:kFUFileSchemePrefix] 
        || [self hasPrefix:@"about:"] 
        || [self hasPrefix:@"data:"] 
        || [self hasPrefix:@"file:"] 
        || [self hasPrefix:@"javascript:"];
}

@end
