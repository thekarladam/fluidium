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

#import "FUWhitelistPreferences.h"
#import "FUWhitelistController.h"
#import "FUApplication.h"

@interface FUWhitelistPreferences ()
- (void)changeKeyPath:(NSString *)keyPath ofObject:(id)obj toValue:(id)inValue;
@end

@implementation FUWhitelistPreferences

- (void)dealloc {
    self.arrayController = nil;
    self.textView = nil;
    self.URLPatternStrings = nil;
    [super dealloc];
}


- (void)awakeFromNib {
    [self loadURLPatternStrings];
}


- (void)insertObject:(NSMutableDictionary *)dict inURLPatternStringsAtIndex:(NSInteger)i {
    NSUndoManager *undoManager = [[[self controlBox] window] undoManager];
    [[undoManager prepareWithInvocationTarget:self] removeObjectFromURLPatternStringsAtIndex:i];
    
    [self startObservingRule:dict];
    [self.URLPatternStrings insertObject:dict atIndex:i];
    [self storeURLPatternStrings];
}


- (void)removeObjectFromURLPatternStringsAtIndex:(NSInteger)i {
    NSMutableDictionary *rule = [self.URLPatternStrings objectAtIndex:i];
    
    NSUndoManager *undoManager = [[[self controlBox] window] undoManager];
    [[undoManager prepareWithInvocationTarget:self] insertObject:rule inURLPatternStringsAtIndex:i];
    
    [self stopObservingRule:rule];
    [self.URLPatternStrings removeObjectAtIndex:i];
    [self storeURLPatternStrings];
}


- (void)startObservingRule:(NSMutableDictionary *)rule {
    [rule addObserver:self
           forKeyPath:@"value"
              options:NSKeyValueObservingOptionOld
              context:NULL];
}


- (void)stopObservingRule:(NSMutableDictionary *)rule {
    [rule removeObserver:self forKeyPath:@"value"];
}


- (void)changeKeyPath:(NSString *)keyPath ofObject:(id)obj toValue:(id)v {
    [obj setValue:v forKeyPath:keyPath];
    [self storeURLPatternStrings];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)obj change:(NSDictionary *)change context:(void *)ctx {
    NSUndoManager *undoManager = [[[self controlBox] window] undoManager];
    id oldValue = [change objectForKey:NSKeyValueChangeOldKey];
    [[undoManager prepareWithInvocationTarget:self] changeKeyPath:keyPath ofObject:obj toValue:oldValue];
    [self storeURLPatternStrings];
}


- (void)controlTextDidEndEditing:(NSNotification *)n {
    [self storeURLPatternStrings];
}


- (void)loadURLPatternStrings {
    self.URLPatternStrings = [[FUWhitelistController instance] URLPatternStrings];
}


- (void)storeURLPatternStrings {
    [[FUWhitelistController instance] setURLPatternStrings:URLPatternStrings];
    [[FUWhitelistController instance] save];
    [[FUWhitelistController instance] loadURLPatterns]; // regenerates pattern objs from strings
}


- (void)setURLPatternStrings:(NSMutableArray *)new {
    NSMutableArray *old = URLPatternStrings;
    
    if (old != new) {
        for (id rule in old) {
            [self stopObservingRule:rule];
        }
        
        [old autorelease];
        URLPatternStrings = [new retain];
        [self storeURLPatternStrings];
        
        for (id rule in new) {
            [self startObservingRule:rule];
        }
    }
}

@synthesize arrayController;
@synthesize textView;
@synthesize URLPatternStrings;
@end
