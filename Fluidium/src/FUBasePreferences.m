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

@implementation FUBasePreferences

- (IBAction)restoreDefaults:(id)sender {
    [super restoreDefaults:sender];
    self.defaultsHaveChanged = NO;
}


- (void)restoreDefaultsNoPrompt {
    [super restoreDefaultsNoPrompt];
    self.defaultsHaveChanged = NO;
}


- (BOOL)haveAnyDefaultsChanged {
    if (self.defaultsHaveChanged) {
        return YES;
    }
    
    return [super haveAnyDefaultsChanged];
}

@synthesize defaultsHaveChanged;
@end
