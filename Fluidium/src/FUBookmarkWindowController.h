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

@class FUBookmark;

@interface FUBookmarkWindowController : NSWindowController {
    NSTableView *tableView;
    NSArrayController *arrayController;
}

+ (id)instance;

- (IBAction)insert:(id)sender;
- (IBAction)remove:(id)sender;

- (void)appendBookmark:(FUBookmark *)b;
- (void)insertBookmark:(FUBookmark *)b atIndex:(NSInteger)i;
- (void)removeBookmark:(FUBookmark *)b;

@property (nonatomic, retain) IBOutlet NSTableView *tableView;
@property (nonatomic, retain) IBOutlet NSArrayController *arrayController;
@property (nonatomic, retain, readonly) NSMutableArray *bookmarks;
@end
