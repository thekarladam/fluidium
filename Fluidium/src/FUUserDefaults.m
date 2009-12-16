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

#import "FUUserDefaults.h"
#import "WebKitPrivate.h"

NSString *const FUHomeURLStringDidChangeNotification = @"FUHomeURLStringDidChangeNotification";

// Browser
NSString *const kFUWebIconDatabaseDirectoryDefaultsKey = @"WebIconDatabaseDirectoryDefaults";
NSString *const kFURecentURLStringsKey = @"FURecentURLStrings";
NSString *const kFUUserAgentStringKey = @"FUUserAgentString";

// WebKit
NSString *const kFUContinuousSpellCheckingEnabledKey = @"FUContinuousSpellCheckingEnabled";
NSString *const kFUZoomTextOnlyKey = @"FUZoomTextOnly";

// UI
NSString *const kFUBookmarkBarShownKey = @"FUBookmarkBarShown";
NSString *const kFUStatusBarShownKey = @"FUStatusBarShown";
NSString *const kFUTabBarHiddenAlwaysKey = @"FUTabBarHiddenAlways";
NSString *const kFUWindowFrameStringKey = @"FUWindowFrameString";
NSString *const kFUWindowScreenIndexKey = @"FUWindowScreenIndex";

// General Prefs
NSString *const kFUNewWindowsOpenWithKey = @"FUNewWindowsOpenWith";
NSString *const kFUHomeURLStringKey = @"FUHomeURLString";
NSString *const kFUDownloadDirPathKey = @"FUDownloadDirPath";
NSString *const kFUGlobalShortcutKeyComboCodeKey = @"FUGlobalShortcutKeyComboCode";
NSString *const kFUGlobalShortcutKeyComboFlagsKey = @"FUGlobalShortcutKeyComboFlags";

// Appearance Prefs
NSString *const kFUStandardFontFamilyKey = @"FUStandardFontFamily";
NSString *const kFUDefaultFontSizeKey = @"FUDefaultFontSize";
NSString *const kFUFixedFontFamilyKey = @"FUFixedFontFamily";
NSString *const kFUDefaultFixedFontSizeKey = @"FUDefaultFixedFontSize";
NSString *const kFULoadsImagesAutomaticallyKey = @"FULoadsImagesAutomatically";

// Behavior Prefs
NSString *const kFUSpacesBehaviorKey = @"FUSpacesBehavior";
NSString *const kFUTargetedClicksCreateTabsKey = @"FUTargetedClicksCreateTabs";
NSString *const kFULinksSentToOtherApplicationsOpenInBackgroundKey = @"FULinksSentToOtherApplicationsOpenInBackground";
NSString *const kFUOpenLinksFromApplicationsInKey = @"FUOpenLinksFromApplicationsIn";
NSString *const kFUHideLastClosedWindowKey = @"FUHideLastClosedWindow";
NSString *const kFUSessionsEnabledKey = @"FUSessionsEnabled";
NSString *const kFUSessionInfoKey = @"FUSessionInfo";

// Tabs Prefs
NSString *const kFUTabbedBrowsingEnabledKey = @"FUTabbedBrowsingEnabled";
NSString *const kFUSelectNewWindowsOrTabsAsCreatedKey = @"FUSelectNewWindowsOrTabsAsCreated";
NSString *const kFUConfirmBeforeClosingMultipleTabsOrWindowsKey = @"FUConfirmBeforeClosingMultipleTabsOrWindows";
NSString *const kFUTabBarHiddenForSingleTabKey = @"FUTabBarHiddenForSingleTab";
NSString *const kFUTabBarCellOptimumWidthKey = @"FUTabBarCellOptimumWidth";

// Security Prefs
NSString *const kFUPlugInsEnabledKey = @"FUPlugInsEnabled";
NSString *const kFUJavaEnabledKey = @"FUJavaEnabled";
NSString *const kFUJavaScriptEnabledKey = @"FUJavaScriptEnabled";
NSString *const kFUJavaScriptCanOpenWindowsAutomaticallyKey = @"FUJavaScriptCanOpenWindowsAutomatically";
NSString *const kFUCookieAcceptPolicyKey = @"FUCookieAcceptPolicy";

// Shortcut Prefs
NSString *const kFUShortcutsKey = @"FUShortcuts";

// Advanced Prefs
NSString *const kFUAllowBrowsingToAnyDomainKey = @"FUAllowBrowsingToAnyDomain";
NSString *const kFUInvertWhitelistKey = @"FUInvertWhitelist";
NSString *const kFUWhitelistURLPatternStringsKey = @"FUWhitelistURLPatternStrings";

// PlugIns Prefs
NSString *const kFUShowVisiblePlugInsInNewWindowsKey = @"FUShowVisiblePlugInsInNewWindows";
NSString *const kFUVisiblePlugInIdentifiersKey = @"FUVisiblePlugInIdentifiers";
NSString *const kFUNumberOfBrowsaPlugInsKey = @"FUNumberOfBrowsaPlugIns";
NSString *const kFUPlugInDrawerContentSizeStringKey = @"FUPlugInDrawerContentSizeString";

@interface FUUserDefaults ()
+ (void)setUpUserDefaults;
@end

@implementation FUUserDefaults

+ (void)load {
    if ([FUUserDefaults class] == self) {
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

        // initialize WebKit favicon database
        [WebIconDatabase sharedIconDatabase];

        [self setUpUserDefaults];
        
        [pool release];
    }
}


+ (void)setUpUserDefaults {
    NSString *path = [[NSBundle mainBundle] pathForResource:@"DefaultValues" ofType:@"plist"];
    NSMutableDictionary *defaultValues = [NSMutableDictionary dictionaryWithContentsOfFile:path];
    
    [[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:defaultValues];
    [[NSUserDefaults standardUserDefaults] registerDefaults:defaultValues];
}


+ (id)instance {
    static FUUserDefaults *instance = nil;
    @synchronized (self) {
        if (!instance) {
            instance = [[FUUserDefaults alloc] init];
        }
    }
    return instance;
}


#pragma mark -
#pragma mark Browser

- (NSString *)webIconDatabaseDirectoryDefaults {
    return [[NSUserDefaults standardUserDefaults] stringForKey:kFUWebIconDatabaseDirectoryDefaultsKey];
}
- (void)setWebIconDatabaseDirectoryDefaults:(NSString *)s {
    [[NSUserDefaults standardUserDefaults] setObject:s forKey:kFUWebIconDatabaseDirectoryDefaultsKey];
}


- (NSString *)homeURLString {
    return [[NSUserDefaults standardUserDefaults] stringForKey:kFUHomeURLStringKey];
}
- (void)setHomeURLString:(NSString *)s {
    [[NSUserDefaults standardUserDefaults] setObject:s forKey:kFUHomeURLStringKey];
}


- (NSString *)downloadDirPath {
    return [[NSUserDefaults standardUserDefaults] stringForKey:kFUDownloadDirPathKey];
}
- (void)setDownloadDirPath:(NSString *)s {
    [[NSUserDefaults standardUserDefaults] setObject:s forKey:kFUDownloadDirPathKey];
}


- (NSArray *)recentURLStrings {
    return [[NSUserDefaults standardUserDefaults] arrayForKey:kFURecentURLStringsKey];
}
- (void)setRecentURLStrings:(NSArray *)a {
    [[NSUserDefaults standardUserDefaults] setObject:a forKey:kFURecentURLStringsKey];
}


- (NSString *)userAgentString {
    return [[NSUserDefaults standardUserDefaults] stringForKey:kFUUserAgentStringKey];
}
- (void)setUserAgentString:(NSString *)s {
    [[NSUserDefaults standardUserDefaults] setObject:s forKey:kFUUserAgentStringKey];
}


#pragma mark -
#pragma mark WebKit

- (BOOL)continuousSpellCheckingEnabled {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kFUContinuousSpellCheckingEnabledKey];
}
- (void)setContinuousSpellCheckingEnabled:(BOOL)yn {
    [[NSUserDefaults standardUserDefaults] setBool:yn forKey:kFUContinuousSpellCheckingEnabledKey];
}


- (BOOL)zoomTextOnly {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kFUZoomTextOnlyKey];
}
- (void)setZoomTextOnly:(BOOL)yn {
    [[NSUserDefaults standardUserDefaults] setBool:yn forKey:kFUZoomTextOnlyKey];
}


#pragma mark -
#pragma mark UI

- (BOOL)statusBarShown {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kFUStatusBarShownKey];
}
- (void)setStatusBarShown:(BOOL)yn {
    [[NSUserDefaults standardUserDefaults] setBool:yn forKey:kFUStatusBarShownKey];
}


- (BOOL)bookmarkBarShown {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kFUBookmarkBarShownKey];
}
- (void)setBookmarkBarShown:(BOOL)yn {
    [[NSUserDefaults standardUserDefaults] setBool:yn forKey:kFUBookmarkBarShownKey];
}


- (BOOL)tabBarHiddenAlways {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kFUTabBarHiddenAlwaysKey];
}
- (void)setTabBarHiddenAlways:(BOOL)yn {
    [[NSUserDefaults standardUserDefaults] setBool:yn forKey:kFUTabBarHiddenAlwaysKey];
}


- (NSString *)windowFrameString {
    return [[NSUserDefaults standardUserDefaults] stringForKey:kFUWindowFrameStringKey];
}
- (void)setWindowFrameString:(NSString *)s {
    [[NSUserDefaults standardUserDefaults] setObject:s forKey:kFUWindowFrameStringKey];
}


- (NSInteger)windowScreenIndex {
    return [[NSUserDefaults standardUserDefaults] integerForKey:kFUWindowScreenIndexKey];
}
- (void)setWindowScreenIndex:(NSInteger)i {
    [[NSUserDefaults standardUserDefaults] setInteger:i forKey:kFUWindowScreenIndexKey];
}



#pragma mark -
#pragma mark General Prefs

- (NSInteger)newWindowsOpenWith {
    return [[NSUserDefaults standardUserDefaults] integerForKey:kFUNewWindowsOpenWithKey];
}
- (void)setNewWindowsOpenWith:(NSInteger)i {
    [[NSUserDefaults standardUserDefaults] setInteger:i forKey:kFUNewWindowsOpenWithKey];
}



#pragma mark -
#pragma mark Appearance Prefs

- (NSString *)standardFontFamily {
    return [[NSUserDefaults standardUserDefaults] stringForKey:kFUStandardFontFamilyKey];
}
- (void)setStandardFontFamily:(NSString *)s {
    [[NSUserDefaults standardUserDefaults] setObject:s forKey:kFUStandardFontFamilyKey];
}


- (int)defaultFontSize {
    return [[NSUserDefaults standardUserDefaults] integerForKey:kFUDefaultFontSizeKey];
}
- (void)setDefaultFontSize:(int)i {
    [[NSUserDefaults standardUserDefaults] setInteger:i forKey:kFUDefaultFontSizeKey];
}


- (NSString *)fixedFontFamily {
    return [[NSUserDefaults standardUserDefaults] stringForKey:kFUFixedFontFamilyKey];
}
- (void)setFixedFontFamily:(NSString *)s {
    [[NSUserDefaults standardUserDefaults] setObject:s forKey:kFUFixedFontFamilyKey];
}


- (int)defaultFixedFontSize {
    return [[NSUserDefaults standardUserDefaults] integerForKey:kFUDefaultFixedFontSizeKey];
}
- (void)setDefaultFixedFontSize:(int)i {
    [[NSUserDefaults standardUserDefaults] setInteger:i forKey:kFUDefaultFixedFontSizeKey];
}


- (BOOL)loadsImagesAutomatically {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kFULoadsImagesAutomaticallyKey];
}
- (void)setLoadsImagesAutomatically:(BOOL)yn {
    [[NSUserDefaults standardUserDefaults] setBool:yn forKey:kFULoadsImagesAutomaticallyKey];
}


#pragma mark -
#pragma mark Behavior Prefs

- (NSInteger)spacesBehavior {
    return [[NSUserDefaults standardUserDefaults] integerForKey:kFUSpacesBehaviorKey];
}
- (void)setSpacesBehavior:(NSInteger)i {
    [[NSUserDefaults standardUserDefaults] setInteger:i forKey:kFUSpacesBehaviorKey];
}


- (BOOL)targetedClicksCreateTabs {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kFUTargetedClicksCreateTabsKey];
}
- (void)setTargetedClicksCreateTabs:(BOOL)yn {
    [[NSUserDefaults standardUserDefaults] setBool:yn forKey:kFUTargetedClicksCreateTabsKey];
}


- (BOOL)linksSentToOtherApplicationsOpenInBackground {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kFULinksSentToOtherApplicationsOpenInBackgroundKey];
}
- (void)setLinksSentToOtherApplicationsOpenInBackground:(BOOL)yn {
    [[NSUserDefaults standardUserDefaults] setBool:yn forKey:kFULinksSentToOtherApplicationsOpenInBackgroundKey];
}


- (NSInteger)openLinksFromApplicationsIn {
    return [[NSUserDefaults standardUserDefaults] integerForKey:kFUOpenLinksFromApplicationsInKey];
}
- (void)setOpenLinksFromApplicationsIn:(NSInteger)i {
    [[NSUserDefaults standardUserDefaults] setInteger:i forKey:kFUOpenLinksFromApplicationsInKey];
}


- (BOOL)hideLastClosedWindow {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kFUHideLastClosedWindowKey];
}
- (void)setHideLastClosedWindow:(BOOL)yn {
    [[NSUserDefaults standardUserDefaults] setBool:yn forKey:kFUHideLastClosedWindowKey];
}


- (BOOL)sessionsEnabled {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kFUSessionsEnabledKey];
}
- (void)setSessionsEnabled:(BOOL)yn {
    [[NSUserDefaults standardUserDefaults] setBool:yn forKey:kFUSessionsEnabledKey];
}


- (NSArray *)sessionInfo {
    return [[NSUserDefaults standardUserDefaults] arrayForKey:kFUSessionInfoKey];
}
- (void)setSessionInfo:(NSArray *)a {
    [[NSUserDefaults standardUserDefaults] setObject:a forKey:kFUSessionInfoKey];
}


#pragma mark -
#pragma mark Tabs Prefs

- (BOOL)tabbedBrowsingEnabled {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kFUTabbedBrowsingEnabledKey];
}
- (void)setTabbedBrowsingEnabled:(BOOL)yn {
    [[NSUserDefaults standardUserDefaults] setBool:yn forKey:kFUTabbedBrowsingEnabledKey];
}


- (BOOL)selectNewWindowsOrTabsAsCreated {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kFUSelectNewWindowsOrTabsAsCreatedKey];
}
- (void)setSelectNewWindowsOrTabsAsCreated:(BOOL)yn {
    [[NSUserDefaults standardUserDefaults] setBool:yn forKey:kFUSelectNewWindowsOrTabsAsCreatedKey];
}


- (BOOL)confirmBeforeClosingMultipleTabsOrWindows {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kFUConfirmBeforeClosingMultipleTabsOrWindowsKey];
}
- (void)setConfirmBeforeClosingMultipleTabsOrWindows:(BOOL)yn {
    [[NSUserDefaults standardUserDefaults] setBool:yn forKey:kFUConfirmBeforeClosingMultipleTabsOrWindowsKey];
}


- (BOOL)tabBarHiddenForSingleTab {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kFUTabBarHiddenForSingleTabKey];
}
- (void)setTabBarHiddenForSingleTab:(BOOL)yn {
    [[NSUserDefaults standardUserDefaults] setBool:yn forKey:kFUTabBarHiddenForSingleTabKey];
}


- (NSInteger)tabBarCellOptimumWidth {
    return [[NSUserDefaults standardUserDefaults] integerForKey:kFUTabBarCellOptimumWidthKey];
}
- (void)setTabBarCellOptimumWidth:(NSInteger)i {
    [[NSUserDefaults standardUserDefaults] setInteger:i forKey:kFUTabBarCellOptimumWidthKey];
}


#pragma mark -
#pragma mark Security Prefs

- (BOOL)plugInsEnabled {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kFUPlugInsEnabledKey];
}
- (void)setPlugInsEnabled:(BOOL)yn {
    [[NSUserDefaults standardUserDefaults] setBool:yn forKey:kFUPlugInsEnabledKey];
}


- (BOOL)javaEnabled {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kFUJavaEnabledKey];
}
- (void)setJavaEnabled:(BOOL)yn {
    [[NSUserDefaults standardUserDefaults] setBool:yn forKey:kFUJavaEnabledKey];
}


- (BOOL)javaScriptEnabled {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kFUJavaScriptEnabledKey];
}
- (void)setJavaScriptEnabled:(BOOL)yn {
    [[NSUserDefaults standardUserDefaults] setBool:yn forKey:kFUJavaScriptEnabledKey];
}


- (BOOL)javaScriptCanOpenWindowsAutomatically {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kFUJavaScriptCanOpenWindowsAutomaticallyKey];
}
- (void)setJavaScriptCanOpenWindowsAutomatically:(BOOL)yn {
    [[NSUserDefaults standardUserDefaults] setBool:yn forKey:kFUJavaScriptCanOpenWindowsAutomaticallyKey];
}


- (NSInteger)cookieAcceptPolicy {
    return [[NSUserDefaults standardUserDefaults] integerForKey:kFUCookieAcceptPolicyKey];
}
- (void)setCookieAcceptPolicy:(NSInteger)i {
    [[NSUserDefaults standardUserDefaults] setInteger:i forKey:kFUCookieAcceptPolicyKey];
}


#pragma mark -
#pragma mark Shortcut Prefs

- (NSArray *)shortcuts {
    return [[NSUserDefaults standardUserDefaults] arrayForKey:kFUShortcutsKey];
}
- (void)setShortcuts:(NSArray *)a {
    [[NSUserDefaults standardUserDefaults] setObject:a forKey:kFUShortcutsKey];
}


#pragma mark -
#pragma mark Whitelist Prefs

- (BOOL)allowBrowsingToAnyDomain {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kFUAllowBrowsingToAnyDomainKey];
}
- (void)setAllowBrowsingToAnyDomain:(BOOL)yn {
    [[NSUserDefaults standardUserDefaults] setBool:yn forKey:kFUAllowBrowsingToAnyDomainKey];
}


- (BOOL)invertWhitelist {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kFUInvertWhitelistKey];
}
- (void)setInvertWhitelist:(BOOL)yn {
    [[NSUserDefaults standardUserDefaults] setBool:yn forKey:kFUInvertWhitelistKey];
}


- (NSArray *)whitelistURLPatternStrings {
    return [[NSUserDefaults standardUserDefaults] arrayForKey:kFUWhitelistURLPatternStringsKey];
}
- (void)setWhitelistURLPatternStrings:(NSArray *)a {
    [[NSUserDefaults standardUserDefaults] setObject:a forKey:kFUWhitelistURLPatternStringsKey];
}


#pragma mark -
#pragma mark PlugIns Prefs

- (BOOL)showVisiblePlugInsInNewWindows {
    return [[NSUserDefaults standardUserDefaults] boolForKey:kFUShowVisiblePlugInsInNewWindowsKey];
}
- (void)setShowVisiblePlugInsInNewWindows:(BOOL)yn {
    [[NSUserDefaults standardUserDefaults] setBool:yn forKey:kFUShowVisiblePlugInsInNewWindowsKey];
}


- (NSArray *)visiblePlugInIdentifiers {
    return [[NSUserDefaults standardUserDefaults] arrayForKey:kFUVisiblePlugInIdentifiersKey];
}
- (void)setVisiblePlugInIdentifiers:(NSArray *)a {
    [[NSUserDefaults standardUserDefaults] setObject:a forKey:kFUVisiblePlugInIdentifiersKey];
}


- (NSInteger)numberOfBrowsaPlugIns {
    return [[NSUserDefaults standardUserDefaults] integerForKey:kFUNumberOfBrowsaPlugInsKey];
}
- (void)setNumberOfBrowsaPlugIns:(NSInteger)i {
    [[NSUserDefaults standardUserDefaults] setInteger:i forKey:kFUNumberOfBrowsaPlugInsKey];
}


- (NSString *)plugInDrawerContentSizeString {
    return [[NSUserDefaults standardUserDefaults] stringForKey:kFUPlugInDrawerContentSizeStringKey];
}
- (void)setPlugInDrawerContentSizeString:(NSString *)s {
    [[NSUserDefaults standardUserDefaults] setObject:s forKey:kFUPlugInDrawerContentSizeStringKey];
}

@end
