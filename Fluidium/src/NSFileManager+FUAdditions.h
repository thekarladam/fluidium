//
//  NSFileManager+FUAdditions.h
//  Fluidium
//
//  Created by Todd Ditchendorf on 12/11/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSFileManager (FUAdditions)
- (NSArray *)FU_directoryContentsAtPath:(NSString *)path havingExtension:(NSString *)extension error:(NSError **)outError;
@end
