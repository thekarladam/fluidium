//
//  NSEvent+FUAdditions.m
//  Fluidium
//
//  Created by Todd Ditchendorf on 12/4/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import "NSEvent+FUAdditions.h"
#import "FUUtils.h"

#define ESC 53
#define RETURN 36
#define ENTER 76

@implementation NSEvent (FUAdditions)

- (BOOL)FU_isKeyUpOrDown {
    return (NSKeyUp == [self type] || NSKeyDown == [self type]);
}


- (BOOL)FU_is3rdButtonClick {
    return 2 == [self buttonNumber];
}


- (BOOL)FU_isCommandKeyPressed {
    return FUIsCommandKeyPressed([self modifierFlags]);
}


- (BOOL)FU_isShiftKeyPressed {
    return FUIsShiftKeyPressed([self modifierFlags]);
}


- (BOOL)FU_isOptionKeyPressed {
    return FUIsOptionKeyPressed([self modifierFlags]);
}


- (BOOL)FU_isEscKeyPressed {
    return [self FU_isKeyUpOrDown] && ESC == [self keyCode];
}


- (BOOL)FU_isReturnKeyPressed {
    return [self FU_isKeyUpOrDown] && RETURN == [self keyCode];
}


- (BOOL)FU_isEnterKeyPressed {
    return [self FU_isKeyUpOrDown] && ENTER == [self keyCode];
}

@end
