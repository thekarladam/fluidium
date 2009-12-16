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

#import "FUShortcutPreferences.h"
#import "FUUserDefaults.h"

@interface FUShortcutPreferences ()
- (void)storeShortcutsInUserDefaults;
- (void)startObservingRule:(NSMutableDictionary *)rule;
- (void)stopObservingRule:(NSMutableDictionary *)rule;
- (void)changeKeyPath:(NSString *)keyPath ofObject:(id)obj toValue:(id)inValue;
@end

@implementation FUShortcutPreferences

- (void)dealloc {
    self.arrayController = nil;
    self.shortcuts = nil;
    [super dealloc];
}


- (void)insertObject:(NSMutableDictionary *)dict inShortcutsAtIndex:(NSInteger)i {
    NSUndoManager *undoManager = [[[self controlBox] window] undoManager];
    [[undoManager prepareWithInvocationTarget:self] removeObjectFromShortcutsAtIndex:i];
    
    [self startObservingRule:dict];
    [self.shortcuts insertObject:dict atIndex:i];
    [self storeShortcutsInUserDefaults];
}


- (void)removeObjectFromShortcutsAtIndex:(NSInteger)i {
    NSMutableDictionary *rule = [self.shortcuts objectAtIndex:i];
    
    NSUndoManager *undoManager = [[[self controlBox] window] undoManager];
    [[undoManager prepareWithInvocationTarget:self] insertObject:rule inShortcutsAtIndex:i];
    
    [self stopObservingRule:rule];
    [self.shortcuts removeObjectAtIndex:i];
    [self storeShortcutsInUserDefaults];
}


- (void)storeShortcutsInUserDefaults {
    [[FUUserDefaults instance] setShortcuts:self.shortcuts];
}


- (void)startObservingRule:(NSMutableDictionary *)rule {
    [rule addObserver:self
           forKeyPath:@"URLPattern"
              options:NSKeyValueObservingOptionOld
              context:NULL];
    [rule addObserver:self
           forKeyPath:@"query"
              options:NSKeyValueObservingOptionOld
              context:NULL];
}


- (void)stopObservingRule:(NSMutableDictionary *)rule {
    [rule removeObserver:self forKeyPath:@"URLPattern"];
    [rule removeObserver:self forKeyPath:@"query"];
}


- (void)changeKeyPath:(NSString *)keyPath ofObject:(id)obj toValue:(id)inValue {
    [obj setValue:inValue forKeyPath:keyPath];
    [self storeShortcutsInUserDefaults];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)obj change:(NSDictionary *)change context:(void *)context {
    NSUndoManager *undoManager = [[[self controlBox] window] undoManager];
    id oldValue = [change objectForKey:NSKeyValueChangeOldKey];
    [[undoManager prepareWithInvocationTarget:self] changeKeyPath:keyPath ofObject:obj toValue:oldValue];
    [self storeShortcutsInUserDefaults];
}


- (void)controlTextDidEndEditing:(NSNotification *)notification {
    [self storeShortcutsInUserDefaults];
}


- (NSMutableArray *)shortcuts {
    if (!shortcuts) {
        self.shortcuts = [NSMutableArray arrayWithArray:[[FUUserDefaults instance] shortcuts]];
        if (![shortcuts count]) {
            NSString *path = [[NSBundle mainBundle] pathForResource:@"Shortcuts" ofType:@"plist"];
            NSDictionary *dict = [NSMutableDictionary dictionaryWithContentsOfFile:path];
            self.shortcuts = [NSMutableArray arrayWithArray:[dict objectForKey:@"FUShortcuts"]];
        }        
    }
    return [[shortcuts retain] autorelease];
}


- (void)setShortcuts:(NSMutableArray *)a {
    if (shortcuts != a) {
        for (id rule in shortcuts) {
            [self stopObservingRule:rule];
        }
        
        [shortcuts autorelease];
        shortcuts = [a retain];
        
        for (id rule in shortcuts) {
            [self startObservingRule:rule];
        }
    }
}

@synthesize arrayController;
@end
