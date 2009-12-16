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

#import "FUViewSourceWindowController.h"
#import "TDSourceCodeTextView.h"
#import "TDHtmlSyntaxHighlighter.h"

@interface FUViewSourceWindowController ()
@end

@implementation FUViewSourceWindowController

- (id)init {
    self = [super initWithWindowNibName:@"FUViewSourceWindow"];
    if (self != nil) {
        self.monacoFont = [NSFont fontWithName:@"Monaco" size:11];
        self.highlighter = [[[TDHtmlSyntaxHighlighter alloc] initWithAttributesForDarkBackground:YES] autorelease];
    }
    return self;
}


- (void)dealloc {
    self.sourceTextView = nil;
    self.URLString = nil;
    self.source = nil;
    self.monacoFont = nil;
    self.highlighter = nil;
    [super dealloc];
}


#pragma mark -
#pragma mark Actions

- (void)showWindow:(id)sender {
    [super showWindow:sender];
    [sourceTextView renderGutter];
}


- (IBAction)addNewTabInForeground:(id)sender {
    [self runFontPanel:sender];
}


- (IBAction)runFontPanel:(id)sender {    
    NSFont *font = [sourceTextView font];
    NSFontManager *fontMgr = [NSFontManager sharedFontManager];
    [fontMgr setSelectedFont:font isMultiple:NO];
    
    NSFontPanel *fontPanel = [fontMgr fontPanel:YES];
    
    if (![fontPanel isVisible]) {
        [fontPanel orderFront:sender];
    }
}


- (IBAction)showFindPanelAction:(id)sender {
    [sourceTextView performFindPanelAction:sender];
}


- (IBAction)find:(id)sender {
    [sourceTextView performFindPanelAction:sender];
}


- (IBAction)useSelectionForFind:(id)sender {
    self.tag = 7; // NSFindPanelActionSetFindString
    [sourceTextView performFindPanelAction:self];
    [sourceTextView performFindPanelAction:sender];
}


#pragma mark -
#pragma mark Public

- (void)displaySourceString:(NSString *)s {
    self.source = [highlighter attributedStringForString:s];
    
//    NSDictionary *attrs = [NSDictionary dictionaryWithObjectsAndKeys:
//                           [NSFont fontWithName:@"Monaco" size:11], NSFontAttributeName,
//                           [NSColor whiteColor], NSForegroundColorAttributeName,
//                           nil];
//    
//    self.source = [[[NSAttributedString alloc] initWithString:s attributes:attrs] autorelease];
}

@synthesize sourceTextView;
@synthesize monacoFont;
@synthesize URLString;
@synthesize source;
@synthesize highlighter;
@synthesize tag;
@end
