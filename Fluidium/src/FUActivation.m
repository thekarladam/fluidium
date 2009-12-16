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

#import "FUActivation.h"
#import "FUUtils.h"
#import "NSEvent+FUAdditions.h"
#import <WebKit/WebKit.h>

@interface FUActivation ()
@property (nonatomic, readwrite, getter=isCommandClick) BOOL isCommandKeyPressed;
@property (nonatomic, readwrite, getter=isShiftClick) BOOL isShiftKeyPressed;
@property (nonatomic, readwrite, getter=isOptionClick) BOOL isOptionKeyPressed;
@end

@implementation FUActivation

+ (id)activationFromEvent:(NSEvent *)evt {
    FUActivation *a = [[[self alloc] init] autorelease];
    
    a.isCommandKeyPressed = [evt FU_isCommandKeyPressed] || [evt FU_is3rdButtonClick];
    a.isShiftKeyPressed   = [evt FU_isShiftKeyPressed];
    a.isOptionKeyPressed  = [evt FU_isOptionKeyPressed];
    
    return a;
}


+ (id)activationFromModifierFlags:(NSUInteger)flags {
    FUActivation *a = [[[self alloc] init] autorelease];
    
    a.isCommandKeyPressed = FUIsCommandKeyPressed(flags);
    a.isShiftKeyPressed   = FUIsShiftKeyPressed(flags);
    a.isOptionKeyPressed  = FUIsOptionKeyPressed(flags);
    
    return a;
}


+ (id)activationFromWebActionInfo:(NSDictionary *)info {
    FUActivation *a = [[[self alloc] init] autorelease];
    
    NSUInteger flags = [[info objectForKey:WebActionModifierFlagsKey] unsignedIntegerValue];
    BOOL isMiddleClick = 1 == [[info objectForKey:WebActionButtonKey] integerValue];
    
    a.isCommandKeyPressed = FUIsCommandKeyPressed(flags) || isMiddleClick;
    a.isShiftKeyPressed   = FUIsShiftKeyPressed(flags);
    a.isOptionKeyPressed  = FUIsOptionKeyPressed(flags);

    return a;
}

@synthesize isCommandKeyPressed;
@synthesize isShiftKeyPressed;
@synthesize isOptionKeyPressed;
@end
