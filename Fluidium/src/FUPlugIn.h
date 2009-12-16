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

// Notification names
extern NSString *const FUPlugInViewControllerWillAppearNotifcation;
extern NSString *const FUPlugInViewControllerDidAppearNotifcation;
extern NSString *const FUPlugInViewControllerWillDisappearNotifcation;
extern NSString *const FUPlugInViewControllerDidDisappearNotifcation;

// keys for the userInfo dictionary of Notifications sent with names from above
extern NSString *const FUPlugInCurrentViewPlacementMaskKey; // NSInteger
extern NSString *const FUPlugInKey;                         // id <FUPlugIn>
extern NSString *const FUPlugInViewControllerKey;           // NSViewController
extern NSString *const FUPlugInViewControllerDrawerKey;     // NSDrawer -- this is only sent for view controllers currently in a drawer position

#define FUPlugInViewPlacementIsSplitView(mask)  ((mask) == FUPlugInViewPlacementSplitViewBottomMask || (mask) == FUPlugInViewPlacementSplitViewLeftMask || (mask) == FUPlugInViewPlacementSplitViewRightMask || (mask) == FUPlugInViewPlacementSplitViewTopMask)
#define FUPlugInViewPlacementIsPanel(mask)  ((mask) == FUPlugInViewPlacementUtilityPanelMask || (mask) == FUPlugInViewPlacementFloatingUtilityPanelMask || (mask) == FUPlugInViewPlacementHUDPanelMask || (mask) == FUPlugInViewPlacementFloatingHUDPanelMask)
#define FUPlugInViewPlacementIsDrawer(mask)  ((mask) == FUPlugInViewPlacementDrawerMask)

@protocol FUPlugInAPI;

typedef enum {
    FUPlugInViewPlacementDrawerMask = 1 << 1,
    FUPlugInViewPlacementUtilityPanelMask = 1 << 2,
    FUPlugInViewPlacementFloatingUtilityPanelMask = 1 << 3,
    FUPlugInViewPlacementHUDPanelMask = 1 << 4,
    FUPlugInViewPlacementFloatingHUDPanelMask = 1 << 5,
    FUPlugInViewPlacementSplitViewBottomMask = 1 << 6,
    FUPlugInViewPlacementSplitViewLeftMask = 1 << 7,
    FUPlugInViewPlacementSplitViewRightMask = 1 << 8,
    FUPlugInViewPlacementSplitViewTopMask = 1 << 9,
} FUPlugInViewPlacementMask;

// note that your impl of this protocol will be registered (by the Fluid SSB) for the four PlugInViewController notifications below
// your impl will also be registered (by the Fluid SSB) for all NSWindow Notifications on the window with which it is associated, if it responds to the appropriate callback selectors
// you can implement the NSWindowNotification callback methods if you like. they will be called if you do.
@protocol FUPlugIn <NSObject>

// the plugInController is this plugin's API back to the Fluid SSB application.
- (id)initWithPlugInAPI:(id <FUPlugInAPI>)api;

// Create a new NSViewController to display your plugin in a new window. Subsequent calls should always return a new object.
// The returned object should have a retain count of at least 1, and is 'owned' by the caller from a memory management perspective.
// Fluid will release it when its window is destroyed.
// This may be called multiple times - once for every window in which the user views your plugin.
- (NSViewController *)newPlugInViewController;

// return the single NSViewController which will control the 'Preferences' view that will appear in the Fluid Preferences window.
// only one should ever be created. you should probably create it lazily in your implementation of this method.
// returned object should be autoreleased.
- (NSViewController *)preferencesViewController;

// unique reverse domain. e.g.: com.fluidapp.FoobarPlugIn
- (NSString *)identifier;

// the display string title for this plugin. do not include 'Plug-in' in this string. Just the name of this plugin
// e.g.: 'Clipboard' rather than 'Clipboard Plug-in'.
- (NSString *)localizedTitle;

// an or'ed mask containing the UI placements allowed for this plugin
- (NSInteger)allowedViewPlacementMask;

// a single UI placement maks stating where this plugin should appear by default
- (NSInteger)preferredViewPlacementMask;

// a string that will be used as the 'keyboard shortcut' in the main menu item for this plugin
- (NSString *)preferredMenuItemKeyEquivalent;

// an or'd mask of modifiers to be usind in the keyboard shortcut in the main menu item for this plugin
// e.g.: (NSControlKeyMask|NSAlternateKeyMask|NSCommandKeyMask)
- (NSUInteger)preferredMenuItemKeyEquivalentModifierMask;

// a string matching the filename of an image in this plugin bundle's Resources dir.
// this string should not include the file extension.
- (NSString *)toolbarIconImageName;

// a string matching the filename of an image in this plugin bundle's Resources dir.
// this string should not include the file extension.
- (NSString *)preferencesIconImageName;

// values in this dictionary will be added to NSUserDefaults for the currently running SSB.
// the keys in this dictionary should be carefully namespaced
- (NSDictionary *)defaultsDictionary;

// a dictionary containing the standard keys and values provided as the 'options' arg to:
// -[NSApplication orderFrontStandardAboutPanelWithOptions:]. See Apple's documentation for that method.
- (NSDictionary *)aboutInfoDictionary;

@optional
- (CGFloat)preferredVerticalSplitPosition;
- (CGFloat)preferredHorizontalSplitPosition;
- (NSInteger)preferredToolbarButtonType;
@end

@interface NSObject (FUPlugInNotifications)
- (void)plugInViewControllerWillAppear:(NSNotification *)notification;
- (void)plugInViewControllerDidAppear:(NSNotification *)notification;
- (void)plugInViewControllerWillDisappear:(NSNotification *)notification;
- (void)plugInViewControllerDidDisappear:(NSNotification *)notification;
@end