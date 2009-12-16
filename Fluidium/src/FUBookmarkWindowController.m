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

#import "FUBookmarkWindowController.h"
#import "FUBookmark.h"
#import "FUBookmarkController.h"

@interface FUBookmarkWindowController ()
- (void)postBookmarksChangedNotification;
- (void)bookmarksChanged:(NSNotification *)n;
- (void)update;

- (void)insertObject:(FUBookmark *)bookmark inBookmarksAtIndex:(NSInteger)index;
- (void)removeObjectFromBookmarksAtIndex:(NSInteger)index;
- (void)startObservingBookmark:(FUBookmark *)bookmark;
- (void)stopObservingBookmark:(FUBookmark *)bookmark;
@end

@implementation FUBookmarkWindowController

+ (id)instance {    
    static FUBookmarkWindowController *instance = nil;
    @synchronized (self) {
        if (!instance) {
            instance = [[FUBookmarkWindowController alloc] initWithWindowNibName:@"FUBookmarkWindow"];
        }
    }
    return instance;
}


- (id)initWithWindowNibName:(NSString *)name {    
    if (self = [super initWithWindowNibName:name]) {

    }
    return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];

    self.tableView = nil;
    self.arrayController = nil;
    [super dealloc];
}


- (void)awakeFromNib {
    NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
    [nc addObserver:self selector:@selector(bookmarksChanged:) name:FUBookmarksChangedNotification object:nil];
}


#pragma mark -
#pragma mark Actions

- (IBAction)insert:(id)sender {
    [arrayController insert:sender];
    [self performSelector:@selector(postBookmarksChangedNotification) withObject:nil afterDelay:0];
}


- (IBAction)remove:(id)sender {
    [arrayController remove:sender];
    [self performSelector:@selector(postBookmarksChangedNotification) withObject:nil afterDelay:0];
}


#pragma mark -
#pragma mark Public

- (void)appendBookmark:(FUBookmark *)b {
    [arrayController addObject:b];
}


- (void)insertBookmark:(FUBookmark *)b atIndex:(NSInteger)i {
    [arrayController insertObject:b atArrangedObjectIndex:i];
}


- (void)removeBookmark:(FUBookmark *)b {
    [arrayController removeObject:b];
}


- (NSMutableArray *)bookmarks {
    return [[FUBookmarkController instance] bookmarks];
}


#pragma mark -
#pragma mark Private

- (void)update {
    for (FUBookmark *bookmark in self.bookmarks) {
        [self startObservingBookmark:bookmark];
    }
    
    [arrayController setContent:self.bookmarks];
    
    [tableView reloadData];
    [tableView setNeedsDisplay:YES];
}


#pragma mark -
#pragma mark ArrayController / Undo

- (void)insertObject:(FUBookmark *)bookmark inBookmarksAtIndex:(NSInteger)index {
    NSUndoManager *undo = [[self window] undoManager];
    [[undo prepareWithInvocationTarget:self] removeObjectFromBookmarksAtIndex:index];

    [self startObservingBookmark:bookmark];
    [self.bookmarks insertObject:bookmark atIndex:index];
}


- (void)removeObjectFromBookmarksAtIndex:(NSInteger)index {
    FUBookmark *bookmark = [self.bookmarks objectAtIndex:index];
    
    NSUndoManager *undo = [[self window] undoManager];
    [[undo prepareWithInvocationTarget:self] insertObject:bookmark inBookmarksAtIndex:index];
    
    [self stopObservingBookmark:bookmark];
    [self.bookmarks removeObjectAtIndex:index];
}


- (void)startObservingBookmark:(FUBookmark *)bookmark {
    [bookmark addObserver:self
               forKeyPath:@"title"
                  options:NSKeyValueObservingOptionOld
                  context:NULL];

    [bookmark addObserver:self
               forKeyPath:@"content"
                  options:NSKeyValueObservingOptionOld
                  context:NULL];
}


- (void)stopObservingBookmark:(FUBookmark *)bookmark {
    [bookmark removeObserver:self forKeyPath:@"title"];
    [bookmark removeObserver:self forKeyPath:@"content"];
}


- (void)changeKeyPath:(NSString *)keyPath ofObject:(id)obj toValue:(id)newValue {
    [obj setValue:newValue forKeyPath:keyPath];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)obj change:(NSDictionary *)change context:(void *)context {
    NSUndoManager *undo = [[self window] undoManager];
    id oldValue = [change objectForKey:NSKeyValueChangeOldKey];
    [[undo prepareWithInvocationTarget:self] changeKeyPath:keyPath ofObject:obj toValue:oldValue];
}


#pragma mark -
#pragma mark Notifications

- (void)bookmarksChanged:(NSNotification *)n {
    [self update];
}


- (void)postBookmarksChangedNotification {
    [[NSNotificationCenter defaultCenter] postNotificationName:FUBookmarksChangedNotification object:nil];
}


- (void)windowDidBecomeKey:(NSNotification *)n {
    [self update];
}


- (void)windowDidResignKey:(NSNotification *)n {
    [self postBookmarksChangedNotification];
}

@synthesize tableView;
@synthesize arrayController;
@end
