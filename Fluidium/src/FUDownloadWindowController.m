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

#import "FUDownloadWindowController.h"
#import "FUDownloadItem.h"
#import "FUApplication.h"
#import "FUUserDefaults.h"
#import <WebKit/WebKit.h>

@interface FUDownloadWindowController ()
- (void)updateLabelTextField;
- (void)insertDownloadItem:(FUDownloadItem *)item;
- (FUDownloadItem *)downloadItemForURLDownload:(NSURLDownload *)download;
- (NSUInteger)indexForButton:(id)sender;
- (FUDownloadItem *)downloadItemForButton:(id)sender;
- (void)scrollToBottom;
@end

@implementation FUDownloadWindowController

+ (id)instance {
    static FUDownloadWindowController *instance = nil;
    @synchronized (self) {
        if (!instance) {
            instance = [[FUDownloadWindowController alloc] initWithWindowNibName:@"FUDownloadWindow"];
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

    self.collectionView = nil;
    self.scrollView = nil;
    self.arrayController = nil;
    self.statusBar = nil;
    self.labelTextField = nil;
    self.downloadItems = nil;
    self.indexForURLDownloadTable = nil;
    self.nextDestinationDirPath = nil;
    self.nextDestinationFilename = nil;
    [super dealloc];
}


- (void)awakeFromNib {
    self.indexForURLDownloadTable = [NSMutableDictionary dictionary];
    NSString *path = [[[FUApplication instance] downloadArchiveFilePath] stringByExpandingTildeInPath];
    NSArray *storedDownloads = [NSKeyedUnarchiver unarchiveObjectWithFile:path];
    self.downloadItems = [NSMutableArray array];

    for (FUDownloadItem *item in storedDownloads) {
        [self insertDownloadItem:item];
    }
    
    [collectionView setBackgroundColors:[NSColor controlAlternatingRowBackgroundColors]];

    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidBecomeKey:) name:NSWindowDidBecomeKeyNotification object:self.window];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(windowDidResignKey:) name:NSWindowDidResignKeyNotification object:self.window];
}


#pragma mark -
#pragma mark Actions

- (IBAction)stopDownload:(id)sender {
    FUDownloadItem *item = [self downloadItemForButton:sender];
    [item.download cancel];
    item.busy = NO;
    item.done = NO;
}


- (IBAction)resumeDownload:(id)sender {
    FUDownloadItem *item = [self downloadItemForButton:sender];
    if (!item.canResume) { NSBeep(); return; } 
    
    NSString *key = [item.download description];
    if (!key) { NSBeep(); return; } 
    
    NSData *resumeData = [item.download resumeData];
    if (!resumeData) { NSBeep(); return; } 

    [indexForURLDownloadTable removeObjectForKey:key];
    [arrayController removeObject:item];
    
    item.busy = YES;
    item.done = NO;
    
    NSURLDownload *newDownload = [[NSURLDownload alloc] initWithResumeData:resumeData delegate:self path:item.path];
    item.download = newDownload;
    [newDownload release];

    [self insertDownloadItem:item];
}


- (IBAction)revealDownloadInFinder:(id)sender {
    FUDownloadItem *item = [self downloadItemForButton:sender];
    [[NSWorkspace sharedWorkspace] selectFile:item.path inFileViewerRootedAtPath:@""];
}


- (IBAction)clearDownloads:(id)sender {
    [FUDownloadItem resetTagCount];
    
    NSEnumerator *e = [downloadItems reverseObjectEnumerator];
    FUDownloadItem *item = nil;
    
    while (item = [e nextObject]) {
        if (!item.busy) {
            [arrayController removeObject:item];
        }
    }
    
    self.indexForURLDownloadTable = [NSMutableDictionary dictionary];

    NSInteger i = 0;
    for (FUDownloadItem *item in downloadItems) {
        if (item.download) {
            [indexForURLDownloadTable setObject:[NSNumber numberWithInteger:i++] forKey:[item.download description]];
        }
    }

    [self updateLabelTextField];
}


#pragma mark -
#pragma mark NSWindowDelegate

- (void)windowDidBecomeKey:(NSNotification *)n {
    [statusBar setNeedsDisplay:YES];
}


- (void)windowDidResignKey:(NSNotification *)n {
    [statusBar setNeedsDisplay:YES];    
}


#pragma mark -
#pragma mark Private

- (void)save {
    if ([downloadItems count]) {
        if (![NSKeyedArchiver archiveRootObject:downloadItems toFile:[[FUApplication instance] downloadArchiveFilePath]]) {
            NSLog(@"Fluidium.app could not write download archive to disk");
        }
    }
}


- (void)updateLabelTextField {
    self.numberOfDownloadItems = [downloadItems count];    

    [labelTextField setStringValue:1 == numberOfDownloadItems ? NSLocalizedString(@"Download", @"") : NSLocalizedString(@"Downloads", @"")];
}


- (void)insertDownloadItem:(FUDownloadItem *)item {
    if (item) {
        NSInteger index = [downloadItems count];
        [arrayController addObject:item];
        
        if (item.download) {
            [indexForURLDownloadTable setObject:[NSNumber numberWithInteger:index] forKey:[item.download description]];
        }
    }
    [self updateLabelTextField];
}


- (FUDownloadItem *)downloadItemForURLDownload:(NSURLDownload *)download {
    id indexObj = [indexForURLDownloadTable objectForKey:[download description]];
    if (indexObj) {
        NSInteger index = [indexObj integerValue];
        return [[arrayController content] objectAtIndex:index];
    } else {
        return nil;
    }
}


- (NSUInteger)indexForButton:(id)sender {
    NSUInteger index = [[sender alternateTitle] integerValue];

    //NSLog(@"clicked: '%@',  %d", [sender alternateTitle], index);
    return index;
}


- (FUDownloadItem *)downloadItemForButton:(id)sender {
    return [[arrayController content] objectAtIndex:[self indexForButton:sender]];
}


- (void)scrollToBottom {
    NSPoint p = NSMakePoint(0.0, NSMaxY([[scrollView documentView] frame]) - NSHeight([[scrollView contentView] bounds]));
    [[scrollView contentView] scrollToPoint:p];
    [scrollView reflectScrolledClipView:[scrollView contentView]];
}


#pragma mark -
#pragma mark WebDownloadDelegate

- (NSWindow *)downloadWindowForAuthenticationSheet:(WebDownload *)download {
    return [self window];
}


#pragma mark -
#pragma mark NSURLDownloadDelegate

// this is also called when a download is resumed. WTF. have to handle that here.
- (void)downloadDidBegin:(NSURLDownload *)download {
    
    [self showWindow:self]; // this must come first. cuz sometimes this method is called before -awakeFromNib which must be called before this. this call triggers -awakeFromNib

    [download setDeletesFileUponFailure:NO];
    
    FUDownloadItem *item = [self downloadItemForURLDownload:download];
    if (!item) {
        item = [[[FUDownloadItem alloc] initWithURLDownload:download] autorelease];
        [self insertDownloadItem:item];
    }
    item.startDate = [NSDate date];
    item.busy = YES;
    item.done = NO;
    
    [self performSelector:@selector(scrollToBottom) withObject:nil afterDelay:.8];
}


- (NSURLRequest *)download:(NSURLDownload *)download willSendRequest:(NSURLRequest *)req redirectResponse:(NSURLResponse *)redirectResponse {
    return req;
}


- (void)download:(NSURLDownload *)download didReceiveResponse:(NSURLResponse *)response {    
    FUDownloadItem *item = [self downloadItemForURLDownload:download];
    
    item.receivedLength = 0;
    item.expectedLength = (NSUInteger)[response expectedContentLength];
}


- (void)download:(NSURLDownload *)download willResumeWithResponse:(NSURLResponse *)response fromByte:(long long)startingByte {
    FUDownloadItem *item = [self downloadItemForURLDownload:download];
    item.busy = YES;
    item.done = NO;
}


- (void)download:(NSURLDownload *)download didReceiveDataOfLength:(NSUInteger)length {
    FUDownloadItem *item = [self downloadItemForURLDownload:download];
    item.receivedLength = (item.receivedLength + length);
}


- (BOOL)download:(NSURLDownload *)download shouldDecodeSourceDataOfMIMEType:(NSString *)encodingType {
    return [NSURLDownload canResumeDownloadDecodedWithEncodingMIMEType:encodingType];
}


- (void)download:(NSURLDownload *)download decideDestinationWithSuggestedFilename:(NSString *)filename {
    BOOL isUserscript = NO;
    NSString *dirPath = nil;
    NSString *path = nil;
    if (nextDestinationDirPath && nextDestinationFilename) {
        dirPath = [[nextDestinationDirPath copy] autorelease];
        filename = [[nextDestinationFilename copy] autorelease];
        path = [dirPath stringByAppendingPathComponent:filename];
        self.nextDestinationDirPath = nil;
        self.nextDestinationFilename = nil;
    } else {
        if (isUserscript) {
            dirPath = [[FUApplication instance] userscriptDirPath];
        } else {
            dirPath = [[[FUUserDefaults instance] downloadDirPath] stringByExpandingTildeInPath];
        }
        
        path = [dirPath stringByAppendingPathComponent:filename];
        NSString *ext = [path pathExtension];
        NSString *filenameMinusExt = [filename substringToIndex:[filename rangeOfString:@"." options:NSBackwardsSearch].location];
        
        NSUInteger i = 0;
        while ([[NSFileManager defaultManager] fileExistsAtPath:path] && !isUserscript) {
            i++;
            
            NSRange range = NSMakeRange([filenameMinusExt length] - 2, 2);
            BOOL isAlreadyDashed = [[filenameMinusExt substringWithRange:range] hasPrefix:@"-"];
            if (isAlreadyDashed) {
                range = NSMakeRange(0, [filenameMinusExt length] - 2);
                filenameMinusExt = [filenameMinusExt substringWithRange:range];
            }
            filenameMinusExt = [NSString stringWithFormat:@"%@-%d", filenameMinusExt, i];
            
            filename = [filenameMinusExt stringByAppendingPathExtension:ext];
            path = [dirPath stringByAppendingPathComponent:filename];
        }
    }
    
    [download setDestination:path allowOverwrite:YES];

    FUDownloadItem *item = [self downloadItemForURLDownload:download];
    item.filename = filename;
    item.path = path;
    item.isUserscript = isUserscript;
}


- (void)downloadDidFinish:(NSURLDownload *)download {
    FUDownloadItem *item = [self downloadItemForURLDownload:download];
    item.busy = NO;
    item.done = YES;
}


- (void)download:(NSURLDownload *)download didFailWithError:(NSError *)error {
    FUDownloadItem *item = [self downloadItemForURLDownload:download];
    item.busy = NO;
    item.done = NO;
}

@synthesize collectionView;
@synthesize scrollView;
@synthesize arrayController;
@synthesize statusBar;
@synthesize labelTextField;
@synthesize downloadItems;
@synthesize indexForURLDownloadTable;
@synthesize numberOfDownloadItems;
@synthesize nextDestinationDirPath;
@synthesize nextDestinationFilename;
@end
    