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

#import "FUPlugInPreferences.h"
#import "FUPlugInController.h"
#import "FUPlugInWrapper.h"

@implementation FUPlugInPreferences

- (id)init {
    if (self = [super init]) {
        [self observeValueForKeyPath:@"plugIn" ofObject:self change:nil context:NULL];
    }
    return self;
}


- (void)dealloc {
    self.contentView = nil;
    self.viewPlacementPopUpButton = nil;
    self.plugInWrapper = nil;
    [super dealloc];
}


- (IBAction)viewPlacementMenuItemAction:(id)sender {
    NSInteger tag = [sender selectedTag];
    NSInteger mask = (1 << tag);
    
    FUPlugInController *plugInManager = [FUPlugInController instance];
    
    [plugInManager hidePlugInWrapperInAllWindows:plugInWrapper];
    
    NSInteger oldMask = plugInWrapper.currentViewPlacementMask;
    if (FUPlugInViewPlacementIsPanel(oldMask)) {
        [plugInManager.windowsForPlugInIdentifier removeObjectForKey:plugInWrapper.identifier];
    }
    
    plugInWrapper.currentViewPlacementMask = mask;
    [plugInManager toggleVisibilityOfPlugInWrapper:plugInWrapper];
}


- (IBAction)changeFont:(id)sender {
    NSViewController *viewController = plugInWrapper.preferencesViewController;
    if ([viewController respondsToSelector:@selector(changeFont:)]) {
        [viewController changeFont:sender];
    }
    self.defaultsHaveChanged = YES;
}


- (void)updatePopUpMenu {
    NSInteger mask = plugInWrapper.currentViewPlacementMask;
    NSInteger tag;
    
    for (tag = 1; tag < 10; tag++) {
        if ((mask & (1 << tag))) {
            break;
        }
    }

    [viewPlacementPopUpButton selectItemWithTag:tag];
}


- (NSView *)contentView {
    return contentView;
}


- (NSPopUpButton *)viewPlacementPopUpButton {
    return viewPlacementPopUpButton;
}


- (BOOL)validateMenuItem:(NSMenuItem *)menuItem {
    NSInteger tag = [menuItem tag];
    NSUInteger mask = plugInWrapper.allowedViewPlacementMask;

//    NSLog(@"tag %d, mask: %d, result:%d", tag, mask, (mask&(1 << tag)));
    return ((NSInteger)(mask & (1 << tag))) > 0;
}


- (void)valuesHaveChanged {
    [super valuesHaveChanged];
    [self updateUI];
    
    NSViewController *viewController = plugInWrapper.preferencesViewController;
    if ([viewController respondsToSelector:@selector(updateUI)]) {
        [viewController performSelector:@selector(updateUI)];
    }
}

@synthesize contentView;
@synthesize viewPlacementPopUpButton;
@synthesize plugInWrapper;
@end
