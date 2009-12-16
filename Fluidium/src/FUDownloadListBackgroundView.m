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

#import "FUDownloadListBackgroundView.h"

#define ROW_HEIGHT 66

@implementation FUDownloadListBackgroundView

- (BOOL)isFlipped {
    return YES;
}


- (void)drawRect:(NSRect)rect {
    NSArray *colors = [NSColor controlAlternatingRowBackgroundColors];
    
    NSInteger i = 0;
    CGFloat totalHeight = 0;
    for ( ; totalHeight < rect.size.height + ROW_HEIGHT; totalHeight += ROW_HEIGHT, i++) {
        NSColor *color = nil;
        color = [colors objectAtIndex:i % 2];
        [color set];
        NSRectFill(NSMakeRect(0, totalHeight, rect.size.width, ROW_HEIGHT));
    }
}

@end
