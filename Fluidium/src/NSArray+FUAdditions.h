//
//  NSArray+FUAdditions.h
//  Fluidium
//
//  Created by Todd Ditchendorf on 6/12/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSArray (FUAdditions)
- (NSMutableArray *)FU_reversedMutableArray;
- (NSArray *)FU_reversedArray;
@end
