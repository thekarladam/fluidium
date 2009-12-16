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

#import "FUBasePreferences.h"

@interface FUAppearancePreferences : FUBasePreferences {
    NSTextField *standardFontTextField;
    NSTextField *fixedWidthFontTextField;
    
    BOOL selectingStandard;
}

- (IBAction)runFontPanel:(id)sender;
- (IBAction)toggleSetLoadsImagesAutomatically:(id)sender;

- (NSFont *)standardFont;
- (NSFont *)fixedWidthFont;
- (NSString *)standardFontDisplayString;
- (NSString *)fixedWidthFontDisplayString;

- (void)changeFont:(id)sender;

@property (nonatomic, retain) IBOutlet NSTextField *standardFontTextField;
@property (nonatomic, retain) IBOutlet NSTextField *fixedWidthFontTextField;
@end
