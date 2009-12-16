//
//  NSString+FUAdditions.h
//  Fluidium
//
//  Created by Todd Ditchendorf on 6/12/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSString (FUAdditions)
- (NSString *)FU_stringByEnsuringURLSchemePrefix;
- (NSString *)FU_stringByTrimmingURLSchemePrefix;
- (BOOL)FU_hasHTTPSchemePrefix;
- (BOOL)FU_hasSupportedSchemePrefix;
@end
