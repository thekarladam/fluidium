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

#import "FUBar.h"

@class FUBookmarkBarButton;
@class FUBookmarkButtonSeparator;
@class FUBookmarkBarOverflowButton;

@interface FUBookmarkBar : FUBar {
    FUBookmarkButtonSeparator *separator;
    NSMutableArray *buttons;
    NSInteger currDropIndex;

    FUBookmarkBarOverflowButton *overflowButton;
    NSMenu *overflowMenu;
    NSInteger visibleButtonCount;
    
    FUBookmarkBarButton *draggingButton;
}

- (void)addButtonForItem:(id)item;
- (void)addItem:(id)item;
- (void)startedDraggingButton:(FUBookmarkBarButton *)button;

@property (nonatomic, retain) FUBookmarkButtonSeparator *separator;
@property (nonatomic, retain) NSMutableArray *buttons;
@property (nonatomic, retain) FUBookmarkBarOverflowButton *overflowButton;
@property (nonatomic, retain) NSMenu *overflowMenu;
@property (nonatomic, retain) FUBookmarkBarButton *draggingButton;
@end
