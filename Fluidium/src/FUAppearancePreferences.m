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

#import "FUAppearancePreferences.h"
#import "FUWebPreferences.h"
#import <WebKit/WebKit.h>

@implementation FUAppearancePreferences

- (void)dealloc {
    self.standardFontTextField = nil;
    self.fixedWidthFontTextField = nil;
    [super dealloc];
}


- (void)updateUI {
//    NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
//    WebPreferences *webPreferences = [FUWebPreferences instance];
    
    [self willChangeValueForKey:@"standardFontDisplayString"];
    [self willChangeValueForKey:@"standardFont"];
//    [webPreferences setStandardFontFamily:[defaults objectForKey:kFUStandardFontFamilyKey]];
//    [webPreferences setDefaultFontSize:(int)[defaults integerForKey:kFUStandardFontSizeKey]];
    [self didChangeValueForKey:@"standardFontDisplayString"];
    [self didChangeValueForKey:@"standardFont"];
    [self willChangeValueForKey:@"fixedWidthFontDisplayString"];
    [self willChangeValueForKey:@"fixedWidthFont"];
//    [webPreferences setFixedFontFamily:[userDefaults objectForKey:kFUFixedWidthFontFamily]];
//    [webPreferences setDefaultFixedFontSize:(int)[userDefaults floatForKey:kFUFixedWidthFontSize]];
    [self didChangeValueForKey:@"fixedWidthFontDisplayString"];
    [self didChangeValueForKey:@"fixedWidthFont"];
}


- (NSString *)standardFontDisplayString {
    NSFont *font = [self standardFont];
    return [NSString stringWithFormat:@"%@ %0.f", [font displayName], [font pointSize]];
}


- (NSString *)fixedWidthFontDisplayString {
    NSFont *font = [self fixedWidthFont];
    return [NSString stringWithFormat:@"%@ %0.f", [font displayName], [font pointSize]];
}


- (IBAction)runFontPanel:(id)sender {
    selectingStandard = [sender tag];
    
    NSFont *font = selectingStandard ? [self standardFont] : [self fixedWidthFont];

    [[NSFontManager sharedFontManager] setSelectedFont:font isMultiple:NO];
    NSFontPanel *fontPanel = [[NSFontManager sharedFontManager] fontPanel:YES];
    [fontPanel orderFront:self];
}


- (NSFont *)standardFont {
    NSString *fontFamily = [[FUWebPreferences instance] standardFontFamily];
    CGFloat fontSize = [[FUWebPreferences instance] defaultFontSize];
    return [NSFont fontWithName:fontFamily size:fontSize];    
}


- (NSFont *)fixedWidthFont {
    NSString *fontFamily = [[FUWebPreferences instance] fixedFontFamily];
    CGFloat fontSize = [[FUWebPreferences instance] defaultFixedFontSize];
    return [NSFont fontWithName:fontFamily size:fontSize];    
}


- (void)changeFont:(id)sender {    
    NSFont *oldFont = selectingStandard ? [self standardFont] : [self fixedWidthFont];
    NSFont *newFont = [sender convertFont:oldFont];

    //    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    if (selectingStandard) {
        [self willChangeValueForKey:@"standardFontDisplayString"];
        [self willChangeValueForKey:@"standardFont"];
//        [userDefaults setObject:[newFont familyName] forKey:kFUStandardFontFamily];
//        [userDefaults setFloat:[newFont pointSize] forKey:kFUStandardFontSize];
        [[FUWebPreferences instance] setStandardFontFamily:[newFont familyName]];
        [[FUWebPreferences instance] setDefaultFontSize:[newFont pointSize]];
        [self didChangeValueForKey:@"standardFontDisplayString"];
        [self didChangeValueForKey:@"standardFont"];
    } else {
        [self willChangeValueForKey:@"fixedWidthFontDisplayString"];
        [self willChangeValueForKey:@"fixedWidthFont"];
//        [userDefaults setObject:[newFont familyName] forKey:kFUFixedWidthFontFamily];
//        [userDefaults setFloat:[newFont pointSize] forKey:kFUFixedWidthFontSize];
        [[FUWebPreferences instance] setFixedFontFamily:[newFont familyName]];
        [[FUWebPreferences instance] setDefaultFixedFontSize:[newFont pointSize]];
        [self didChangeValueForKey:@"fixedWidthFontDisplayString"];
        [self didChangeValueForKey:@"fixedWidthFont"];
    }
    
    [[FUWebPreferences instance] postDidChangeNotification];
    self.defaultsHaveChanged = YES;
}


- (IBAction)toggleSetLoadsImagesAutomatically:(id)sender {
    [[FUWebPreferences instance] setLoadsImagesAutomatically:[[FUWebPreferences instance] loadsImagesAutomatically]];

    [[FUWebPreferences instance] postDidChangeNotification];
    self.defaultsHaveChanged = YES;
}

@synthesize standardFontTextField;
@synthesize fixedWidthFontTextField;
@end
