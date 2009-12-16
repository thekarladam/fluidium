/*
HMButtonCell.m

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

#import "HMButtonCell.h"

@implementation HMButtonCell

//--------------------------------------------------------------//
#pragma mark -- Initialize --
//--------------------------------------------------------------//

- (void)dealloc
{
    [_selectedImage release], _selectedImage = nil;
    
    [super dealloc];
}

//--------------------------------------------------------------//
#pragma mark -- Separator --
//--------------------------------------------------------------//

- (BOOL)isSeparator
{
    return _isSeparator;
}

- (void)setSeparator:(BOOL)isSepaartor
{
    _isSeparator = isSepaartor;
}

//--------------------------------------------------------------//
#pragma mark -- Selection --
//--------------------------------------------------------------//

- (BOOL)isSelected
{
    return _isSelected;
}

- (void)setSelected:(BOOL)isSelected
{
    _isSelected = isSelected;
}

- (NSImage*)selectedImage
{
    return _selectedImage;
}

- (void)setSelectedImage:(NSImage*)image
{
    _selectedImage = [image retain];
}

//--------------------------------------------------------------//
#pragma mark -- Drawing --
//--------------------------------------------------------------//

- (void)_drawSeparatorWithFrame:(NSRect)cellFrame 
        inView:(NSView*)controlView
{
    // Draw separator
    NSRect  rect;
    
#if 1
    [[NSColor colorWithCalibratedWhite:0.36f alpha:1.0f] set];
    rect.origin.x = cellFrame.origin.x;
    rect.origin.y = cellFrame.origin.y + ceil(cellFrame.size.height / 2) - 1;
    rect.size.width = cellFrame.size.width;
    rect.size.height = 1;
    NSRectFill(rect);
#else
    [[NSColor colorWithCalibratedWhite:0.6f alpha:0.8f] set];
    rect.origin.x = cellFrame.origin.x;
    rect.origin.y = cellFrame.origin.y + ceil(cellFrame.size.height / 2) - 1;
    rect.size.width = cellFrame.size.width;
    rect.size.height = 1;
    NSRectFill(rect);
    
    [[NSColor colorWithCalibratedWhite:0.9f alpha:0.8f] set];
    rect.origin.y += 1;
    NSRectFill(rect);
#endif
}

- (void)_drawSelectedImageWithFrame:(NSRect)cellFrame 
        inView:(NSView*)controlView
{
    if (!_selectedImage || !_isSelected) {
        return;
    }
    
    if ([_selectedImage isFlipped] != [controlView isFlipped]) {
        [_selectedImage setFlipped:[controlView isFlipped]];
    }
    
    // Draw image
    NSRect  srcRect, destRect;
    srcRect.origin = NSZeroPoint;
    srcRect.size = [_selectedImage size];
    destRect.origin = cellFrame.origin;
    destRect.size = [_selectedImage size];
    [_selectedImage drawInRect:destRect fromRect:srcRect 
            operation:NSCompositeSourceOver fraction:1.0f];
}

- (void)drawInteriorWithFrame:(NSRect)cellFrame 
        inView:(NSView*)controlView
{
    // For separator
    if (_isSeparator) {
        [self _drawSeparatorWithFrame:cellFrame inView:controlView];
        return;
    }
    
    // For selected
    if (_isSelected) {
        [self _drawSelectedImageWithFrame:cellFrame inView:controlView];
    }
    
    [super drawInteriorWithFrame:cellFrame inView:controlView];
}
    
@end
