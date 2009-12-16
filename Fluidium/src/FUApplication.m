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

#import "FUApplication.h"
#import "FUUserDefaults.h"
#import "FUDownloadWindowController.h"
#import "FUBookmarkWindowController.h"
#import "PTHotKey.h"
#import "FUAppearancePreferences.h"
#import "FUPlugInPreferences.h"
#import "TDSourceCodeTextView.h"
#import "FUWhitelistController.h"
#import "FUUserscriptController.h"
#import "FUUserstyleController.h"
#import "FURecentURLController.h"
#import "FUHistoryController.h"
#import "FUPlugInController.h"
#import "FUDownloadWindowController.h"
#import "FUUserAgentWindowController.h"
#import "FUBookmarkController.h"
#import <OmniAppKit/OAPreferenceController.h>

NSString *const FUApplicationVersionDidChangeNotification = @"FUApplicationVersionDidChangeNotification";

static NSString *const kFUApplicationLastVersionStringKey = @"FUApplicationLastVersionString";

@interface FUApplication ()
- (BOOL)createDirAtPathIfDoesntExist:(NSString *)path;
- (void)checkForVersionChange;
@end

@implementation FUApplication

+ (id)instance {
    return [self sharedApplication];
}


- (id)init {
    if (self = [super init]) {
        [self createAppSupportDir];
        
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(applicationWillTerminate:) name:NSApplicationWillTerminateNotification object:self];
    }
    return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.appName = nil;
    self.appSupportDirPath = nil;
    self.ssbSupportDirPath = nil;
    self.userscriptDirPath = nil;
    self.userscriptFilePath = nil;
    self.userstyleDirPath = nil;
    self.userstyleFilePath = nil;
    self.bookmarksFilePath = nil;
    self.downloadArchiveFilePath = nil;
    self.plugInPrivateDirPath = nil;
    self.plugInDirPath = nil;
    [super dealloc];
}


#pragma mark -
#pragma mark Actions

- (IBAction)showDownloadsWindow:(id)sender {
    [[FUDownloadWindowController instance] showWindow:sender];
}


- (IBAction)showBookmarksWindow:(id)sender {
    [[FUBookmarkWindowController instance] showWindow:sender];
}


- (IBAction)globalShortcutActivated:(id)sender {
    [self activateIgnoringOtherApps:YES];
}


// font panel support
- (IBAction)changeFont:(id)sender {
    NSWindow *win = [NSApp mainWindow];
    
    BOOL prefWinIsMain = [[win className] isEqualToString:@"OAPreferencesWindow"];
    BOOL viewSourceWinIsMain = [win isKindOfClass:[TDSourceCodeTextView class]];
    
    if (prefWinIsMain) {
        OAPreferenceClient *client = [[OAPreferenceController sharedPreferenceController] currentClient];
        if (client) {
            [client changeFont:sender];
        }
    } else if (viewSourceWinIsMain) {
        
    }
    
}


#pragma mark -
#pragma mark Public

- (BOOL)isFullScreen {
    return NO;
}


- (BOOL)createAppSupportDir {
    NSArray *pathComps = [NSArray arrayWithObjects:@"~", @"Library", @"Application Support", @"Fluidium", nil];
    NSString *path = [[NSString pathWithComponents:pathComps] stringByExpandingTildeInPath];
    self.appSupportDirPath = path;
    self.plugInDirPath = [appSupportDirPath stringByAppendingPathComponent:@"PlugIns"];
    self.plugInPrivateDirPath = [[NSBundle mainBundle] builtInPlugInsPath];
    
    BOOL success = [self createDirAtPathIfDoesntExist:appSupportDirPath];
    
    if (success) {
        path = [path stringByAppendingPathComponent:@"SSB"];
        [self createDirAtPathIfDoesntExist:path];
        
        path = [path stringByAppendingPathComponent:[[NSProcessInfo processInfo] processName]];
        self.ssbSupportDirPath = path;
        [self createDirAtPathIfDoesntExist:ssbSupportDirPath];

        path = [ssbSupportDirPath stringByAppendingPathComponent:@"Userscripts"];
        self.userscriptDirPath = path;
        [self createDirAtPathIfDoesntExist:userscriptDirPath];
        self.userscriptFilePath = [[userscriptDirPath stringByAppendingPathComponent:@"Userscripts"] stringByAppendingPathExtension:@"plist"];
        
        path = [ssbSupportDirPath stringByAppendingPathComponent:@"Userstyles"];
        self.userstyleDirPath = path;
        [self createDirAtPathIfDoesntExist:userstyleDirPath];
        self.userstyleFilePath = [[userstyleDirPath stringByAppendingPathComponent:@"Userstyles"] stringByAppendingPathExtension:@"plist"];
        
        self.downloadArchiveFilePath = [ssbSupportDirPath stringByAppendingPathComponent:@"DownloadArchive"];
        self.bookmarksFilePath = [ssbSupportDirPath stringByAppendingPathComponent:@"Bookmarks"];

        path = [appSupportDirPath stringByAppendingPathComponent:@"IconDatabase"];
        success = [self createDirAtPathIfDoesntExist:path];
        if (success) {
            // must set value for this WebKit user defaults key in the user defaults or else favicons will never be created
            [[FUUserDefaults instance] setWebIconDatabaseDirectoryDefaults:path];
        }
    }
    
    return success;
}


- (BOOL)createDirAtPathIfDoesntExist:(NSString *)path {
    BOOL exists, isDir;
    exists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir];
    
    BOOL success = (exists && isDir);
    
    if (!success) {
        NSError *err = nil;
        success = [[NSFileManager defaultManager] createDirectoryAtPath:path withIntermediateDirectories:YES attributes:nil error:&err];
        if (!success) {
            NSLog(@"Fluidium.app could not create dir at path: %@: %@", path, err);
        }
    }
    
    return success;
}


#pragma mark -
#pragma mark Private

- (void)checkForVersionChange {
    NSString *lastVers = [[NSUserDefaults standardUserDefaults] stringForKey:kFUApplicationLastVersionStringKey];
    NSString *currVers = [[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleVersion"];
    if (![lastVers isEqualToString:currVers]) {
        [[NSUserDefaults standardUserDefaults] setObject:currVers forKey:kFUApplicationLastVersionStringKey];
        
        [[NSNotificationCenter defaultCenter] postNotificationName:FUApplicationVersionDidChangeNotification object:self];
    }    
}


#pragma mark -
#pragma mark Notifications

- (void)finishLaunching {
    [super finishLaunching];
    
    [FUWhitelistController instance];
    [FUUserstyleController instance];
    [FUBookmarkController instance];
    [FUHistoryController instance];
    [FUPlugInController instance];
    [FUUserscriptController instance];
    [FUUserstyleController instance];
    [FUUserAgentWindowController instance];

    [self checkForVersionChange];
}


- (void)applicationWillTerminate:(NSNotification *)n {
    [[FUDownloadWindowController instance] save];
    [[FUWhitelistController instance] save];
    [[FURecentURLController instance] save];
    [[FUBookmarkController instance] save];
    [[FUHistoryController instance] save];
    [[FUUserscriptController instance] save];
    [[FUUserstyleController instance] save];
    
    [[NSUserDefaults standardUserDefaults] synchronize];
}

@synthesize appName;
@synthesize appSupportDirPath;
@synthesize ssbSupportDirPath;
@synthesize userscriptDirPath;
@synthesize userscriptFilePath;
@synthesize userstyleDirPath;
@synthesize userstyleFilePath;
@synthesize bookmarksFilePath;
@synthesize downloadArchiveFilePath;
@synthesize plugInPrivateDirPath;
@synthesize plugInDirPath;
@end
