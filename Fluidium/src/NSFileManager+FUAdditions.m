//
//  NSFileManager+FUAdditions.m
//  Fluidium
//
//  Created by Todd Ditchendorf on 12/11/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import "NSFileManager+FUAdditions.h"

@implementation NSFileManager (FUAdditions)

- (NSArray *)FU_directoryContentsAtPath:(NSString *)path havingExtension:(NSString *)extension error:(NSError **)outError {
    NSError *error = nil;
    NSArray *children = [self contentsOfDirectoryAtPath:path error:&error];
    if (!children) {
        if (outError) {
            *outError = error;
        }
        return nil;
    }
    
    NSMutableArray *filteredChildren = [NSMutableArray array];
    for (NSString *child in children) {
        if ([[child pathExtension] isEqualToString:extension])
            [filteredChildren addObject:child];
    }
    
    return filteredChildren;
}

@end
