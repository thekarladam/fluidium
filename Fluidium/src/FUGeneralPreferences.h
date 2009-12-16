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

@class SRRecorderControl;
@class PTHotKey;

@interface FUGeneralPreferences : FUBasePreferences {
    NSTextField *homeURLStringTextField;
    SRRecorderControl *recorderControl;
    NSPopUpButton *downloadFolderPopUpButton;
    NSMenu *downloadFolderPopUpButtonMenu;
    PTHotKey *globalHotKey;
    BOOL busy;
}

- (IBAction)changeAppIcon:(id)sender;
- (IBAction)toggleGlobalHotKey:(id)sender;
- (IBAction)runSelectDownloadFolderPanel:(id)sender;

@property (nonatomic, retain) IBOutlet NSTextField *homeURLStringTextField;
@property (nonatomic, retain) IBOutlet SRRecorderControl *recorderControl;
@property (nonatomic, retain) IBOutlet NSPopUpButton *downloadFolderPopUpButton;
@property (nonatomic, retain) IBOutlet NSMenu *downloadFolderPopUpButtonMenu;
@property (nonatomic, getter=isBusy) BOOL busy;
@property (nonatomic, retain) PTHotKey *globalHotKey;
@property (nonatomic, readonly) NSString *downloadFolderName;
@end
