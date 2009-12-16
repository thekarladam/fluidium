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

#import "FUBookmarkBarOverflowButton.h"

@interface FUBookmarkBarOverflowButton (Private)
- (void)killTimer;
@end

@implementation FUBookmarkBarOverflowButton

- (id)init {
    if (self = [super init]) {
        [self setImage:[NSImage imageNamed:@"OverflowButton"]];
        [self setTitle:nil];
        [self setBordered:NO];
        [self sizeToFit];
    }
    return self;
}


- (void)dealloc {
    [self killTimer];
    [super dealloc];
}


- (void)killTimer {
    if (timer) {
        [timer invalidate];
        self.timer = nil;
    }
}


- (void)displayMenu:(NSTimer *)theTimer {
    NSEvent *evt = [timer userInfo];
    
    NSInteger y = NSMinY([[self superview] frame]) + NSMinY([self frame]);
    NSEvent *click = [NSEvent mouseEventWithType:[evt type] 
                                        location:NSMakePoint(NSMinX([self frame]), y) 
                                   modifierFlags:[evt modifierFlags] 
                                       timestamp:[evt timestamp] 
                                    windowNumber:[evt windowNumber] 
                                         context:[evt context]
                                     eventNumber:[evt eventNumber] 
                                      clickCount:[evt clickCount] 
                                        pressure:[evt pressure]]; 

    [NSMenu popUpContextMenu:[self menu] withEvent:click forView:self];
    [self killTimer];
}   


- (void)mouseDown:(NSEvent *)evt { 
    [self highlight:NO];
    [self setImage:[NSImage imageNamed:@"OverflowButtonPressed"]];
    
    self.timer = [NSTimer timerWithTimeInterval:0.0 
                                         target:self 
                                       selector:@selector(displayMenu:) 
                                       userInfo:evt 
                                        repeats:NO];

    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
} 


- (void)mouseUp:(NSEvent *)evt { 
    [self unhighlight];
}


- (void)unhighlight {
    [self highlight:NO];
    [self setImage:[NSImage imageNamed:@"OverflowButton"]];
}


- (NSImage *)imageNamed:(NSString *)name {
    NSBundle *bundle = [NSBundle bundleForClass:[FUBookmarkBarOverflowButton class]];
    return [[[NSImage alloc] initByReferencingFile:[bundle pathForImageResource:name]] autorelease];
}

@synthesize timer;
@end
