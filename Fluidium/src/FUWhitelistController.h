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

#import <Foundation/Foundation.h>

@interface FUWhitelistController : NSObject {
    NSMutableArray *URLPatternStrings; // array of dicts: @"value" => @"*example.com*". these are dicts cuz they use bindings and undo in the UI
    NSMutableArray *URLPatterns;
    NSMutableArray *specialCaseURLPatterns;
    NSDate *lastDate;
    NSString *lastURLString;
}

+ (id)instance;

- (void)save;
- (void)loadURLPatterns;

//  if Fluid should handle this request, it returns YES. if not, it sends the request to the system and returns NO.
- (BOOL)processRequest:(NSURLRequest *)req;

- (BOOL)isRequestWhitelisted:(NSURLRequest *)req;
- (void)makeSystemHandleRequest:(NSURLRequest *)req;

@property (nonatomic, retain) NSMutableArray *URLPatternStrings;
@property (nonatomic, retain) NSMutableArray *URLPatterns;
@property (nonatomic, retain) NSArray *specialCaseURLPatterns;
@property (nonatomic, retain) NSDate *lastDate;
@property (nonatomic, copy) NSString *lastURLString;
@end
