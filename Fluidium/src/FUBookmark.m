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

#import "FUBookmark.h"

@implementation FUBookmark

- (id)init {
    if (self = [super init]) {
        self.title = NSLocalizedString(@"Untitled", @"");
        self.content = @"";
    }
    return self;
}


- (void)dealloc {
    self.title = nil;
    self.content = nil;
    [super dealloc];
}


#pragma mark -
#pragma mark NSCoding

- (id)initWithCoder:(NSCoder *)coder {
    [super init];
    self.title = [coder decodeObjectForKey:@"title"];
    self.content = [coder decodeObjectForKey:@"content"];
    return self;
}


- (void)encodeWithCoder:(NSCoder *)coder {
    [coder encodeObject:title forKey:@"title"];
    [coder encodeObject:content forKey:@"content"];
}


- (NSString *)description {
    return [NSString stringWithFormat:@"<FUBookmark: %@>", title];
}

@synthesize title;
@synthesize content;
@end
