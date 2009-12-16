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

#import <Cocoa/Cocoa.h>

@class TDSourceCodeTextView;
@class TDHtmlSyntaxHighlighter;

@interface FUViewSourceWindowController : NSWindowController {
    TDSourceCodeTextView *sourceTextView;
    
    NSString *URLString;
    NSAttributedString *source;
    NSFont *monacoFont;
    CGFloat sourceTextViewOffset;
    TDHtmlSyntaxHighlighter *highlighter;
    NSInteger tag;
}

- (IBAction)addNewTabInForeground:(id)sender;
- (IBAction)runFontPanel:(id)sender;
- (IBAction)showFindPanelAction:(id)sender;
- (IBAction)find:(id)sender;
- (IBAction)useSelectionForFind:(id)sender;

- (void)displaySourceString:(NSString *)s;

@property (nonatomic, retain) IBOutlet TDSourceCodeTextView *sourceTextView;
@property (nonatomic, copy) NSString *URLString;
@property (nonatomic, retain) NSAttributedString *source;
@property (nonatomic, retain) NSFont *monacoFont;
@property (nonatomic, retain) TDHtmlSyntaxHighlighter *highlighter;
@property (nonatomic) NSInteger tag;
@end
