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

#import "FUPlugIn.h"

@class FUPlugInWrapper;
@protocol FUPlugInAPI;

@interface FUPlugInController : NSObject {
    NSMenu *plugInMenu;
    NSMutableDictionary *windowsForPlugInIdentifier;
    id <FUPlugInAPI>plugInAPI;
    NSMutableArray *plugInWrappers;
    NSMutableArray *allPlugInIdentifiers;
    BOOL plugInsLoaded;
}

+ (id)instance;

- (void)plugInAboutMenuItemAction:(id)sender;
- (void)plugInMenuItemAction:(id)sender;

- (void)loadPlugIns;
- (void)createMenuItemsForPlugIns;
- (void)toggleVisibilityOfPlugInWrapper:(FUPlugInWrapper *)wrap;
- (void)toggleVisibilityOfPlugInWrapper:(FUPlugInWrapper *)wrap inWindow:(NSWindow *)window;

- (void)showPlugInWrapper:(FUPlugInWrapper *)wrap inWindow:(NSWindow *)window;
- (void)hidePlugInWrapperWithViewPlacementMask:(FUPlugInViewPlacementMask)mask inWindow:(NSWindow *)window;
- (void)hidePlugInWrapperInAllWindows:(FUPlugInWrapper *)wrap;

- (NSArray *)visiblePlugInWrappers;

- (FUPlugInWrapper *)plugInWrapperForIdentifier:(NSString *)identifier;

@property (nonatomic, retain) NSMenu *plugInMenu;
@property (nonatomic, retain) id <FUPlugInAPI>plugInAPI;
@property (nonatomic, retain) NSMutableArray *plugInWrappers;
@property (nonatomic, retain) NSMutableArray *allPlugInIdentifiers;
@property (nonatomic, retain) NSMutableDictionary *windowsForPlugInIdentifier;
@end
