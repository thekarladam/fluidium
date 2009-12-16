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

#import "FUDownloadListButton.h"
#import "FUDownloadListButtonCell.h"
#import "NSImage+FUAdditions.h"

#define STOP_PROGRESS_BUTTON_TAG 2

@implementation FUDownloadListButton

+ (Class)cellClass {
    return [FUDownloadListButtonCell class];
}


- (void)dealloc {
    [super dealloc];
}


- (void)awakeFromNib {
    if (STOP_PROGRESS_BUTTON_TAG == [self tag]) { // stop progress button needs to be resized. its too big.
        NSImage *img = [NSImage imageNamed:NSImageNameStopProgressFreestandingTemplate];
        [self setImage:[img FU_scaledImageOfSize:NSMakeSize(14, 14)]];
    }
    [self setShowsBorderOnlyWhileMouseInside:YES];
}

@end
