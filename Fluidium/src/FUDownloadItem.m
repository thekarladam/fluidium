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

#import "FUDownloadItem.h"

static NSUInteger sTagCount;

@interface FUDownloadItem ()
- (void)lengthDidChange;
- (void)determineRemainingTimeString;
@end

@implementation FUDownloadItem

+ (void)initialize {
    if ([FUDownloadItem class] == self) {
        [self resetTagCount];
    }
}


+ (void)resetTagCount {
    sTagCount = -1;
}


- (id)initWithURLDownload:(NSURLDownload *)aDownload {
    self = [super init];
    if (self != nil) {
        self.download = aDownload;
        self.tagString = [NSString stringWithFormat:@"%d", ++sTagCount];
        self.URL = [[aDownload request] URL];
        self.filename = [[URL absoluteString] lastPathComponent];
        self.expectedLength = 0;
        self.receivedLength = 0;
        self.icon = [[NSWorkspace sharedWorkspace] iconForFileType:[[URL absoluteString] pathExtension]];
        self.done = NO;
        self.busy = NO;
        self.canResume = YES;

        [self addObserver:self forKeyPath:@"receivedLength" options:NSKeyValueObservingOptionNew context:NULL];
        [self addObserver:self forKeyPath:@"expectedLength" options:NSKeyValueObservingOptionNew context:NULL];
        [self addObserver:self forKeyPath:@"done" options:NSKeyValueObservingOptionNew context:NULL];
    }
    return self;
}


- (void)dealloc {
    [self removeObserver:self forKeyPath:@"receivedLength"];
    [self removeObserver:self forKeyPath:@"expectedLength"];
    [self removeObserver:self forKeyPath:@"done"];
    
    self.startDate = nil;
    self.lastDisplayDate = nil;
    self.tagString = nil;
    self.URL = nil;
    self.download = nil;
    self.filename = nil;
    self.path = nil;
    self.icon = nil;
    self.status = nil;
    self.remainingTimeString = nil;
    [super dealloc];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:@"receivedLength"] || [keyPath isEqualToString:@"expectedLength"] || [keyPath isEqualToString:@"done"]) {
        [self lengthDidChange];
    }
}


- (NSString *)description {
    return [NSString stringWithFormat:@"<FUDownloadItem %p \n\tfilename: %@, \n\tpath: %@, \n\tURL: %@, \n\treceivedLength: %f, \n\texpectedLength: %f>", self, filename, path, URL, receivedLength, expectedLength];
}


#pragma mark -
#pragma mark NSCoding

- (id)initWithCoder:(NSCoder *)coder {
    [super init];
    self.tagString = [coder decodeObjectForKey:@"tagString"]; ++sTagCount;
    self.URL = [coder decodeObjectForKey:@"URL"];
    self.filename = [coder decodeObjectForKey:@"filename"];
    self.path = [coder decodeObjectForKey:@"path"];
    self.icon = [coder decodeObjectForKey:@"icon"];
    self.expectedLength = [coder decodeIntegerForKey:@"expectedLength"];
    self.receivedLength = [coder decodeIntegerForKey:@"receivedLength"];
    self.done = [coder decodeBoolForKey:@"done"];
    self.busy = NO;
    self.canResume = NO;
    return self;
}


- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:tagString forKey:@"tagString"];
    [coder encodeObject:URL forKey:@"URL"];
    [coder encodeObject:filename forKey:@"filename"];
    [coder encodeObject:path forKey:@"path"];
    [coder encodeObject:icon forKey:@"icon"];
    [coder encodeInteger:expectedLength forKey:@"expectedLength"];
    [coder encodeInteger:receivedLength forKey:@"receivedLength"];
    [coder encodeBool:done forKey:@"done"];
}


#pragma mark -
#pragma mark Private

- (void)determineRemainingTimeString {

    // dont change in less that a second

    if (lastDisplayDate) {
        if (abs([lastDisplayDate timeIntervalSinceNow]) < 1.) {
            return;
        }
    }
    self.lastDisplayDate = [NSDate date];

    
    
    CGFloat secondsSinceStart = ceil(abs([startDate timeIntervalSinceNow]));

    if (secondsSinceStart < 10) { // seems very unreliable for first few seconds. so return nothing.
        self.remainingTimeString = @"";
        return;
    }
    
    CGFloat totalExpectedTime = secondsSinceStart / ratio;
    CGFloat remaingSeconds = totalExpectedTime - secondsSinceStart;
    
    if (remaingSeconds < 2) { // show nothing for less that 2 seconds
        self.remainingTimeString = @"";
    } else if (remaingSeconds < 60) { // seconds
        self.remainingTimeString = [NSString stringWithFormat:@" – %.0f seconds remaining", remaingSeconds];
    } else { // minutes
        NSInteger minutes = floor(remaingSeconds / 60);
        if (minutes <= 1) {
            self.remainingTimeString = @" – 1 minute remaining";
        } else {
            self.remainingTimeString = [NSString stringWithFormat:@" – %d minutes remaining", minutes];
        }
    }
}


- (void)lengthDidChange {
    if (receivedLength > expectedLength) {
        expectedLength = receivedLength;
    }
    
    if (expectedLength > 0) {
        self.ratio = (CGFloat)((CGFloat)receivedLength / (CGFloat)expectedLength);
    } else {
        self.ratio = 0;
    }
    
    NSString *units = nil;
    NSString *fmt = nil;
    CGFloat displayedReceivedLength = 0;
    CGFloat displayedExpectedLength = 0;
    CGFloat divisor = 0;
        
    if (expectedLength != -1 && expectedLength > (1024 * 1024)) {
        units = @"MB";
        fmt = done ? @"%.1f %@" : @"%.1f of %.1f %@%@";
        divisor = (CGFloat)(1024 * 1024);
    } else {
        units = @"KB";
        fmt = done ?  @"%.1f %@" : @"%.1f of %.1f %@%@";
        divisor = (CGFloat)1024;
    } 
    displayedReceivedLength = (CGFloat)((CGFloat)receivedLength / divisor);
    displayedExpectedLength = (CGFloat)((CGFloat)expectedLength / divisor);
    
    if (self.done) {
        self.status = [NSString stringWithFormat:fmt, displayedReceivedLength, units];
    } else {
        if (self.busy) {
            [self determineRemainingTimeString];
            self.status = [NSString stringWithFormat:fmt, displayedReceivedLength, displayedExpectedLength, units, remainingTimeString];
        } else {
            self.status = [NSString stringWithFormat:fmt, displayedReceivedLength, displayedExpectedLength, units, @""];
        }
    }
}

@synthesize startDate;
@synthesize lastDisplayDate;
@synthesize tagString;
@synthesize URL;
@synthesize download;
@synthesize filename;
@synthesize path;
@synthesize remainingTimeString;
@synthesize status;
@synthesize icon;
@synthesize expectedLength;
@synthesize receivedLength;
@synthesize ratio;
@synthesize isUserscript;
@synthesize busy;
@synthesize done;
@synthesize canResume;
@end
