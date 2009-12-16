//
//  WebIconDatabase+FUAdditions.h
//  Fluidium
//
//  Created by Todd Ditchendorf on 12/5/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import "WebKitPrivate.h"

@interface WebIconDatabase (FUAdditions)
- (NSImage *)FU_defaultFavicon;
- (NSImage *)FU_faviconForURL:(NSString *)s;
@end
