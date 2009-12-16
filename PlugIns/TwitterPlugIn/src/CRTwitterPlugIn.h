//
//  CRTwitterPlugIn.h
//  TwitterPlugIn
//
//  Created by Todd Ditchendorf on 10/11/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "FUPlugIn.h"

@class CRTwitterPlugInViewController;
@class CRTwitterPlugInPrefsViewController;

extern NSString *kCRTwitterDisplayUsernamesKey;
extern NSString *kCRTwitterAccountIDsKey;
extern NSString *kCRTwitterSelectNewTabsAndWindowsKey;

extern NSString *CRTwitterPlugInSelectedUsernameDidChangeNotification;

@interface CRTwitterPlugIn : NSObject <FUPlugIn> {
    id <FUPlugInAPI>plugInAPI; // weakref
    NSMutableArray *viewControllers;

	CRTwitterPlugInPrefsViewController *preferencesViewController;
	NSString *identifier;
	NSString *localizedTitle;
	NSInteger allowedViewPlacementMask;
	NSInteger preferredViewPlacementMask;
	NSString *preferredMenuItemKeyEquivalent;
	NSUInteger preferredMenuItemKeyEquivalentModifierMask;
	NSString *toolbarIconImageName;
	NSString *preferencesIconImageName;
	NSDictionary *defaultsDictionary;
	NSDictionary *aboutInfoDictionary;
	CGFloat preferredVerticalSplitPosition;
	CGFloat preferredHorizontalSplitPosition;
    
    CRTwitterPlugInViewController *frontViewController;
    
    NSString *selectedUsername;
}
+ (id)instance;

- (void)showPrefs:(id)sender;

// prefs
- (BOOL)tabbedBrowsingEnabled;
- (BOOL)selectNewWindowsOrTabsAsCreated;

- (void)openURLString:(NSString *)s;
- (void)openURL:(NSURL *)URL;
- (void)openURLWithArgs:(NSDictionary *)args;

- (void)openURL:(NSURL *)URL inNewTabInForeground:(BOOL)inBackground;
- (void)openURL:(NSURL *)URL inNewWindowInForeground:(BOOL)inBackground;

- (void)showStatusText:(NSString *)s;

- (NSArray *)usernames;
- (NSString *)passwordFor:(NSString *)username;

- (BOOL)wasCommandKeyPressed:(NSInteger)modifierFlags;
- (BOOL)wasShiftKeyPressed:(NSInteger)modifierFlags;
- (BOOL)wasOptionKeyPressed:(NSInteger)modifierFlags;

@property (nonatomic, assign) id <FUPlugInAPI>plugInAPI;
@property (nonatomic, assign) CRTwitterPlugInViewController *frontViewController;
@property (nonatomic, copy) NSString *selectedUsername;
@end
