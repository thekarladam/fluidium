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

@interface FUDownloadWindowController : NSWindowController {
    NSCollectionView *collectionView;
    NSScrollView *scrollView;
    NSArrayController *arrayController;
    NSView *statusBar;
    NSTextField *labelTextField;
    
    NSMutableArray *downloadItems;
    NSMutableDictionary *indexForURLDownloadTable;
    NSUInteger numberOfDownloadItems;

    NSString *nextDestinationDirPath;
    NSString *nextDestinationFilename;
}

+ (id)instance;

- (IBAction)stopDownload:(id)sender;
- (IBAction)resumeDownload:(id)sender;
- (IBAction)revealDownloadInFinder:(id)sender;
- (IBAction)clearDownloads:(id)sender;

- (void)save;

@property (nonatomic, retain) IBOutlet NSCollectionView *collectionView;
@property (nonatomic, retain) IBOutlet NSScrollView *scrollView;
@property (nonatomic, retain) IBOutlet NSArrayController *arrayController;
@property (nonatomic, retain) IBOutlet NSView *statusBar;
@property (nonatomic, retain) IBOutlet NSTextField *labelTextField;
@property (nonatomic, retain) NSMutableArray *downloadItems;
@property (nonatomic, retain) NSMutableDictionary *indexForURLDownloadTable;
@property NSUInteger numberOfDownloadItems;

@property (nonatomic, copy) NSString *nextDestinationDirPath;
@property (nonatomic, copy) NSString *nextDestinationFilename;
@end
