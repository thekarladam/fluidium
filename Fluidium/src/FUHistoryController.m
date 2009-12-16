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

#import "FUHistoryController.h"
#import "FUApplication.h"
#import "FUDocumentController.h"
#import <WebKit/WebKit.h>

#define NUM_STATIC_ITEMS 6
#define NUM_DAYS_STORED 7
#define MAX_VISIBLE_ITEMS 15

#define LOADING_TITLE NSLocalizedString(@"Loading... ", @"")

@interface FUHistoryController ()
- (void)setUpHistoryMenu;
- (void)setUpHistory;
- (BOOL)isDateToday:(NSCalendarDate *)day;
@end

@implementation FUHistoryController

+ (id)instance {
    static FUHistoryController *instance = nil;
    @synchronized (self) {
        if (!instance) {
            instance = [[FUHistoryController alloc] init];
        }
    }
    return instance;
}


- (id)init {
    if (self = [super init]) {
        [self setUpHistoryMenu];
        [self setUpHistory];
    }
    return self;
}


- (void)dealloc {
    self.webHistoryFilePath = nil;
    self.historyMenuObjects = nil;
    [super dealloc];
}


#pragma mark -
#pragma mark Actions

- (IBAction)historyItemClicked:(id)sender {
    WebHistoryItem *historyItem = [sender representedObject];
    
    FUDocumentController *dc = [FUDocumentController instance];
    WebView *webView = [dc frontWebView];
    
    if (!webView) {
        [dc newDocument:self];
        webView = [dc frontWebView];
    }
    
    [webView setMainFrameURL:[historyItem URLString]];
}


#pragma mark -

- (void)save {
    NSError *err = nil;
    [[WebHistory optionalSharedHistory] saveToURL:[NSURL fileURLWithPath:webHistoryFilePath] error:&err];
    
    if (err) {
        NSLog(@"Fluidium.app could not write history to disk");
    }
}


- (void)setUpHistoryMenu {
    NSMenu *historyMenu = [[[NSApp mainMenu] itemWithTitle:NSLocalizedString(@"History", @"")] submenu];
    [historyMenu setDelegate:self];
}


- (void)setUpHistory {
    WebHistory *history = [[[WebHistory alloc] init] autorelease];
    
    if ([[FUApplication instance] appSupportDirPath]) {
        
        NSString *path = [[[FUApplication instance] ssbSupportDirPath] stringByAppendingPathComponent:@"webhistory"];
        BOOL exists, isDir;
        exists = [[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDir];
        
        self.webHistoryFilePath = path;
        
        if (exists && !isDir) {
            NSError *err = nil;
            [history loadFromURL:[NSURL fileURLWithPath:path] error:&err];
            if (err) {
                NSLog(@"Fluidium.app encountered error reading webhistory on disk!");
                history = [[[WebHistory alloc] init] autorelease];
            }
        }
    }
    
    [history setHistoryAgeInDaysLimit:NUM_DAYS_STORED];
    [WebHistory setOptionalSharedHistory:history];
}


- (BOOL)isDateToday:(NSCalendarDate *)day {
    NSCalendarDate *today = [NSCalendarDate date];
    return [day dayOfMonth] == [today dayOfMonth] 
        && [day monthOfYear] == [today monthOfYear]
        && [day yearOfCommonEra] == [today yearOfCommonEra];
}


#pragma mark -
#pragma mark NSMenuDelegate

- (NSInteger)numberOfItemsInMenu:(NSMenu *)menu {    
    WebHistory *history = [WebHistory optionalSharedHistory];
    NSUInteger numDaysInHistory = [[history orderedLastVisitedDays] count];
    
    self.historyMenuObjects = [NSMutableArray array];
    
    if (!numDaysInHistory) {
        return NUM_STATIC_ITEMS;
    }
    
    NSArray *lastVisitedDays = [history orderedLastVisitedDays];
    if (![lastVisitedDays count]) {
        return NUM_STATIC_ITEMS;
    }
    
    NSCalendarDate *firstDate = [lastVisitedDays objectAtIndex:0];
    firstHistoryDateIsToday = [self isDateToday:firstDate];
    
    if (firstHistoryDateIsToday) {
        NSArray *todaysHistoryItems = [history orderedItemsLastVisitedOnDay:firstDate];
        for (WebHistoryItem *historyItem in todaysHistoryItems) {
            [historyMenuObjects addObject:historyItem];
            if ([historyMenuObjects count] >= MAX_VISIBLE_ITEMS) {
                break;
            }
        }
    }
    
    numIndividualItems = [historyMenuObjects count];
    
    for (NSCalendarDate *currDate in [history orderedLastVisitedDays]) {
        if (firstHistoryDateIsToday && currDate == firstDate) {
            if (numIndividualItems < MAX_VISIBLE_ITEMS) {
                continue;
            }
        }
        [historyMenuObjects addObject:currDate];
    }
    
    return NUM_STATIC_ITEMS + [historyMenuObjects count];    
}


- (BOOL)menu:(NSMenu *)menu updateItem:(NSMenuItem *)menuItem atIndex:(NSInteger)index shouldCancel:(BOOL)shouldCancel {
    index -= NUM_STATIC_ITEMS;
    
    if (index < 0) {
        return YES;
    }
    
    if (index < numIndividualItems) {
        WebHistoryItem *historyItem = [historyMenuObjects objectAtIndex:index];
        NSString *title = [historyItem title];
        
        if ([title hasPrefix:LOADING_TITLE]) {
            title = [title substringFromIndex:[LOADING_TITLE length]];
        }
        
        [menuItem setAction:@selector(historyItemClicked:)];
        [menuItem setTarget:self];
        if ([title length]) {
            [menuItem setTitle:title];
        } else {
            [menuItem setTitle:[historyItem originalURLString]];
        }
        [menuItem setImage:[historyItem icon]];
        [menuItem setRepresentedObject:historyItem];
        [menuItem setSubmenu:nil];
    } else {
        NSCalendarDate *day = [historyMenuObjects objectAtIndex:index];
        
        BOOL isEarlierTodaySubmenu = (index == numIndividualItems && firstHistoryDateIsToday && numIndividualItems == MAX_VISIBLE_ITEMS);
        
        NSString *submenuTitle = nil;
        if (isEarlierTodaySubmenu) {
            submenuTitle = NSLocalizedString(@"Earlier Today", @"");
        } else {
            submenuTitle = [day descriptionWithCalendarFormat:@"%A, %B %e" locale:[NSLocale systemLocale]]; 
        }
        
        [menuItem setTitle:submenuTitle];
        NSMenu *submenu = [[[NSMenu alloc] initWithTitle:submenuTitle] autorelease];
        [menuItem setSubmenu:submenu];
        
        NSArray *orderedItemsForDay = [[WebHistory optionalSharedHistory] orderedItemsLastVisitedOnDay:day];
        
        NSInteger i = -1;
        for (WebHistoryItem *subHistoryItem in orderedItemsForDay) {
            i++;
            
            // if first day, don't show the individual items already shown
            if (isEarlierTodaySubmenu) {
                if (i < MAX_VISIBLE_ITEMS) {
                    continue;
                }
            }
            
            NSString *title = [subHistoryItem title];
            if (!title) {
                title = @"";
            } else if ([title hasPrefix:LOADING_TITLE]) {
                title = [title substringFromIndex:[LOADING_TITLE length]];
            }
            
            NSMenuItem *submenuItem = [submenu addItemWithTitle:title
                                                         action:@selector(historyItemClicked:)
                                                  keyEquivalent:@""];
            [submenuItem setTarget:self];
            [submenuItem setImage:[subHistoryItem icon]];
            [submenuItem setRepresentedObject:subHistoryItem];
        }
    }
    
    return YES;
}

@synthesize webHistoryFilePath;
@synthesize historyMenuObjects;
@end
