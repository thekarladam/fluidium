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

extern NSString *const FUHomeURLStringDidChangeNotification;

// Browser
extern NSString *const kFUWebIconDatabaseDirectoryDefaultsKey;
extern NSString *const kFURecentURLStringsKey;
extern NSString *const kFUUserAgentStringKey;

// WebKit
extern NSString *const kFUContinuousSpellCheckingEnabledKey;
extern NSString *const kFUZoomTextOnlyKey;

// UI
extern NSString *const kFUBookmarkBarShownKey;
extern NSString *const kFUStatusBarShownKey;
extern NSString *const kFUTabBarHiddenAlwaysKey;
extern NSString *const kFUWindowFrameStringKey;
extern NSString *const kFUWindowScreenIndexKey;

// General Prefs
extern NSString *const kFUNewWindowsOpenWithKey;
extern NSString *const kFUHomeURLStringKey;
extern NSString *const kFUDownloadDirPathKey;
extern NSString *const kFUGlobalShortcutKeyComboCodeKey;
extern NSString *const kFUGlobalShortcutKeyComboFlagsKey;
extern NSString *const kFULoadsImagesAutomaticallyKey;

// Appearance Prefs
extern NSString *const kFUStandardFontFamilyKey;
extern NSString *const kFUDefaultFontSizeKey;
extern NSString *const kFUFixedFontFamilyKey;
extern NSString *const kFUDefaultFixedFontSizeKey;    

// Behavior Prefs
extern NSString *const kFUSpacesBehaviorKey;
extern NSString *const kFUTargetedClicksCreateTabsKey;
extern NSString *const kFULinksSentToOtherApplicationsOpenInBackgroundKey;
extern NSString *const kFUOpenLinksFromApplicationsInKey;
extern NSString *const kFUHideLastClosedWindowKey;
extern NSString *const kFUSessionsEnabledKey;
extern NSString *const kFUSessionInfoKey;

// Tabs Prefs
extern NSString *const kFUTabbedBrowsingEnabledKey;
extern NSString *const kFUSelectNewWindowsOrTabsAsCreatedKey;
extern NSString *const kFUConfirmBeforeClosingMultipleTabsOrWindowsKey;
extern NSString *const kFUTabBarHiddenForSingleTabKey;
extern NSString *const kFUTabBarCellOptimumWidthKey;

// Security Prefs
extern NSString *const kFUPlugInsEnabledKey;
extern NSString *const kFUJavaEnabledKey;
extern NSString *const kFUJavaScriptEnabledKey;
extern NSString *const kFUJavaScriptCanOpenWindowsAutomaticallyKey;
extern NSString *const kFUCookieAcceptPolicyKey;

// Shortcut Prefs
extern NSString *const kFUShortcutsKey;

// Whitelist Prefs
extern NSString *const kFUAllowBrowsingToAnyDomainKey;
extern NSString *const kFUInvertWhitelistKey;
extern NSString *const kFUWhitelistURLPatternStringsKey;

// PlugIns Prefs
extern NSString *const kFUShowVisiblePlugInsInNewWindowsKey;
extern NSString *const kFUVisiblePlugInIdentifiersKey;
extern NSString *const kFUNumberOfBrowsaPlugInsKey;
extern NSString *const kFUPlugInDrawerContentSizeStringKey;

@interface FUUserDefaults : NSObject {

}

+ (id)instance;

// Browser
@property (nonatomic, copy) NSString *webIconDatabaseDirectoryDefaults;
@property (nonatomic, copy) NSArray *recentURLStrings;
@property (nonatomic, copy) NSString *userAgentString;

// WebView
@property (nonatomic) BOOL continuousSpellCheckingEnabled;
@property (nonatomic) BOOL zoomTextOnly;

// UI
@property (nonatomic) BOOL statusBarShown;
@property (nonatomic) BOOL bookmarkBarShown;
@property (nonatomic) BOOL tabBarHiddenAlways;
@property (nonatomic, copy) NSString *windowFrameString;
@property (nonatomic) NSInteger windowScreenIndex;

// General Prefs
@property (nonatomic) NSInteger newWindowsOpenWith;
@property (nonatomic, copy) NSString *homeURLString;
@property (nonatomic, copy) NSString *downloadDirPath;

// Appearance Prefs
@property (nonatomic, copy) NSString *standardFontFamily;
@property (nonatomic) int defaultFontSize;
@property (nonatomic, copy) NSString *fixedFontFamily;
@property (nonatomic) int defaultFixedFontSize;
@property (nonatomic) BOOL loadsImagesAutomatically;

// Behavior Prefs
@property (nonatomic) NSInteger spacesBehavior;
@property (nonatomic) BOOL targetedClicksCreateTabs;
@property (nonatomic) BOOL linksSentToOtherApplicationsOpenInBackground;
@property (nonatomic) NSInteger openLinksFromApplicationsIn;
@property (nonatomic) BOOL hideLastClosedWindow;
@property (nonatomic) BOOL  sessionsEnabled;
@property (nonatomic, copy) NSArray *sessionInfo;

// Tabs Prefs
@property (nonatomic) BOOL tabbedBrowsingEnabled;
@property (nonatomic) BOOL selectNewWindowsOrTabsAsCreated;
@property (nonatomic) BOOL confirmBeforeClosingMultipleTabsOrWindows;
@property (nonatomic) BOOL tabBarHiddenForSingleTab;
@property (nonatomic) NSInteger tabBarCellOptimumWidth;

// Security Prefs
@property (nonatomic) BOOL plugInsEnabled;
@property (nonatomic) BOOL javaEnabled;
@property (nonatomic) BOOL javaScriptEnabled;
@property (nonatomic) BOOL javaScriptCanOpenWindowsAutomatically;
@property (nonatomic) NSInteger cookieAcceptPolicy;

// Shortcuts
@property (nonatomic, copy) NSArray *shortcuts;

// Whitelist Prefs
@property (nonatomic) BOOL allowBrowsingToAnyDomain;
@property (nonatomic) BOOL invertWhitelist;
@property (nonatomic, copy) NSArray *whitelistURLPatternStrings;

// All Plugins
@property (nonatomic) BOOL showVisiblePlugInsInNewWindows;
@property (nonatomic, copy) NSArray *visiblePlugInIdentifiers;
@property (nonatomic) NSInteger numberOfBrowsaPlugIns;
@property (nonatomic, copy) NSString *plugInDrawerContentSizeString;
@end
