//
//  NSEvent+FUAdditions.h
//  Fluidium
//
//  Created by Todd Ditchendorf on 12/4/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface NSEvent (FUAdditions)
- (BOOL)FU_isKeyUpOrDown;
- (BOOL)FU_is3rdButtonClick;
- (BOOL)FU_isCommandKeyPressed;
- (BOOL)FU_isShiftKeyPressed;
- (BOOL)FU_isOptionKeyPressed;
- (BOOL)FU_isEscKeyPressed;
- (BOOL)FU_isReturnKeyPressed;
- (BOOL)FU_isEnterKeyPressed;
@end
