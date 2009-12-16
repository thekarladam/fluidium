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

#import <Cocoa/Cocoa.h>

@protocol FUPlugIn;

@interface FUPlugInWrapper : NSObject {
    id <FUPlugIn>plugIn;
    NSMutableDictionary *viewControllers;
    NSMutableSet *visibleWindowNumbers;
    NSString *currentViewPlacementMaskKey;
}

- (id)initWithPlugIn:(id <FUPlugIn>)aPlugIn;

- (NSViewController *)plugInViewControllerForWindowNumber:(NSInteger)num;
- (NSViewController *)newViewControllerForWindowNumber:(NSInteger)num;

- (BOOL)isVisibleInWindowNumber:(NSInteger)num;
- (void)setVisible:(BOOL)visible inWindowNumber:(NSInteger)num;

@property (nonatomic, retain, readonly) id <FUPlugIn> plugIn;
@property (nonatomic) NSInteger currentViewPlacementMask;
@property (nonatomic, copy, readonly) NSString *currentViewPlacementMaskKey;
@property (nonatomic, retain) NSMutableDictionary *viewControllers;

@property (nonatomic, readonly) NSViewController *preferencesViewController;
@property (nonatomic, readonly) NSString *identifier;
@property (nonatomic, readonly) NSString *localizedTitle;
@property (nonatomic, readonly) NSInteger allowedViewPlacementMask;
@property (nonatomic, readonly) NSInteger preferredViewPlacementMask;
@property (nonatomic, readonly) NSString *preferredMenuItemKeyEquivalent;
@property (nonatomic, readonly) NSUInteger preferredMenuItemKeyEquivalentModifierMask;
@property (nonatomic, readonly) NSString *toolbarIconImageName;
@property (nonatomic, readonly) NSString *preferencesIconImageName;
@property (nonatomic, readonly) NSDictionary *defaultsDictionary;
@property (nonatomic, readonly) NSDictionary *aboutInfoDictionary;
@property (nonatomic, readonly) CGFloat preferredVerticalSplitPosition;
@property (nonatomic, readonly) CGFloat preferredHorizontalSplitPosition;
@property (nonatomic, readonly) NSInteger preferredToolbarButtonType;
@end
