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

#import "FUWebView.h"
#import "FUUserDefaults.h"
#import "FUWebPreferences.h"
#import "FUUserAgentWindowController.h"

@interface FUWebView ()
- (void)FU_webPreferencesDidChange:(NSNotification *)n;
- (void)FU_userAgentStringDidChange:(NSNotification *)n;
@end

@implementation FUWebView

- (id)initWithFrame:(NSRect)frame frameName:(NSString *)frameName groupName:(NSString *)groupName {
    if (self = [super initWithFrame:frame frameName:frameName groupName:groupName]) {
        NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
        [nc addObserver:self selector:@selector(FU_webPreferencesDidChange:) name:FUWebPreferencesDidChangeNotification object:[FUWebPreferences instance]];
        [nc addObserver:self selector:@selector(FU_userAgentStringDidChange:) name:FUUserAgentStringDidChangeNotification object:nil];
        
        [self FU_userAgentStringDidChange:nil];
    }
    return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [super dealloc];
}


#pragma mark -
#pragma mark Actions

- (IBAction)toggleContinuousSpellChecking:(id)sender {
    [super toggleContinuousSpellChecking:sender];
    BOOL enabled = [self isContinuousSpellCheckingEnabled];
    [[FUUserDefaults instance] setContinuousSpellCheckingEnabled:enabled];
}


#pragma mark -
#pragma mark Notifications

- (void)FU_webPreferencesDidChange:(NSNotification *)n {
    [self setPreferences:[FUWebPreferences instance]];
    [self reload:self];
}


- (void)FU_userAgentStringDidChange:(NSNotification *)n {
    [self setCustomUserAgent:[[FUUserAgentWindowController instance] userAgentString]];
}


#pragma mark -
#pragma mark Public

- (NSImage *)FU_imageRepresentation {
    NSRect webViewBounds = [self bounds];
    NSImage *image = [[[NSImage alloc] initWithSize:webViewBounds.size] autorelease];
    [self lockFocus];
    NSBitmapImageRep *imageRep = [self bitmapImageRepForCachingDisplayInRect:webViewBounds];
    [image addRepresentation:imageRep];
    [self cacheDisplayInRect:webViewBounds toBitmapImageRep:imageRep];
    [self unlockFocus];
    return image;
}

@end
