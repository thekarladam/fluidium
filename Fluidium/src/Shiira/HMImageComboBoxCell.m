/*
 HMImageComboBoxCell.m
 
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

#import "HMAppKitEx.h"

static int  HMImageComboBoxImageMargin = 2;

@implementation HMImageComboBoxCell

//--------------------------------------------------------------//
#pragma mark -- Initialize --
//--------------------------------------------------------------//

- (id)initImageCell:(NSImage *)anImage
{
    //NSLog(@"%s", _cmd);
    self = [super init];
    if (self != nil) {
        
    }
    return self;
}


- (id)initTextCell:(NSString *)aString
{
    //NSLog(@"%s", _cmd);
    self = [super init];
    if (self != nil) {
        
    }
    return self;
}


- (void)dealloc
{
    [_image release], _image = nil;
    [super dealloc];
}

- (id)copyWithZone:(NSZone*)zone
{
    HMImageComboBoxCell*    cell;
    cell = (HMImageComboBoxCell *)[super copyWithZone:zone];
    cell->_image = [_image retain];
    return cell;
}

//--------------------------------------------------------------//
#pragma mark -- Working with image --
//--------------------------------------------------------------//

- (void)setImage:(NSImage*)image {
    if (_image != image) {
        [_image release];
        _image = [image retain];
        
        [[self controlView] setNeedsDisplay:YES];
    }
}

- (NSImage *)image {
    return _image;
}

- (NSRect)imageFrameForCellFrame:(NSRect)cellFrame
{
    if (_image) {
        NSRect imageFrame;
        imageFrame.size = [_image size];
        imageFrame.origin = cellFrame.origin;
        imageFrame.origin.x += 3;
        imageFrame.origin.y += ceil((cellFrame.size.height - imageFrame.size.height) / 2);
        return imageFrame;
    }
    else {
        return NSZeroRect;
    }
}

//--------------------------------------------------------------//
#pragma mark -- Editing --
//--------------------------------------------------------------//

- (void)selectWithFrame:(NSRect)rect 
                 inView:(NSView*)controlView 
                 editor:(NSText*)textObj 
               delegate:(id)object 
                  start:(NSInteger)selStart 
                 length:(NSInteger)selLength
{
    // Divide frame
    NSRect  textFrame, imageFrame, buttonFrame;
    if (_image) {
        NSDivideRect(rect, &imageFrame, &textFrame, HMImageComboBoxImageMargin + [_image size].width, NSMinXEdge);
    }
    else {
        textFrame = rect;
        imageFrame = NSZeroRect;
    }
    
    buttonFrame = [(HMImageComboBox*)controlView buttonFrame];
    textFrame.size.width -= buttonFrame.size.width + 2;
    
    [super selectWithFrame:textFrame 
                    inView:controlView 
                    editor:textObj 
                  delegate:object 
                     start:selStart 
                    length:selLength];
}

- (void)editWithFrame:(NSRect)rect 
               inView:(NSView*)controlView 
               editor:(NSText*)textObj 
             delegate:(id)object 
                event:(NSEvent*)event 
{
    // Divide frame
    NSRect  textFrame, imageFrame, buttonFrame;
    if (_image) {
        NSDivideRect(rect, &imageFrame, &textFrame, 
                     HMImageComboBoxImageMargin + [_image size].width, NSMinXEdge);
    }
    else {
        textFrame = rect;
        imageFrame = NSZeroRect;
    }
    
    buttonFrame = [(HMImageComboBox*)controlView buttonFrame];
    textFrame.size.width -= buttonFrame.size.width + 2;
    
    [super editWithFrame:textFrame 
                  inView:controlView 
                  editor:textObj 
                delegate:object 
                   event:event];
}

//--------------------------------------------------------------//
#pragma mark -- Drawing --
//--------------------------------------------------------------//

- (void)drawInteriorWithFrame:(NSRect)cellFrame 
                       inView:(NSView*)controlView
{
    // Draw image
    if (_image) {
        NSSize    imageSize;
        NSRect    imageFrame;
        
        imageSize = [_image size];
        NSDivideRect(cellFrame, &imageFrame, &cellFrame, 
                     HMImageComboBoxImageMargin + imageSize.width, NSMinXEdge);
        imageFrame.origin.x += 3;
        imageFrame.size = imageSize;
        imageFrame.origin.y += ceil((cellFrame.size.height - imageFrame.size.height) / 2);
        if ([self drawsBackground]) {
            [[self backgroundColor] set];
            NSRectFill(imageFrame);
        }
        
        imageFrame.origin.y = cellFrame.origin.y;
        if ([controlView isFlipped]) {
            imageFrame.origin.y += ceil((cellFrame.size.height + imageFrame.size.height) / 2);
        }
        else {
            imageFrame.origin.y += ceil((cellFrame.size.height - imageFrame.size.height) / 2);
        }
        
        [_image compositeToPoint:imageFrame.origin operation:NSCompositeSourceOver];
    }
    
    // Draw text
    [super drawInteriorWithFrame:cellFrame inView:controlView];
}

- (void)drawInteriorImageOnlyWithFrame:(NSRect)cellFrame 
                                inView:(NSView*)controlView
{
    // Draw image
    if (_image) {
        NSSize    imageSize;
        NSRect    imageFrame;
        
        imageSize = [_image size];
        NSDivideRect(cellFrame, &imageFrame, &cellFrame, 
                     HMImageComboBoxImageMargin + imageSize.width, NSMinXEdge);
        imageFrame.origin.x += 3;
        imageFrame.size = imageSize;
        imageFrame.origin.y += ceil((cellFrame.size.height - imageFrame.size.height) / 2);
        // TODD removing this
        //        if ([self drawsBackground]) {
        //            [[self backgroundColor] set];
        //            NSRectFill(imageFrame);
        //        }
        
        imageFrame.origin.y = cellFrame.origin.y;
        if ([controlView isFlipped]) {
            imageFrame.origin.y += ceil((cellFrame.size.height + imageFrame.size.height) / 2);
        }
        else {
            imageFrame.origin.y += ceil((cellFrame.size.height - imageFrame.size.height) / 2);
        }
        
        [_image compositeToPoint:imageFrame.origin operation:NSCompositeSourceOver];
    }
    
    // Draw text
    //    [super drawInteriorWithFrame:cellFrame inView:controlView];
}

- (NSSize)cellSize
{
    NSSize cellSize = [super cellSize];
    cellSize.width += (_image ? [_image size].width : 0) + HMImageComboBoxImageMargin;
    return cellSize;
}

- (void)_drawFocusRingWithFrame:(NSRect)rect
{
    if (_image) {
        rect.origin.x -= [_image size].width + HMImageComboBoxImageMargin;
        rect.size.width += [_image size].width + HMImageComboBoxImageMargin;
    }
    
    NSRect  buttonFrame;
    buttonFrame = [(HMImageComboBox*)[self controlView] buttonFrame];
    if (buttonFrame.size.width > 0) {
        rect.size.width += buttonFrame.size.width + 2;
    }
    
    rect = NSInsetRect(rect, 1.0, 1.0);
    [super _drawFocusRingWithFrame:rect];
}

//--------------------------------------------------------------//
#pragma mark -- Dragging --
//--------------------------------------------------------------//

- (NSImage*)imageForDraggingWithFrame:(NSRect)cellFrame inView:(NSView*)controlView
{
    // Create image
    NSImage*    image;
    image = [[NSImage alloc] initWithSize:cellFrame.size];
    [image autorelease];
    
    // Create attributed string
    NSMutableAttributedString*  attrStr;
    float                       alpha = 0.7f;
    attrStr = [[NSMutableAttributedString alloc] 
               initWithAttributedString:[self attributedStringValue]];
    [attrStr autorelease];
    [attrStr addAttribute:NSForegroundColorAttributeName 
                    value:[NSColor colorWithCalibratedWhite:0.0f alpha:alpha] 
                    range:NSMakeRange(0, [attrStr length])];
    
    // Draw cell
    [image lockFocus];
    [_image dissolveToPoint:NSZeroPoint fraction:alpha];
    [attrStr drawAtPoint:NSMakePoint([_image size].width + HMImageComboBoxImageMargin, 0.0f)];
    [image unlockFocus];
    
    return image;
}

- (BOOL)imageTrackMouse:(NSEvent*)event 
                 inRect:(NSRect)cellFrame 
                 ofView:(NSView*)controlView 
{
    // Check mouse is in image or not
    NSRect  imageFrame;
    NSPoint point;
    
    imageFrame = [self imageFrameForCellFrame:cellFrame];
    
    point = [controlView convertPoint:[event locationInWindow] fromView:nil];
    
    if (NSPointInRect(point, imageFrame)) {
#if 0
        //
        // Start dragging
        //
        
        // Get URL string and title from web data source
        WebDataSource*  dataSource;
        NSString*       pageURLString;
        NSString*       title;
        dataSource = [[[[[controlView window] windowController] selectedWebView] mainFrame] dataSource];
        pageURLString = [[[dataSource request] URL] _web_userVisibleString];
        title = [dataSource pageTitle];
        
        // Get URL string from itself
        NSString*   URLString;
        URLString = [self stringValue];
        if (!URLString) {
            // User URL string from web data source
            URLString = pageURLString;
        }
        else if (![URLString isEqualToString:pageURLString]) {
            // Use URL string as title
            title = URLString;
        }
        
        if (!URLString || [URLString length] == 0) {
            return NO;
        }
        if (!title) {
            title = URLString;
        }
        
        // Get attributed sring and its size
        NSAttributedString* attrString;
        NSSize              stringSize;
        attrString = [self attributedStringValue];
        //if string is too long causes "Can't cache image" error. so truncate
        if([attrString length]>300){
            attrString = [attrString attributedSubstringFromRange:NSMakeRange(0,300)];
        }
        stringSize = [attrString size];
        if(stringSize.width>1000){
            stringSize.width=1000;
        }
        
        // Create image
        NSSize      imageSize;
        NSImage*    dragImage;
        imageSize = stringSize;
        imageSize.width += [_image size].width + HMImageComboBoxImageMargin;
        dragImage = [[NSImage alloc] initWithSize:imageSize];
        [dragImage autorelease];
        
        // Draw image
        NSMutableAttributedString*  coloredAttrString;
        float                       alpha = 0.7;
        
        coloredAttrString = [[NSMutableAttributedString alloc] 
                             initWithAttributedString:attrString];
        [coloredAttrString autorelease];
        [coloredAttrString addAttribute:NSForegroundColorAttributeName 
                                  value:[NSColor colorWithCalibratedWhite:0.0 alpha:alpha] 
                                  range:NSMakeRange(0, [attrString length])];
        
        [NSGraphicsContext saveGraphicsState];
        [dragImage lockFocus];
        [_image dissolveToPoint:NSZeroPoint fraction:alpha];
        [coloredAttrString drawAtPoint:NSMakePoint([_image size].width + HMImageComboBoxImageMargin, 0)];
        [dragImage unlockFocus];
        [NSGraphicsContext restoreGraphicsState];
        
        // Create bookmark data
        SRBookmark* bookmark;
        bookmark = [SRBookmark bookmarkWithTitle:title 
                                       URLString:URLString 
                                 originalBrowser:SRBrowserShiira];
        
        // Get MIME type
        NSURLResponse*  response;
        NSString*       MIMEType;
        response = [dataSource response];
        MIMEType = [response MIMEType];
        if ([[SRRSSRepresentation RSSMimes] containsObject:MIMEType]) {
            [bookmark setType:SRBookmarkTypeRSS];
        }
        
        // Write bookmark to pasteboard
        NSPasteboard*   pboard;
        pboard = [NSPasteboard pasteboardWithName:NSDragPboard];
        SRWriteBookmarksToPasteboard([NSArray arrayWithObject:bookmark], pboard);
        
        // Start dragging
        NSPoint startAt;
        startAt = imageFrame.origin;
        if ([controlView isFlipped]) {
            startAt.y = cellFrame.size.height - startAt.y;
        }
        
        [controlView dragImage:dragImage 
                            at:startAt 
                        offset:NSZeroSize 
                         event:event 
                    pasteboard:pboard 
                        source:self 
                     slideBack:YES];
#endif
        
        return YES;
    }
    
    return NO;
}

- (void)resetCursorRect:(NSRect)cellFrame 
                 inView:(NSView*)controlView
{
    NSRect  textFrame;
    NSRect  imageFrame;
    NSDivideRect(
                 cellFrame, &imageFrame, &textFrame, HMImageComboBoxImageMargin + [_image size].width, NSMinXEdge);
    [super resetCursorRect:textFrame inView:controlView];
}



- (id)popUp {
    return self->_popUp;
}


@end
