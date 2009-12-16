//
//  NSImage+FUAdditions.h
//  Fluidium
//
//  Created by Todd Ditchendorf on 12/5/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSImage (FUAdditions)
- (NSImage *)FU_scaledImageOfSize:(NSSize)size;
@end
