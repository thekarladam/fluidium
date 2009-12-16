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

#import "FUUserthingPreferences.h"
#import "FUApplication.h"

@interface FUUserthingPreferences ()
- (void)changeKeyPath:(NSString *)keyPath ofObject:(id)obj toValue:(id)inValue;
@end

@implementation FUUserthingPreferences

- (void)dealloc {
    self.arrayController = nil;
    self.textView = nil;
    self.userthings = nil;
    [super dealloc];
}


- (void)awakeFromNib {
    [textView setFont:[NSFont fontWithName:@"Monaco" size:10]];
    [self loadUserthings];
}


- (void)insertObject:(NSMutableDictionary *)dict inUserthingsAtIndex:(NSInteger)i {
    NSUndoManager *undoManager = [[[self controlBox] window] undoManager];
    [[undoManager prepareWithInvocationTarget:self] removeObjectFromUserthingsAtIndex:i];
    
    [self startObservingRule:dict];
    [self.userthings insertObject:dict atIndex:i];
    [self storeUserthings];
}


- (void)removeObjectFromUserthingsAtIndex:(NSInteger)i {
    NSMutableDictionary *rule = [self.userthings objectAtIndex:i];
    
    NSUndoManager *undoManager = [[[self controlBox] window] undoManager];
    [[undoManager prepareWithInvocationTarget:self] insertObject:rule inUserthingsAtIndex:i];
    
    [self stopObservingRule:rule];
    [self.userthings removeObjectAtIndex:i];
    [self storeUserthings];
}


- (void)startObservingRule:(NSMutableDictionary *)rule {
    [rule addObserver:self
           forKeyPath:@"URLPattern"
              options:NSKeyValueObservingOptionOld
              context:NULL];
    [rule addObserver:self
           forKeyPath:@"source"
              options:NSKeyValueObservingOptionOld
              context:NULL];
    [rule addObserver:self
           forKeyPath:@"enabled"
              options:NSKeyValueObservingOptionOld
              context:NULL];
}


- (void)stopObservingRule:(NSMutableDictionary *)rule {
    [rule removeObserver:self forKeyPath:@"URLPattern"];
    [rule removeObserver:self forKeyPath:@"source"];
    [rule removeObserver:self forKeyPath:@"enabled"];
}


- (void)changeKeyPath:(NSString *)keyPath ofObject:(id)obj toValue:(id)v {
    [obj setValue:v forKeyPath:keyPath];
    [self storeUserthings];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)obj change:(NSDictionary *)change context:(void *)ctx {
    NSUndoManager *undoManager = [[[self controlBox] window] undoManager];
    id oldValue = [change objectForKey:NSKeyValueChangeOldKey];
    [[undoManager prepareWithInvocationTarget:self] changeKeyPath:keyPath ofObject:obj toValue:oldValue];
    [self storeUserthings];
}


- (void)controlTextDidEndEditing:(NSNotification *)n {
    [self storeUserthings];
}


#pragma mark -
#pragma mark Abstract

- (void)loadUserthings {
    NSAssert(0, @"must override");
}


- (void)storeUserthings {
    NSAssert(0, @"must override");
}


- (void)setUserthings:(NSMutableArray *)a {
    NSAssert(0, @"must override");
}

@synthesize arrayController;
@synthesize textView;
@synthesize userthings;
@end
