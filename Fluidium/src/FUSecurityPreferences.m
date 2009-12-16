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

#import "FUSecurityPreferences.h"
#import "FUUserDefaults.h"
#import "FUWebPreferences.h"
#import <WebKit/WebKit.h>

@implementation FUSecurityPreferences

- (IBAction)toggleArePluginsEnabled:(id)sender {
    BOOL yn = [[FUUserDefaults instance] plugInsEnabled];
    [[FUWebPreferences instance] setPlugInsEnabled:yn];
    self.defaultsHaveChanged = YES;
}


- (IBAction)toggleIsJavaEnabled:(id)sender {
    BOOL yn = [[FUUserDefaults instance] javaEnabled];
    [[FUWebPreferences instance] setJavaEnabled:yn];
    self.defaultsHaveChanged = YES;
}


- (IBAction)toggleIsJavaScriptEnabled:(id)sender {
    BOOL yn = [[FUUserDefaults instance] javaScriptEnabled];
    [[FUWebPreferences instance] setJavaScriptEnabled:yn];
    self.defaultsHaveChanged = YES;
}


- (IBAction)toggleBlockPopUpWindows:(id)sender {
    BOOL yn = [[FUUserDefaults instance] javaScriptCanOpenWindowsAutomatically];
    [[FUWebPreferences instance] setJavaScriptCanOpenWindowsAutomatically:yn];
    self.defaultsHaveChanged = YES;
}


- (IBAction)changeCookieAcceptPolicy:(id)sender {
    NSInteger i = [[sender selectedCell] tag];
    [[FUUserDefaults instance] setCookieAcceptPolicy:i];
    [[NSHTTPCookieStorage sharedHTTPCookieStorage] setCookieAcceptPolicy:i];
    self.defaultsHaveChanged = YES;
}

@end
