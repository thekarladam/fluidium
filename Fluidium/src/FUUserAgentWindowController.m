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

#import "FUUserAgentWindowController.h"
#import "FUUserDefaults.h"
#import "FUUtils.h"

#define UA_MENU_TAG 47

NSString *const FUUserAgentStringDidChangeNotification = @"FUUserAgentStringDidChangeNotification";

@interface FUUserAgentWindowController ()
- (void)loadUserAgentStrings;
- (void)updateMainMenu;
- (BOOL)isUsingDefaultUserAgent;
- (void)postDidChangeNotification;

@property (nonatomic, copy) NSArray *userAgentStrings;
@property (nonatomic, copy) NSString *defaultUserAgentFormat;
@end

@implementation FUUserAgentWindowController

+ (id)instance {
    static FUUserAgentWindowController *instance = nil;
    @synchronized (self) {
        if (!instance) {
            instance = [[FUUserAgentWindowController alloc] initWithWindowNibName:@"FUUserAgentWindow"];
        }
    }
    return instance;
}


- (id)initWithWindowNibName:(NSString *)name {
    if (self = [super initWithWindowNibName:name]) {
        [self loadUserAgentStrings];
        [self updateMainMenu];
    }
    return self;
}


- (void)dealloc {
    self.userAgentString = nil;
    self.userAgentStrings = nil;
    self.defaultUserAgentFormat = nil;
    self.defaultUserAgentString = nil;
    self.webKitVersionString = nil;
    self.editingUserAgentString = nil;
    [super dealloc];
}


#pragma mark -
#pragma mark Actions

- (IBAction)changeUAString:(id)sender {
    NSMenu *UAMenu = [sender menu];
    
    for (NSMenuItem *item in [UAMenu itemArray]) {
        [item setState:NSOffState];
    }
    
    [sender setState:NSOnState];
    
    self.userAgentString = [[userAgentStrings objectAtIndex:[sender tag]] objectForKey:@"value"];
}


- (IBAction)changeUAStringToOther:(id)sender {
    NSMenu *UAMenu = [sender menu];
    
    for (NSMenuItem *item in [UAMenu itemArray]) {
        [item setState:NSOffState];
    }
    
    [sender setState:NSOnState];
    
    self.editingUserAgentString = self.userAgentString;
    [self showWindow:self];
}


- (IBAction)cancel:(id)sender {
    [[self window] performClose:sender];
    self.editingUserAgentString = nil;
}


- (IBAction)ok:(id)sender {
    [[self window] performClose:sender];
    self.userAgentString = self.editingUserAgentString;
    self.editingUserAgentString = nil;
}


#pragma mark -
#pragma mark Private

- (void)loadUserAgentStrings {
    NSString *path = [[[NSBundle mainBundle] pathForResource:@"UserAgentStrings" ofType:@"plist"] stringByExpandingTildeInPath];
    self.userAgentStrings = [NSArray arrayWithContentsOfFile:path];
    if ([userAgentStrings count]) {
        self.defaultUserAgentFormat = [[userAgentStrings objectAtIndex:0] objectForKey:@"value"];
    }
}


- (NSString *)userAgentString {
    if ([self isUsingDefaultUserAgent]) {
        return self.defaultUserAgentString;
    } else {
        return [[FUUserDefaults instance] userAgentString];
    }
}


- (NSString *)webKitVersionString {
    if (!webKitVersionString) {
        NSString *path = @"/System/Library/Frameworks/WebKit.framework/Versions/A/Resources/version.plist";
        NSDictionary *d = [NSDictionary dictionaryWithContentsOfFile:path];
        NSString *s = [d objectForKey:@"CFBundleVersion"];
        if ([s length] > 2) {
            // The value in the version.plist file looks like this. dunno what the leading '6' is for, but Safari removes it. so we will too. :|
            //        <key>CFBundleVersion</key>
            //        <string>6531.21.8</string>
            s = [s substringFromIndex:1];
        } else {
            // a reasonable default (Safari 4.0.4)
            s = @"531.21.10";
        }
        self.webKitVersionString = s;
    }
    return webKitVersionString;
}


- (NSString *)defaultUserAgentString {
    if (!defaultUserAgentString) {
        // Mozilla/5.0 (Macintosh; U; Intel Mac OS X 10_6_2; en-us) AppleWebKit/531.21.8 (KHTML, like Gecko) Version/4.0.4 Safari/531.21.10
        // Mozilla/5.0 (Macintosh; U; Intel Mac OS X %d_%d_%d; en-us) AppleWebKit/%@ (KHTML, like Gecko) Fluid/%@ Safari/%@
        
        NSUInteger macMajorVers, macMinorVers, macBugfixVers;
        FUGetSystemVersion(&macMajorVers, &macMinorVers, &macBugfixVers);
        
        NSString *appVers = [[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleVersion"];
        NSString *webKitVers = [self webKitVersionString];
        
        self.defaultUserAgentString = [NSString stringWithFormat:defaultUserAgentFormat, 
                                       macMajorVers,
                                       macMinorVers,
                                       macBugfixVers,
                                       webKitVers,
                                       appVers,
                                       webKitVers];
        //NSLog(@"defaultUserAgentString: %@", defaultUserAgentString);
    }
    return defaultUserAgentString;
}


- (void)setUserAgentString:(NSString *)s {
    if ([s isEqualToString:defaultUserAgentFormat]) {
        [[FUUserDefaults instance] setUserAgentString:nil];
    } else {
        [[FUUserDefaults instance] setUserAgentString:[[s copy] autorelease]];
    }
    [[NSUserDefaults standardUserDefaults] synchronize];
    [self postDidChangeNotification];
}


- (BOOL)isUsingDefaultUserAgent {
    if ([[[FUUserDefaults instance] userAgentString] length]) {
        return NO;
    } else{
        return YES;
    }
}


- (void)updateMainMenu {
    NSString *currentUAString = nil;
    if ([self isUsingDefaultUserAgent]) {
        currentUAString = self.defaultUserAgentFormat;
    } else {
        currentUAString = self.userAgentString;
    }
    BOOL foundCurrentUAString = NO;
    
    NSMenu *appMenu = [[[NSApp mainMenu] itemAtIndex:0] submenu];
    NSMenuItem *UAItem = [[appMenu itemArray] objectAtIndex:[appMenu indexOfItemWithTag:UA_MENU_TAG]];
    
    NSMenu *UAMenu = [[[NSMenu alloc] init] autorelease];
    [UAItem setSubmenu:UAMenu];
    
    NSString *lastTitleFirstWord = nil;
    NSInteger tag = 0;
    for (NSDictionary *d in userAgentStrings) {
        NSString *title = [d objectForKey:@"title"];
        NSString *value = [d objectForKey:@"value"];
        
        if (lastTitleFirstWord && ![title hasPrefix:lastTitleFirstWord]) {
            [UAMenu addItem:[NSMenuItem separatorItem]];
        }
        
        NSInteger loc = [title rangeOfString:@" "].location;
        if (NSNotFound == loc) {
            loc = [title length];
        }
        lastTitleFirstWord = [title substringToIndex:loc];
        
        NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle:title
                                                       action:@selector(changeUAString:)
                                                keyEquivalent:@""] autorelease];
        [item setTarget:self];
        [item setTag:tag++];
        [UAMenu addItem:item];
        
        if (!foundCurrentUAString && [currentUAString isEqualToString:value]) {
            [item setState:NSOnState];
            foundCurrentUAString = YES;
        }
    }
    
    [UAMenu addItem:[NSMenuItem separatorItem]];
    
    NSMenuItem *otherItem = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Other...", @"")
                                                        action:@selector(changeUAStringToOther:)
                                                 keyEquivalent:@""] autorelease];
    [otherItem setTarget:self];
    [UAMenu addItem:otherItem];
    
    if (!foundCurrentUAString) {
        [otherItem setState:NSOnState];
    }
}


- (void)postDidChangeNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:FUUserAgentStringDidChangeNotification object:self];
}

@synthesize userAgentString;
@synthesize userAgentStrings;
@synthesize defaultUserAgentFormat;
@synthesize defaultUserAgentString;
@synthesize webKitVersionString;
@synthesize editingUserAgentString;
@end
