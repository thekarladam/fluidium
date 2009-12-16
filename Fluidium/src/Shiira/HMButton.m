/*
HMButton.m

Author: Makoto Kinoshita

Copyright 2004-2006 The Shiira Project. All rights reserved.

Redistribution and use in source and binary forms, with or without modification, are permitted 
provided that the following conditions are met:

  1. Redistributions of source code must retain the above copyright notice, this list of conditions 
  and the following disclaimer.

  2. Redistributions in binary form must reproduce the above copyright notice, this list of 
  conditions and the following disclaimer in the documentation and/or other materials provided 
  with the distribution.

THIS SOFTWARE IS PROVIDED BY THE SHIIRA PROJECT ``AS IS'' AND ANY EXPRESS OR IMPLIED WARRANTIES, 
INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR 
PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE SHIIRA PROJECT OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, 
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, 
PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING 
NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE 
POSSIBILITY OF SUCH DAMAGE.
*/

#import "HMButton.h"
#import "HMButtonCell.h"

@implementation HMButton

//--------------------------------------------------------------//
#pragma mark -- Initialize --
//--------------------------------------------------------------//

+ (Class)cellClass
{
    return [HMButtonCell class];
}

//--------------------------------------------------------------//
#pragma mark -- Separator --
//--------------------------------------------------------------//

- (BOOL)isSeparator
{
    return [(HMButtonCell*)[self cell] isSeparator];
}

- (void)setSeparator:(BOOL)isSeparator
{
    [(HMButtonCell*)[self cell] setSeparator:isSeparator];
    
    [self setNeedsDisplay:YES];
}

//--------------------------------------------------------------//
#pragma mark -- Selection --
//--------------------------------------------------------------//

- (BOOL)isSelected
{
    return [(HMButtonCell*)[self cell] isSelected];
}

- (void)setSelected:(BOOL)isSelected
{
    [(HMButtonCell*)[self cell] setSelected:isSelected];
    
    [self setNeedsDisplay:YES];
}

- (NSImage*)selectedImage
{
    return [(HMButtonCell*)[self cell] selectedImage];
}

- (void)setSelectedImage:(NSImage*)image
{
    [(HMButtonCell*)[self cell] setSelectedImage:image];
    
    [self setNeedsDisplay:YES];
}

@end
