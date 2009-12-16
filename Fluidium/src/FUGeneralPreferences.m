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

#import "FUGeneralPreferences.h"
#import "PTHotKey.h"
#import "PTHotKeyCenter.h"
#import "FUWindowController.h"
#import "FUUserDefaults.h"
#import "FUApplication.h"
#import "FUIconController.h"
#import <WebKit/WebKit.h>
#import <OmniAppKit/OmniAppKit.h>
#import <ShortcutRecorder/ShortcutRecorder.h>

#define NUM_MENU_ITEMS 3

@interface FUGeneralPreferences ()
- (void)doChangeAppIcon;
- (NSString *)recorderControlAutosaveName;
- (void)openPanelDidEnd:(NSOpenPanel *)openPanel result:(NSInteger)result contextInfo:(void *)ctx;
@end

@implementation FUGeneralPreferences

- (void)dealloc {
    self.homeURLStringTextField = nil;
    self.recorderControl = nil;
    self.downloadFolderPopUpButton = nil;
    self.downloadFolderPopUpButtonMenu = nil;
    self.globalHotKey = nil;
    [super dealloc];
}


- (void)awakeFromNib {
    [recorderControl setCanCaptureGlobalHotKeys:YES];
    [recorderControl setAllowsKeyOnly:NO escapeKeysRecord:NO];
    [[recorderControl cell] setDelegate:self];
    
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    id codeObj = [userDefaults objectForKey:kFUGlobalShortcutKeyComboCodeKey];
    id flagsObj = [userDefaults objectForKey:kFUGlobalShortcutKeyComboFlagsKey];
    if (codeObj && flagsObj) {
        NSInteger code = [userDefaults integerForKey:kFUGlobalShortcutKeyComboCodeKey];
        NSInteger flags = [userDefaults integerForKey:kFUGlobalShortcutKeyComboFlagsKey];
        
        KeyCombo keyCombo = { flags, code };
        [recorderControl setKeyCombo:keyCombo];
    }
    
    [self menuNeedsUpdate:downloadFolderPopUpButtonMenu];
}


- (void)shortcutRecorderCell:(SRRecorderCell *)cell keyComboDidChange:(KeyCombo)keyCombo {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults]; 
    [userDefaults setInteger:keyCombo.code forKey:kFUGlobalShortcutKeyComboCodeKey];
    [userDefaults setInteger:keyCombo.flags forKey:kFUGlobalShortcutKeyComboFlagsKey];

    [self toggleGlobalHotKey:cell];
}


- (NSString *)recorderControlAutosaveName {
    return [NSString stringWithFormat:@"FUGlobalShortcutKeyCombo %@", [[FUApplication instance] appName]];
}


- (IBAction)toggleGlobalHotKey:(id)sender {

    if (self.globalHotKey) {
        [[PTHotKeyCenter sharedCenter] unregisterHotKey:globalHotKey];
        self.globalHotKey = nil;
    }
    
    PTKeyCombo *keyCombo = [PTKeyCombo keyComboWithKeyCode:[recorderControl keyCombo].code
                                                 modifiers:[recorderControl cocoaToCarbonFlags:[recorderControl keyCombo].flags]];
    
    NSString *identifier = [self recorderControlAutosaveName];
    self.globalHotKey = [[[PTHotKey alloc] initWithIdentifier:identifier keyCombo:keyCombo] autorelease];

    [globalHotKey setTarget:[FUApplication instance]];
    [globalHotKey setAction:@selector(globalShortcutActivated:)];
    
    [[PTHotKeyCenter sharedCenter] registerHotKey:globalHotKey];
}


- (IBAction)changeAppIcon:(id)sender {
    [self performSelector:@selector(doChangeAppIcon) withObject:nil afterDelay:.1];
}


- (void)doChangeAppIcon {
    NSOpenPanel *openPanel = [NSOpenPanel openPanel];
    [openPanel setCanChooseDirectories:NO];
    [openPanel setCanChooseFiles:YES];
    [openPanel setAllowsMultipleSelection:NO];

    NSInteger result = [openPanel runModalForDirectory:nil file:nil types:nil];
    NSArray *filenames = [openPanel filenames];
    
    if (NSOKButton == result && filenames.count) {
        self.busy = YES;
        [[FUIconController instance] setCustomAppIconToFileAtPath:[filenames objectAtIndex:0]];
        self.busy = NO;
    }
}


- (IBAction)runSelectDownloadFolderPanel:(id)sender {
    NSOpenPanel *openPanel = [[NSOpenPanel alloc] init]; // retained
    [openPanel setAllowsMultipleSelection:NO];
    [openPanel setCanChooseFiles:NO];
    [openPanel setCanChooseDirectories:YES];
    [openPanel beginSheetForDirectory:nil 
                                 file:nil 
                       modalForWindow:[[OAPreferenceController sharedPreferenceController] window]
                        modalDelegate:self
                       didEndSelector:@selector(openPanelDidEnd:result:contextInfo:) 
                          contextInfo:nil];    
}


- (void)openPanelDidEnd:(NSOpenPanel *)openPanel result:(NSInteger)result contextInfo:(void *)ctx {
    if (NSOKButton == result) {
        [[FUUserDefaults instance] setDownloadDirPath:[openPanel filename]];
        [downloadFolderPopUpButton selectItemAtIndex:0];
        [self menuNeedsUpdate:downloadFolderPopUpButtonMenu];
    }
    [openPanel autorelease]; // released
}


#pragma mark -
#pragma mark NSTextFieldDelegate

- (BOOL)control:(NSControl *)control textShouldEndEditing:(NSText *)fieldEditor {
    NSParameterAssert(control == homeURLStringTextField);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:FUHomeURLStringDidChangeNotification object:self];
    return YES;
}


#pragma mark -
#pragma mark NSMenuDelegate

- (NSInteger)numberOfItemsInMenu:(NSMenu *)menu {
    return NUM_MENU_ITEMS;
}


- (void)menuNeedsUpdate:(NSMenu *)menu {
    [downloadFolderPopUpButton removeAllItems];
    
    NSString *path = [[FUUserDefaults instance] downloadDirPath];
    NSMenuItem *item = [[[NSMenuItem alloc] initWithTitle:[path lastPathComponent]
                                                   action:nil
                                            keyEquivalent:@""] autorelease];
    NSImage *icon = [[NSWorkspace sharedWorkspace] iconForFile:path];
    [icon setScalesWhenResized:YES];
    [icon setSize:NSMakeSize(16, 16)];
    [item setImage:icon];
    [item setState:NSOffState];
    [item setEnabled:YES];
    [menu addItem:item];
    
    [menu addItem:[NSMenuItem separatorItem]];
    
    item = [[[NSMenuItem alloc] initWithTitle:NSLocalizedString(@"Other...", @"")
                                       action:@selector(runSelectDownloadFolderPanel:)
                                keyEquivalent:@""] autorelease];
    [item setTarget:self];
    [item setState:NSOffState];
    [item setEnabled:YES];
    [menu addItem:item];
}


// for bindings
- (NSString *)downloadFolderName {
    return [[[FUUserDefaults instance] downloadDirPath] lastPathComponent];
}

@synthesize homeURLStringTextField;
@synthesize recorderControl;
@synthesize downloadFolderPopUpButton;
@synthesize downloadFolderPopUpButtonMenu;
@synthesize busy;
@synthesize globalHotKey;
@end
