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

@interface FUDownloadItem : NSObject <NSCoding> {
    NSDate *startDate;
    NSDate *lastDisplayDate;
    NSString *tagString;
    NSURL *URL;
    NSURLDownload *download;
    NSString *filename;
    NSString *path;
    NSImage *icon;
    NSString *status;
    NSString *remainingTimeString;
    NSUInteger expectedLength;
    NSUInteger receivedLength;
    CGFloat ratio;
    BOOL isUserscript;
    BOOL busy;
    BOOL done;
    BOOL canResume;
}

+ (void)resetTagCount;

- (id)initWithURLDownload:(NSURLDownload *)aDownload;

@property (nonatomic, retain) NSDate *startDate;
@property (nonatomic, retain) NSDate *lastDisplayDate;
@property (nonatomic, copy) NSString *tagString;
@property (nonatomic, retain) NSURL *URL;
@property (nonatomic, retain) NSURLDownload *download;
@property (nonatomic, copy) NSString *filename;
@property (nonatomic, copy) NSString *path;
@property (nonatomic, copy) NSString *status;
@property (nonatomic, copy) NSString *remainingTimeString;
@property (nonatomic, retain) NSImage *icon;
@property (nonatomic) NSUInteger expectedLength;
@property (nonatomic) NSUInteger receivedLength;
@property (nonatomic) CGFloat ratio;
@property (nonatomic) BOOL isUserscript;
@property (nonatomic) BOOL busy;
@property (nonatomic) BOOL done;
@property (nonatomic) BOOL canResume;
@end
