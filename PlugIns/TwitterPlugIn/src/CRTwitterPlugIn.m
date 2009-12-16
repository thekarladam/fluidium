//
//  CRTwitterPlugIn.m
//  TwitterPlugIn
//
//  Created by Todd Ditchendorf on 10/11/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import "CRTwitterPlugIn.h"
#import "FUPlugInAPI.h"
#import "CRTwitterPlugInViewController.h"
#import "CRTimelineViewController.h"
#import "CRTwitterPlugInPrefsViewController.h"
#import "CRTwitterUtils.h"
#import <WebKit/WebKit.h>

NSString *kCRTwitterDisplayUsernamesKey = @"CRTwitterDisplayUsernames";
NSString *kCRTwitterAccountIDsKey = @"CRTwitterAccountIDs";
NSString *kCRTwitterSelectNewTabsAndWindowsKey = @"CRTwitterSelectNewTabsAndWindows";

NSString *CRTwitterPlugInSelectedUsernameDidChangeNotification = @"CRTwitterPlugInSelectedUsernameDidChange";

static CRTwitterPlugIn *instance = nil;

@interface CRTwitterPlugIn ()
@property (nonatomic, retain) NSMutableArray *viewControllers;

@property (readwrite, retain) NSViewController *preferencesViewController;
@property (readwrite, copy) NSString *identifier;
@property (readwrite, copy) NSString *localizedTitle;
@property (readwrite) NSInteger allowedViewPlacementMask;
@property (readwrite) NSInteger preferredViewPlacementMask;
@property (readwrite, copy) NSString *preferredMenuItemKeyEquivalent;
@property (readwrite) NSUInteger preferredMenuItemKeyEquivalentModifierMask;
@property (readwrite, copy) NSString *toolbarIconImageName;
@property (readwrite, copy) NSString *preferencesIconImageName;
@property (readwrite, retain) NSDictionary *defaultsDictionary;
@property (readwrite, retain) NSDictionary *aboutInfoDictionary;
@property CGFloat preferredVerticalSplitPosition;
@property CGFloat preferredHorizontalSplitPosition;
@end

@implementation CRTwitterPlugIn

+ (void)load {
    if ([CRTwitterPlugIn class] == self) {

        NSDictionary *d = [NSDictionary dictionaryWithObjectsAndKeys:
                           [NSNumber numberWithBool:YES], kCRTwitterDisplayUsernamesKey,
                           [NSNumber numberWithBool:YES], kCRTwitterSelectNewTabsAndWindowsKey,
                           nil];
        [[NSUserDefaultsController sharedUserDefaultsController] setInitialValues:d];
        [[NSUserDefaults standardUserDefaults] registerDefaults:d];
        
    }
}


+ (id)instance {
    return instance;
}


- (id)initWithPlugInAPI:(id <FUPlugInAPI>)api {
	if (self = [super init]) {
        
        // set instance
        instance = self;

        self.plugInAPI = api;
        self.viewControllers = [NSMutableArray array];
        
		self.identifier = @"com.fluidapp.TwitterPlugIn";
		self.localizedTitle = @"Twitter";
		self.preferredMenuItemKeyEquivalent = @"t";
		self.preferredMenuItemKeyEquivalentModifierMask = (NSControlKeyMask|NSAlternateKeyMask|NSCommandKeyMask);
		self.toolbarIconImageName = @"toolbar_button_twitter";
		self.preferencesIconImageName = @"toolbar_button_twitter";
		self.allowedViewPlacementMask = (FUPlugInViewPlacementDrawerMask|
										 FUPlugInViewPlacementUtilityPanelMask|
										 FUPlugInViewPlacementFloatingUtilityPanelMask|
										 FUPlugInViewPlacementHUDPanelMask|
										 FUPlugInViewPlacementFloatingHUDPanelMask|
										 FUPlugInViewPlacementSplitViewLeftMask|
										 FUPlugInViewPlacementSplitViewRightMask|
										 FUPlugInViewPlacementSplitViewTopMask|
										 FUPlugInViewPlacementSplitViewBottomMask);
        
		self.preferredViewPlacementMask = FUPlugInViewPlacementSplitViewLeftMask;
		
		self.preferencesViewController = [[[CRTwitterPlugInPrefsViewController alloc] init] autorelease];
        
		NSBundle *bundle = [NSBundle bundleForClass:[self class]];
		NSString *path = [bundle pathForResource:@"CRTwitterDefaultValues" ofType:@"plist"];
		self.defaultsDictionary = [NSDictionary dictionaryWithContentsOfFile:path];
		self.preferredVerticalSplitPosition = 320;
		self.preferredHorizontalSplitPosition = 160;
    }
	return self;
}


- (void)dealloc {
    self.plugInAPI = nil;
    self.viewControllers = nil;
    
	self.identifier = nil;
	self.localizedTitle = nil;
	self.preferredMenuItemKeyEquivalent = nil;
	self.toolbarIconImageName = nil;
	self.preferencesIconImageName = nil;
	self.defaultsDictionary = nil;
	self.aboutInfoDictionary = nil;
	self.preferencesViewController = nil;
    self.frontViewController = nil;
    self.selectedUsername = nil;
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}


- (void)setAboutInfoDictionary:(NSDictionary *)info {
    if (aboutInfoDictionary != info) {
        [aboutInfoDictionary autorelease];
        aboutInfoDictionary = [info retain];
    }
}


- (NSDictionary *)aboutInfoDictionary {
	if (!aboutInfoDictionary) {
		NSString *credits = [[[NSAttributedString alloc] initWithString:@"" attributes:nil] autorelease];
		NSString *applicationName = @"Fluidium Twitter Plug-in";
		NSImage  *applicationIcon = [NSImage imageNamed:self.preferencesIconImageName];
		NSString *version = @"1.0";
		NSString *copyright = @"Todd Ditchendorf 2009";
		NSString *applicationVersion = @"1.0";
		
		self.aboutInfoDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
									credits, @"Credits",
									applicationName, @"ApplicationName",
									applicationIcon, @"ApplicationIcon",
									version, @"Version",
									copyright, @"Copyright",
									applicationVersion, @"ApplicationVersion",
									nil];
	}
	return aboutInfoDictionary;
}


- (void)showPrefs:(id)sender {
    [[self plugInAPI] showPreferencePaneForIdentifier:[self identifier]];
}


- (BOOL)tabbedBrowsingEnabled {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"FUTabbedBrowsingEnabled"];
}


- (BOOL)selectNewWindowsOrTabsAsCreated {
    return [[NSUserDefaults standardUserDefaults] boolForKey:@"FUSelectNewWindowsOrTabsAsCreated"];
}


- (void)openURLString:(NSString *)s {
    [self openURL:[NSURL URLWithString:s]];
}


- (void)openURL:(NSURL *)URL {
    NSDictionary *args = [NSDictionary dictionaryWithObjectsAndKeys:
                          URL, @"URL", [NSApp currentEvent], @"evt", nil];

    [self openURLWithArgs:args];
}


- (void)openURLWithArgs:(NSDictionary *)args {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(openURLWithArgs:) withObject:args waitUntilDone:NO];
        return;
    }
    
    NSURL *URL = [args objectForKey:@"URL"];
    NSEvent *evt = [args objectForKey:@"evt"];
    
    // foreground or background?
    BOOL middleButtonClick = (2 == [evt buttonNumber]);
    BOOL commandKeyWasPressed = [self wasCommandKeyPressed:[evt modifierFlags]];
    BOOL shiftKeyWasPressed = [self wasShiftKeyPressed:[evt modifierFlags]];

    BOOL inForeground = YES; // tabs will be opened in the foregrand by default from this plugin

    BOOL commandClick = (commandKeyWasPressed | middleButtonClick); 
    if (commandClick) {
        inForeground = [self selectNewWindowsOrTabsAsCreated]; // we only check selectNewTabsOrWindows preference if commandClick was done
                                                               // why? cuz it just feels right
    }
    
    inForeground = (shiftKeyWasPressed) ? !inForeground : inForeground;
    
    // tab or window ?    
    BOOL tabbedBrowsingEnabled = [self tabbedBrowsingEnabled];
    BOOL optionKeyWasPressed = [self wasOptionKeyPressed:[evt modifierFlags]];
    tabbedBrowsingEnabled = (optionKeyWasPressed) ? !tabbedBrowsingEnabled : tabbedBrowsingEnabled;
    
    if (tabbedBrowsingEnabled) {
        [self openURL:URL inNewTabInForeground:inForeground];
    } else {
        [self openURL:URL inNewWindowInForeground:inForeground];
    }
}


- (BOOL)wasCommandKeyPressed:(NSInteger)modifierFlags {
	NSInteger commandKeyWasPressed = (NSCommandKeyMask & modifierFlags);
	return [[NSNumber numberWithInteger:commandKeyWasPressed] boolValue];
}


- (BOOL)wasShiftKeyPressed:(NSInteger)modifierFlags {
	NSInteger commandKeyWasPressed = (NSShiftKeyMask & modifierFlags);
	return [[NSNumber numberWithInteger:commandKeyWasPressed] boolValue];
}


- (BOOL)wasOptionKeyPressed:(NSInteger)modifierFlags {
	NSInteger commandKeyWasPressed = (NSAlternateKeyMask & modifierFlags);
	return [[NSNumber numberWithInteger:commandKeyWasPressed] boolValue];
}


- (void)openURL:(NSURL *)URL inNewTabInForeground:(BOOL)inForeground {
    NSURLRequest *req = [NSURLRequest requestWithURL:URL];
    [plugInAPI loadRequest:req destinationType:FUPlugInDestinationTypeTab inForeground:inForeground];
}


- (void)openURL:(NSURL *)URL inNewWindowInForeground:(BOOL)inForeground {
    NSURLRequest *req = [NSURLRequest requestWithURL:URL];
    [plugInAPI loadRequest:req destinationType:FUPlugInDestinationTypeWindow inForeground:inForeground];
}


- (void)showStatusText:(NSString *)s {
    [plugInAPI showStatusText:s];
}


#pragma mark -
#pragma mark FUPlugIn

- (NSViewController *)newPlugInViewController {
	CRTwitterPlugInViewController *vc = [[CRTwitterPlugInViewController alloc] init];
	vc.plugIn = self;
    self.frontViewController = vc;
    [viewControllers addObject:vc];
	return vc;
}


#pragma mark -
#pragma mark FUPlugInNotifications

- (void)plugInViewControllerWillAppear:(NSNotification *)n {
    CRTwitterPlugInViewController *vc = (CRTwitterPlugInViewController *)[n object];
    [vc willAppear];
}


- (void)plugInViewControllerDidAppear:(NSNotification *)n {
    CRTwitterPlugInViewController *vc = (CRTwitterPlugInViewController *)[n object];
    [vc didAppear];
}


- (void)plugInViewControllerWillDisappear:(NSNotification *)n {
    CRTwitterPlugInViewController *vc = (CRTwitterPlugInViewController *)[n object];
    [vc willDisappear];
}


- (void)plugInViewControllerDidDisappear:(NSNotification *)n {
    CRTwitterPlugInViewController *vc = (CRTwitterPlugInViewController *)[n object];
    [vc didDisappear];
}


- (NSArray *)usernames {
    return [preferencesViewController usernames];
}


- (NSString *)passwordFor:(NSString *)username {
    return [preferencesViewController passwordFor:username];
}


- (NSString *)selectedUsername {
    if (selectedUsername) {
        return [[selectedUsername retain] autorelease];
    } else {
        NSArray *usernames = [self usernames];
        if ([usernames count]) {
            return [usernames objectAtIndex:0];
        } else {
            return nil;
         }
    }
}

@synthesize plugInAPI;
@synthesize viewControllers;
@synthesize preferencesViewController;
@synthesize identifier;
@synthesize localizedTitle;
@synthesize allowedViewPlacementMask;
@synthesize preferredViewPlacementMask;
@synthesize preferredMenuItemKeyEquivalent;
@synthesize preferredMenuItemKeyEquivalentModifierMask;
@synthesize toolbarIconImageName;
@synthesize preferencesIconImageName;
@synthesize defaultsDictionary;
@synthesize preferredVerticalSplitPosition;
@synthesize preferredHorizontalSplitPosition;
@synthesize frontViewController;
@synthesize selectedUsername;
@end
