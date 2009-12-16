/*
HMImageComboBox.m

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

#import "HMImageComboBox.h"
#import "HMImageComboBoxCell.h"

@implementation HMImageComboBox

//--------------------------------------------------------------//
#pragma mark -- Initialize --
//--------------------------------------------------------------//

+ (Class)cellClass
{
    //NSLog(@"%s", _cmd);
    // Use HMImageComboBoxCell class
    return [HMImageComboBoxCell class];
}

- (id)initWithFrame:(NSRect)frame
{
    self = [super initWithFrame:frame];
    if (!self) {
        return nil;
    }
    
    // Initialize member variables
    _buttons = [[NSMutableArray array] retain];
    
    return self;
}

- (void)dealloc
{
    [_buttons release];
    
    [super dealloc];
}

//--------------------------------------------------------------//
#pragma mark -- Working with image --
//--------------------------------------------------------------//

- (void)setImage:(NSImage*)image
{
    // Set image to cell
    [[self cell] setImage:image];
}

- (NSImage*)image
{
    // Get image from cell
    return [[self cell] image];
}

//--------------------------------------------------------------//
#pragma mark -- Working wiht buttons --
//--------------------------------------------------------------//

- (NSArray*)buttons
{
    return _buttons;
}

- (NSButton*)addButtonWithSize:(NSSize)size
{
    // Get button frame;
    NSRect  buttonFrame;
    buttonFrame = [self buttonFrame];
    if (NSIsEmptyRect(buttonFrame)) {
        buttonFrame.origin.x = [self frame].origin.x + [self frame].size.width - 24;
    }
    
    // Create button
    NSRect      frame;
    NSButton*   button;
    frame.origin.x = buttonFrame.origin.x - size.width - 1;
    frame.origin.y = ([self frame].size.height - size.height) / 2;
    frame.size = size;
    button = [[NSButton alloc] initWithFrame:frame];
    [button autorelease];
    [button setAutoresizingMask:NSViewMinXMargin | NSViewMinYMargin];
    
    // Add button
    [self addSubview:button];
    [_buttons addObject:button];
    
    return button;
}

- (NSButton*)buttonWithTag:(int)tag
{
    // Get button
    NSEnumerator*   enumerator;
    NSButton*       button;
    enumerator = [_buttons objectEnumerator];
    while (button = [enumerator nextObject]) {
        if ([button tag] == tag) {
            return button;
        }
    }
    
    return nil;
}

- (void)removeButton:(NSButton*)button
{
    // Remove button
    [button removeFromSuperview];
    [_buttons removeObject:button];
}

- (NSRect)buttonFrame
{
    // Get union rect of existed buttons
    NSRect          unionRect = NSZeroRect;
    NSEnumerator*   enumerator;
    NSButton*       button;
    enumerator = [_buttons objectEnumerator];
    while (button = [enumerator nextObject]) {
        unionRect = NSUnionRect(unionRect, [button frame]);
    }
    
    return unionRect;
}

//--------------------------------------------------------------//
#pragma mark -- Dragging --
//--------------------------------------------------------------//

- (void)mouseDown:(NSEvent*)event
{
    // Get mouse point
    NSPoint point;
    point = [self convertPoint:[event locationInWindow] fromView:nil];
    
    // Get image frame
    NSRect  frame;
    frame = [[self cell] imageFrameForCellFrame:[self bounds]];
    
    // Decide to start dragging
    _shouldDrag = NSPointInRect(point, frame);
    if (!_shouldDrag) {
        [super mouseDown:event];
        return;
    }
    
    // Select text all
    [self selectText:self];
}

- (void)mouseDragged:(NSEvent*)event
{
    // Check flag
    if (!_shouldDrag) {
        [super mouseDragged:event];
        return;
    }
    
    // Write data to pasteboard
    NSPasteboard*   pboard;
    id              delegate;
    pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
    delegate = [self delegate];
    if (![delegate respondsToSelector:@selector(hmComboBox:writeDataToPasteboard:)]) {
        return;
    }
    if (![delegate hmComboBox:self writeDataToPasteboard:pboard]) {
        return;
    }
    
    // Get drag image
    NSImage*    image;
    image = [[self cell] imageForDraggingWithFrame:[self bounds] inView:self]; 
    if (!image) {
        return;
    }
    
    // Start dragging
    NSPoint point;
    point = NSZeroPoint;
    if ([self isFlipped]) {
        point.y = [self bounds].size.height;
    }
    [self dragImage:image at:point offset:NSZeroSize 
            event:event pasteboard:pboard source:self slideBack:YES];
}

@end
