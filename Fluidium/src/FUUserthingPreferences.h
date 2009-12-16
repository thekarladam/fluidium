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

#import "FUBasePreferences.h"

// Abstract base class for FUUserthingPreferences and FUUserstylePreferences
@interface FUUserthingPreferences : FUBasePreferences {
    NSArrayController *arrayController;
    NSTextView *textView;
    NSMutableArray *userthings;
}

- (void)insertObject:(NSMutableDictionary *)dict inUserthingsAtIndex:(NSInteger)i;
- (void)removeObjectFromUserthingsAtIndex:(NSInteger)i;

- (void)startObservingRule:(NSMutableDictionary *)rule;
- (void)stopObservingRule:(NSMutableDictionary *)rule;

- (void)loadUserthings;
- (void)storeUserthings;
    
@property (nonatomic, retain) IBOutlet NSArrayController *arrayController;
@property (nonatomic, retain) IBOutlet NSTextView *textView;
@property (nonatomic, retain) NSMutableArray *userthings;
@end
