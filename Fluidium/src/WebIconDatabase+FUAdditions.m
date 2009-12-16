//
//  WebIconDatabase+FUAdditions.m
//  Fluidium
//
//  Created by Todd Ditchendorf on 12/5/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import "WebIconDatabase+FUAdditions.h"

@implementation WebIconDatabase (FUAdditions)

- (NSImage *)FU_defaultFavicon {
    return [self defaultIconWithSize:NSMakeSize(16, 16)];
}


- (NSImage *)FU_faviconForURL:(NSString *)s {
    return [self iconForURL:s withSize:NSMakeSize(16, 16)];
}

@end
