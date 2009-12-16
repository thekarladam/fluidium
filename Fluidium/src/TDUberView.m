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

#import "TDUberView.h"
#import "TDUberViewSplitView.h"

static NSComparisonResult TDVSplitViewSubviewComparatorFunc(id viewA, id viewB, TDUberView *self);
static NSComparisonResult TDHSplitViewSubviewComparatorFunc(id viewA, id viewB, TDUberView *self);

@interface TDUberView ()
- (void)timerFired:(NSTimer*)t;
- (void)storeSplitPositions;
- (void)storeOpenStates;
- (void)storeLeftSplitPosition;
- (void)storeRightSplitPosition;
- (void)storeTopSplitPosition;
- (void)storeBottomSplitPosition;
- (CGFloat)storedLeftSplitPosition;
- (CGFloat)storedRightSplitPosition;
- (CGFloat)storedTopSplitPosition;
- (CGFloat)storedBottomSplitPosition;
- (void)restoreSplitPositions;
- (void)restoreOpenStates;
- (void)restoreLeftSplitPosition;
- (void)restoreRightSplitPosition;
- (void)restoreTopSplitPosition;
- (void)restoreBottomSplitPosition;
- (void)resetCapturing;

- (CGFloat)vSplitView:(NSSplitView *)splitView constrainSplitPosition:(CGFloat)proposedPosition ofSubviewAt:(NSInteger)dividerIndex;
- (CGFloat)hSplitView:(NSSplitView *)splitView constrainSplitPosition:(CGFloat)proposedPosition ofSubviewAt:(NSInteger)dividerIndex;
- (void)vSplitView:(NSSplitView *)splitView resizeSubviewsWithOldSize:(NSSize)oldSize;
- (void)hSplitView:(NSSplitView *)splitView resizeSubviewsWithOldSize:(NSSize)oldSize;

@property (nonatomic, retain) NSSplitView *vSplitView;
@property (nonatomic, retain) NSSplitView *hSplitView;
@property (nonatomic, retain) NSTimer *timer;

@property (nonatomic, retain) NSView *leftSuperview;
@property (nonatomic, retain) NSView *rightSuperview;
@property (nonatomic, retain) NSView *topSuperview;
@property (nonatomic, retain) NSView *midSuperview;
@property (nonatomic, retain) NSView *bottomSuperview;

@property (nonatomic, readwrite, getter=isLeftViewOpen) BOOL leftViewOpen;
@property (nonatomic, readwrite, getter=isRightViewOpen) BOOL rightViewOpen;
@property (nonatomic, readwrite, getter=isTopViewOpen) BOOL topViewOpen;
@property (nonatomic, readwrite, getter=isBottomViewOpen) BOOL bottomViewOpen;
@end

@implementation TDUberView

- (id)initWithFrame:(NSRect)frame {
    BOOL thin = [[NSUserDefaults standardUserDefaults] boolForKey:@"TDUberView_splitViewDividerStyle"];
    return [self initWithFrame:frame dividerStyle:thin ? NSSplitViewDividerStyleThin : NSSplitViewDividerStyleThick];
}


- (id)initWithFrame:(NSRect)frame dividerStyle:(NSSplitViewDividerStyle)dividerStyle {
    self = [super initWithFrame:frame];
    if (self) {
        self.splitViewDividerStyle = dividerStyle;
        self.preferredLeftSplitWidth = 200.;
        self.preferredRightSplitWidth = 200.;
        self.preferredTopSplitHeight = 175.;
        self.preferredBottomSplitHeight = 175.;
        self.snapsToPreferredSplitWidths = YES;
        self.snapTolerance = 35.;
        
        self.leftViewOpen = NO;
        self.rightViewOpen = NO;
        self.topViewOpen = NO;
        self.bottomViewOpen = NO;
        
        self.vSplitView = [[TDUberViewSplitView alloc] initWithFrame:NSMakeRect(0., 0., frame.size.width, frame.size.height)];
        [vSplitView release];
        [vSplitView setVertical:YES];
        [vSplitView setDividerStyle:splitViewDividerStyle];
        vSplitView.autoresizingMask = NSViewHeightSizable|NSViewWidthSizable; //NSViewMinXMargin|NSViewMinYMargin|NSViewMaxXMargin|NSViewMaxYMargin|
        vSplitView.delegate = self;
        [self addSubview:vSplitView];

        self.leftSuperview = [[NSView alloc] initWithFrame:NSZeroRect];
        //[vSplitView addSubview:leftSuperview];
        leftSuperview.frame = NSMakeRect(0., 0., preferredLeftSplitWidth, MAXFLOAT);
        
        self.hSplitView = [[TDUberViewSplitView alloc] initWithFrame:NSMakeRect(0., 0., frame.size.width, frame.size.height)];
        [hSplitView release];
        [hSplitView setVertical:NO];
        [hSplitView setDividerStyle:splitViewDividerStyle];
        hSplitView.autoresizingMask = NSViewHeightSizable|NSViewWidthSizable; //NSViewMinXMargin|NSViewMinYMargin|NSViewMaxXMargin|NSViewMaxYMargin|
        hSplitView.delegate = self;
        [vSplitView addSubview:hSplitView];

        self.rightSuperview = [[NSView alloc] initWithFrame:NSZeroRect];
        //[vSplitView addSubview:rightSuperview];
        rightSuperview.frame = NSMakeRect(vSplitView.frame.size.width - preferredLeftSplitWidth - preferredRightSplitWidth, 0., preferredRightSplitWidth, MAXFLOAT);

        self.topSuperview = [[NSView alloc] initWithFrame:NSZeroRect];
        //[hSplitView addSubview:topSuperview];
        topSuperview.frame = NSMakeRect(0., 0., MAXFLOAT, preferredTopSplitHeight);

        self.midSuperview = [[NSView alloc] initWithFrame:NSZeroRect];
        [hSplitView addSubview:midSuperview];
        midSuperview.frame = NSMakeRect(0., 0., MAXFLOAT, MAXFLOAT);

        self.bottomSuperview = [[NSView alloc] initWithFrame:NSZeroRect];
        //[hSplitView addSubview:bottomSuperview];
        bottomSuperview.frame = NSMakeRect(0., 0., MAXFLOAT, preferredBottomSplitHeight);

        leftSuperview.autoresizingMask = NSViewHeightSizable|NSViewWidthSizable; //NSViewMinXMargin|NSViewMinYMargin|NSViewMaxXMargin|NSViewMaxYMargin|
        rightSuperview.autoresizingMask = NSViewHeightSizable|NSViewWidthSizable; //NSViewMinXMargin|NSViewMinYMargin|NSViewMaxXMargin|NSViewMaxYMargin|
        topSuperview.autoresizingMask = NSViewHeightSizable|NSViewWidthSizable; //NSViewMinXMargin|NSViewMinYMargin|NSViewMaxXMargin|NSViewMaxYMargin|
        midSuperview.autoresizingMask = NSViewHeightSizable|NSViewWidthSizable; //NSViewMinXMargin|NSViewMinYMargin|NSViewMaxXMargin|NSViewMaxYMargin|
        bottomSuperview.autoresizingMask = NSViewHeightSizable|NSViewWidthSizable; //NSViewMinXMargin|NSViewMinYMargin|NSViewMaxXMargin|NSViewMaxYMargin|
        
        [leftSuperview release];
        [rightSuperview release];
        [topSuperview release];
        [midSuperview release];
        [bottomSuperview release];

        //[self restoreSplitPositions];

        [self resetCapturing];
    }
    return self;
}


- (void)dealloc {
    self.vSplitView = nil;
    self.hSplitView = nil;
    self.leftSuperview = nil;
    self.rightSuperview = nil;
    self.topSuperview = nil;
    self.midSuperview = nil;
    self.bottomSuperview = nil;
    self.leftView = nil;
    self.rightView = nil;
    self.topView = nil;
    self.midView = nil;
    self.bottomView = nil;
    self.timer = nil;
    [super dealloc];
}


- (BOOL)isFlipped {
    return YES;
}


#pragma mark -
#pragma mark Actions

- (IBAction)resetToPreferredSplitPositions:(id)sender {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults removeObjectForKey:@"TDUberView_leftViewWidth"];
    [userDefaults removeObjectForKey:@"TDUberView_rightViewWidth"];
    [userDefaults removeObjectForKey:@"TDUberView_topViewHeight"];
    [userDefaults removeObjectForKey:@"TDUberView_bottomViewHeight"];
    [userDefaults synchronize];
    
    [self restoreSplitPositions];
}

#pragma mark -
#pragma mark LEFT

- (IBAction)toggleLeftView:(id)sender {
    self.leftViewOpen = !leftViewOpen;
    if (leftViewOpen) {
        [self openLeftView:sender];
    } else {
        [self closeLeftView:sender];
    }
}


- (IBAction)openLeftView:(id)sender {
    self.leftViewOpen = YES;
    
    // add leftSuperview to splitview if necessary
    if (leftSuperview.superview != vSplitView) {
        [vSplitView addSubview:leftSuperview];
        [vSplitView sortSubviewsUsingFunction:(NSComparisonResult (*)(id, id, void *))TDVSplitViewSubviewComparatorFunc context:self];
    }
    
    [self restoreLeftSplitPosition];
    [hSplitView setNeedsDisplay:YES];
    [vSplitView setNeedsDisplay:YES];
    [self setNeedsDisplay:YES];
}


- (IBAction)closeLeftView:(id)sender {
    self.leftViewOpen = NO;
    
    // remove leftSuperview from splitview if necessary
    if (leftSuperview.superview == vSplitView) {
        [leftSuperview removeFromSuperview];
    }

    [hSplitView setNeedsDisplay:YES];
    [vSplitView setNeedsDisplay:YES];
    [self setNeedsDisplay:YES];
}


#pragma mark -
#pragma mark RIGHT

- (IBAction)toggleRightView:(id)sender {
    self.rightViewOpen = !rightViewOpen;
    if (rightViewOpen) {
        [self openRightView:sender];
    } else {
        [self closeRightView:sender];
    }
}


- (IBAction)openRightView:(id)sender {
    self.rightViewOpen = YES;

    // add rightSuperview to splitview if necessary
    if (rightSuperview.superview != vSplitView) {
        [vSplitView addSubview:rightSuperview];
        [vSplitView sortSubviewsUsingFunction:(NSComparisonResult (*)(id, id, void *))TDVSplitViewSubviewComparatorFunc context:self];
    }
    
    [self restoreRightSplitPosition];
    [hSplitView setNeedsDisplay:YES];
    [vSplitView setNeedsDisplay:YES];
    [self setNeedsDisplay:YES];
}


- (IBAction)closeRightView:(id)sender {
    self.rightViewOpen = NO;

    // remove rightSuperview from splitview if necessary
    if (rightSuperview.superview == vSplitView) {
        [rightSuperview removeFromSuperview];
    }
    
    [hSplitView setNeedsDisplay:YES];
    [vSplitView setNeedsDisplay:YES];
    [self setNeedsDisplay:YES];
}


#pragma mark -
#pragma mark TOP

- (IBAction)toggleTopView:(id)sender {
    self.topViewOpen = !topViewOpen;
    if (topViewOpen) {
        [self openTopView:sender];
    } else {
        [self closeTopView:sender];
    }
}


- (IBAction)openTopView:(id)sender {
    self.topViewOpen = YES;
    
    // add topSuperview to splitview if necessary
    if (topSuperview.superview != hSplitView) {
        [hSplitView addSubview:topSuperview];
        [hSplitView sortSubviewsUsingFunction:(NSComparisonResult (*)(id, id, void *))TDHSplitViewSubviewComparatorFunc context:self];
    }
    
    [self restoreTopSplitPosition];
    [hSplitView setNeedsDisplay:YES];
    [vSplitView setNeedsDisplay:YES];
    [self setNeedsDisplay:YES];
}


- (IBAction)closeTopView:(id)sender {
    self.topViewOpen = NO;
    
    // remove topSuperview from splitview if necessary
    if (topSuperview.superview == hSplitView) {
        [topSuperview removeFromSuperview];
    }
    
    [hSplitView setNeedsDisplay:YES];
    [vSplitView setNeedsDisplay:YES];
    [self setNeedsDisplay:YES];
}


#pragma mark -
#pragma mark BOTTOM

- (IBAction)toggleBottomView:(id)sender {
    self.bottomViewOpen = !bottomViewOpen;
    if (bottomViewOpen) {
        [self openBottomView:sender];
    } else {
        [self closeBottomView:sender];
    }
}


- (IBAction)openBottomView:(id)sender {
    self.bottomViewOpen = YES;
    
    // add bottomSuperview to splitview if necessary
    if (bottomSuperview.superview != hSplitView) {
        [hSplitView addSubview:bottomSuperview];
        [hSplitView sortSubviewsUsingFunction:(NSComparisonResult (*)(id, id, void *))TDHSplitViewSubviewComparatorFunc context:self];
    }
    
    [self restoreBottomSplitPosition];
    [hSplitView setNeedsDisplay:YES];
    [vSplitView setNeedsDisplay:YES];
    [bottomSuperview setNeedsDisplay:YES];
    [self setNeedsDisplay:YES];
}


- (IBAction)closeBottomView:(id)sender {
    self.bottomViewOpen = NO;
    
    // remove bottomSuperview from splitview if necessary
    if (bottomSuperview.superview == hSplitView) {
        [bottomSuperview removeFromSuperview];
    }
    
    [hSplitView setNeedsDisplay:YES];
    [vSplitView setNeedsDisplay:YES];
    [self setNeedsDisplay:YES];
}


#pragma mark -
#pragma mark NSSplitViewDelegate

- (CGFloat)splitView:(NSSplitView *)splitView constrainMinCoordinate:(CGFloat)proposedMinimumPosition ofSubviewAt:(NSInteger)dividerIndex {
    if (splitView == vSplitView) {
        dragStartMidWidth = -1;
    } else {
        dragStartMidHeight = -1;
    }
    return proposedMinimumPosition;
}


- (CGFloat)splitView:(NSSplitView *)splitView constrainMaxCoordinate:(CGFloat)proposedMaximumPosition ofSubviewAt:(NSInteger)dividerIndex {
    if (splitView == vSplitView) {
        dragStartMidWidth = -1;
    } else {
        dragStartMidHeight = -1;
    }
    return proposedMaximumPosition;
}


- (CGFloat)splitView:(NSSplitView *)splitView constrainSplitPosition:(CGFloat)proposedPosition ofSubviewAt:(NSInteger)dividerIndex {
    if (splitView == vSplitView) {
        return [self vSplitView:splitView constrainSplitPosition:proposedPosition ofSubviewAt:dividerIndex];
    } else {
        return [self hSplitView:splitView constrainSplitPosition:proposedPosition ofSubviewAt:dividerIndex];
    }
}


- (CGFloat)vSplitView:(NSSplitView *)splitView constrainSplitPosition:(CGFloat)proposedPosition ofSubviewAt:(NSInteger)dividerIndex {
    CGFloat result = proposedPosition;
    CGFloat dividerThickness = splitView.dividerThickness;

    if (leftViewOpen && 0 == dividerIndex) { // snap leftFrame
        CGFloat x = preferredLeftSplitWidth;
        if (rightViewOpen && proposedPosition > rightSuperview.frame.origin.x - dividerThickness - snapTolerance) {
            result = rightSuperview.frame.origin.x;
        } else if (proposedPosition > splitView.frame.size.width - dividerThickness - snapTolerance) {
            result = splitView.frame.size.width;
        } else if (proposedPosition > x - snapTolerance && proposedPosition < x + snapTolerance) {
            result = x;
        } else if (proposedPosition >= 0. && proposedPosition < snapTolerance) {
            result = 0.;
        }
    } else if ((!leftViewOpen && 0 == dividerIndex) || (leftViewOpen && 1 == dividerIndex)) { //snap rightFrame
        NSRect frame = splitView.frame;
        CGFloat x = frame.size.width - preferredRightSplitWidth;
        if (proposedPosition < hSplitView.frame.origin.x + snapTolerance - dividerThickness) {
            result = hSplitView.frame.origin.x;
        } else if (proposedPosition > x - snapTolerance && proposedPosition < x + snapTolerance) {
            result = x - dividerThickness;
        } else if (proposedPosition < frame.size.width && proposedPosition > frame.size.width - snapTolerance) {
            result = frame.size.width - dividerThickness;
        }
    }
    
    return result;
}


- (CGFloat)hSplitView:(NSSplitView *)splitView constrainSplitPosition:(CGFloat)proposedPosition ofSubviewAt:(NSInteger)dividerIndex {
    CGFloat result = proposedPosition;
    CGFloat dividerThickness = splitView.dividerThickness;
    
    if (topViewOpen && 0 == dividerIndex) { // snap topFrame
        CGFloat y = preferredTopSplitHeight;
        if (bottomViewOpen && proposedPosition > bottomSuperview.frame.origin.y - dividerThickness - snapTolerance) {
            result = rightSuperview.frame.origin.x;
        } else if (proposedPosition > splitView.frame.size.height - dividerThickness - snapTolerance) {
            result = splitView.frame.size.height;
        } else if (proposedPosition > y - snapTolerance && proposedPosition < y + snapTolerance) {
            result = y;
        } else if (proposedPosition >= 0. && proposedPosition < snapTolerance) {
            result = 0.;
        }
    } else if ((!topViewOpen && 0 == dividerIndex) || (topViewOpen && 1 == dividerIndex)) { //snap rightFrame
        NSRect frame = splitView.frame;
        CGFloat y = frame.size.height - preferredTopSplitHeight;
        if (proposedPosition < midSuperview.frame.origin.y + snapTolerance - dividerThickness) {
            result = midSuperview.frame.origin.y;
        } else if (proposedPosition > y - snapTolerance && proposedPosition < y + snapTolerance) {
            result = y - dividerThickness;
        } else if (proposedPosition < frame.size.height && proposedPosition > frame.size.height - snapTolerance) {
            result = frame.size.height - dividerThickness;
        }
    }
    
    return result;
}


- (void)splitView:(NSSplitView *)splitView resizeSubviewsWithOldSize:(NSSize)oldSize {
    if (splitView == vSplitView) {
        [self vSplitView:splitView resizeSubviewsWithOldSize:oldSize];
    } else {
        [self hSplitView:splitView resizeSubviewsWithOldSize:oldSize];
    }
}


- (void)vSplitView:(NSSplitView *)splitView resizeSubviewsWithOldSize:(NSSize)oldSize {
    NSRect newFrame = splitView.frame; // get the new size of the whole splitView
    
    NSRect leftFrame = leftSuperview.frame;
    NSRect midFrame = hSplitView.frame;
    NSRect rightFrame = rightSuperview.frame;

    if (-1 == dragStartMidWidth) {
        dragStartMidWidth = midFrame.size.width;
        dragStartRightRatio = leftFrame.size.width / rightFrame.size.width;
        dragStartLeftRatio = rightFrame.size.width / leftFrame.size.width;
    }
    
    BOOL wasCollapsed = (dragStartMidWidth <= 0.);

    BOOL bothOpen = (leftViewOpen && rightViewOpen);
    
    CGFloat dividerThickness = splitView.dividerThickness;
    
    leftFrame.size.height = newFrame.size.height;
    midFrame.size.height = newFrame.size.height;
    rightFrame.size.height = newFrame.size.height;

    CGFloat leftWidth, rightWidth;
    if (wasCollapsed) {
        leftWidth = abs(leftFrame.size.width);
        rightWidth = abs(rightFrame.size.width);
    } else {
        leftWidth = abs([self storedLeftSplitPosition]);
        rightWidth = abs([self storedRightSplitPosition]);
        leftFrame.size.width = leftWidth;
        rightFrame.size.width = rightWidth;
    }

    if (bothOpen) { // both open
        midFrame.size.width = newFrame.size.width - leftWidth - rightWidth - dividerThickness*2;
        midFrame.origin.x = leftWidth + dividerThickness;
        rightFrame.origin.x = midFrame.origin.x + midFrame.size.width + dividerThickness;
    } else if (leftViewOpen) { // only left open
        midFrame.size.width = newFrame.size.width - leftWidth - dividerThickness;
        midFrame.origin.x = leftWidth + dividerThickness;
    } else if (rightViewOpen) { // only right open
        midFrame.size.width = newFrame.size.width - rightWidth - dividerThickness;
        midFrame.origin.x = 0.;
        rightFrame.origin.x = midFrame.origin.x + midFrame.size.width + dividerThickness;
    } else { // both closed. BTW. this is still needed.
        midFrame.size.width = newFrame.size.width;
        midFrame.origin.x = 0.;
    }

    // prevent overlap
    if (wasCollapsed || midFrame.size.width < 24.) {
        CGFloat newMidWidth = wasCollapsed ? 0. : 24.;

        if (bothOpen) {
            CGFloat halfWidth = newFrame.size.width/2.;
            
            if (wasCollapsed) {
                if (dragStartLeftRatio < dragStartRightRatio) {
                    leftWidth = newFrame.size.width - ceil(((halfWidth*dragStartLeftRatio) - dividerThickness*2));
                    leftFrame.size.width = leftWidth;

                    rightWidth = newFrame.size.width - leftWidth - newMidWidth - dividerThickness*2;
                    rightFrame.size.width = rightWidth;
                } else {
                    rightWidth = newFrame.size.width - ceil(halfWidth*dragStartRightRatio);
                    rightFrame.size.width = rightWidth;
                    
                    leftWidth = newFrame.size.width - rightWidth - newMidWidth - dividerThickness*2;
                    leftFrame.size.width = leftWidth;
                    
                    rightFrame.origin.x = leftWidth + newMidWidth + dividerThickness*2;
                }
            } else {
                CGFloat leftRatio = leftWidth / rightWidth;
                CGFloat rightRatio = rightWidth / leftWidth;
                if (leftRatio < rightRatio) {
                    leftWidth = ceil(((halfWidth*leftRatio) - (newMidWidth*leftRatio)/2.));
                    leftWidth += newMidWidth + dividerThickness*2;
                    leftFrame.size.width = leftWidth;
                    
                    rightWidth = newFrame.size.width - leftWidth - newMidWidth - dividerThickness*2;
                    rightFrame.size.width = rightWidth;
                } else {
                    rightWidth = ceil((halfWidth*rightRatio) - (newMidWidth*rightRatio)/2.);
                    rightWidth += newMidWidth;
                    rightFrame.size.width = rightWidth;
                    
                    leftWidth = newFrame.size.width - rightWidth - newMidWidth - dividerThickness*2;
                    leftFrame.size.width = leftWidth;
                    
                    rightFrame.origin.x = leftWidth + newMidWidth + dividerThickness*2;
                }
            }

            midFrame.origin.x = leftFrame.size.width + dividerThickness;
            rightFrame.origin.x = newFrame.size.width - rightFrame.size.width;
        } else if (leftViewOpen) {
            leftFrame.size.width = newFrame.size.width - (newMidWidth + dividerThickness);
            midFrame.origin.x = leftFrame.size.width + dividerThickness;
        } else if (rightViewOpen) {
            rightFrame.size.width = newFrame.size.width - (newMidWidth + dividerThickness);
            rightFrame.origin.x = newMidWidth + dividerThickness;
        }
    
        midFrame.size.width = newMidWidth;
    }
    
    leftSuperview.frame = leftFrame;
    [leftView setFrameSize:leftFrame.size];
    hSplitView.frame = midFrame;
    rightSuperview.frame = rightFrame;
    [rightView setFrameSize:rightFrame.size];
}


- (void)hSplitView:(NSSplitView *)splitView resizeSubviewsWithOldSize:(NSSize)oldSize {
    NSRect newFrame = splitView.frame; // get the new size of the whole splitView
    
    NSRect topFrame = topSuperview.frame;
    NSRect midFrame = hSplitView.frame;
    NSRect bottomFrame = bottomSuperview.frame;
    
    if (-1 == dragStartMidWidth) {
        dragStartMidWidth = midFrame.size.height;
        dragStartBottomRatio = topFrame.size.height / bottomFrame.size.height;
        dragStartTopRatio = bottomFrame.size.height / topFrame.size.height;
    }
    
    BOOL wasCollapsed = (dragStartMidWidth <= 0.);
    
    BOOL bothOpen = (topViewOpen && bottomViewOpen);
    
    CGFloat dividerThickness = splitView.dividerThickness;
    
    topFrame.size.width = newFrame.size.width;
    midFrame.size.width = newFrame.size.width;
    bottomFrame.size.width = newFrame.size.width;
    
    CGFloat topHeight, bottomHeight;
    if (wasCollapsed) {
        topHeight = abs(topFrame.size.height);
        bottomHeight = abs(bottomFrame.size.height);
    } else {
        topHeight = abs([self storedTopSplitPosition]);
        bottomHeight = abs([self storedBottomSplitPosition]);
        topFrame.size.height = topHeight;
        bottomFrame.size.height = bottomHeight;
    }
    
    if (bothOpen) { // both open
        midFrame.size.height = newFrame.size.height - topHeight - bottomHeight - dividerThickness*2;
        midFrame.origin.y = topHeight + dividerThickness;
        bottomFrame.origin.y = midFrame.origin.y + midFrame.size.height + dividerThickness;
    } else if (topViewOpen) { // only top open
        midFrame.size.height = newFrame.size.height - topHeight - dividerThickness;
        midFrame.origin.y = topHeight + dividerThickness;
    } else if (bottomViewOpen) { // only bottom open
        midFrame.size.height = newFrame.size.height - bottomHeight - dividerThickness;
        midFrame.origin.y = 0.;
        bottomFrame.origin.y = midFrame.origin.y + midFrame.size.height + dividerThickness;
    } else { // both closed. BTW. this is still needed.
        midFrame.size.height = newFrame.size.height;
        midFrame.origin.y = 0.;
    }
    
    // prevent overlap
    if (wasCollapsed || midFrame.size.height < 24.) {
        CGFloat newMidHeight = wasCollapsed ? 0. : 24.;
        
        if (bothOpen) {
            CGFloat halfHeight = newFrame.size.height/2.;
            
            if (wasCollapsed) {
                if (dragStartTopRatio < dragStartBottomRatio) {
                    topHeight = newFrame.size.height - ceil(((halfHeight*dragStartTopRatio) - dividerThickness*2));
                    topFrame.size.height = topHeight;
                    
                    bottomHeight = newFrame.size.height - topHeight - newMidHeight - dividerThickness*2;
                    bottomFrame.size.height = bottomHeight;
                } else {
                    bottomHeight = newFrame.size.height - ceil(halfHeight*dragStartBottomRatio);
                    bottomFrame.size.height = bottomHeight;
                    
                    topHeight = newFrame.size.height - bottomHeight - newMidHeight - dividerThickness*2;
                    topFrame.size.height = topHeight;
                    
                    bottomFrame.origin.y = topHeight + newMidHeight + dividerThickness*2;
                }
            } else {
                CGFloat topRatio = topHeight / bottomHeight;
                CGFloat bottomRatio = bottomHeight / topHeight;
                if (topRatio < bottomRatio) {
                    topHeight = ceil(((halfHeight*topRatio) - (newMidHeight*topRatio)/2.));
                    topHeight += newMidHeight + dividerThickness*2;
                    topFrame.size.height = topHeight;
                    
                    bottomHeight = newFrame.size.height - topHeight - newMidHeight - dividerThickness*2;
                    bottomFrame.size.height = bottomHeight;
                } else {
                    bottomHeight = ceil((halfHeight*bottomRatio) - (newMidHeight*bottomRatio)/2.);
                    bottomHeight += newMidHeight;
                    bottomFrame.size.height = bottomHeight;
                    
                    topHeight = newFrame.size.height - bottomHeight - newMidHeight - dividerThickness*2;
                    topFrame.size.height = topHeight;
                    
                    bottomFrame.origin.y = topHeight + newMidHeight + dividerThickness*2;
                }
            }
            
            midFrame.origin.y = topFrame.size.height + dividerThickness;
            bottomFrame.origin.y = newFrame.size.height - bottomFrame.size.height;
        } else if (topViewOpen) {
            topFrame.size.height = newFrame.size.height - (newMidHeight + dividerThickness);
            //midFrame.origin.x = 0.;
            midFrame.origin.y = topFrame.size.height + dividerThickness;
        } else if (bottomViewOpen) {
            bottomFrame.size.height = newFrame.size.height - (newMidHeight + dividerThickness);
            bottomFrame.origin.y = newMidHeight + dividerThickness;
        }
        
        midFrame.size.height = newMidHeight;
    }
    
    topSuperview.frame = topFrame;
    [topView setFrameSize:topFrame.size];
    midSuperview.frame = NSMakeRect(0., midFrame.origin.y, midFrame.size.width, midFrame.size.height);
    midView.frame = NSMakeRect(0., 0., midFrame.size.width, midFrame.size.height);
    bottomSuperview.frame = bottomFrame;
    [bottomView setFrameSize:bottomFrame.size];
}


- (void)splitViewDidResizeSubviews:(NSNotification *)n {
    //NSLog(@"%s", _cmd);
    [timer invalidate];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:.1
                                                  target:self
                                                selector:@selector(timerFired:)
                                                userInfo:nil
                                                 repeats:NO];
}


#pragma mark -
#pragma mark Private

- (void)timerFired:(NSTimer*)t {
    [self storeSplitPositions];
}


- (void)storeSplitPositions {
    [self storeOpenStates];
    [self storeLeftSplitPosition];
    [self storeRightSplitPosition];
    [self storeTopSplitPosition];
    [self storeBottomSplitPosition];
}


- (void)storeOpenStates {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    [userDefaults setBool:leftViewOpen forKey:@"TDUberView_leftViewOpen"];
    [userDefaults setBool:rightViewOpen forKey:@"TDUberView_rightViewOpen"];    
    [userDefaults setBool:topViewOpen forKey:@"TDUberView_topViewOpen"];
    [userDefaults setBool:bottomViewOpen forKey:@"TDUberView_bottomViewOpen"];
    [userDefaults synchronize];
}


- (void)storeLeftSplitPosition {
    if (leftViewOpen) {
        CGFloat leftViewWidth = abs(leftSuperview.frame.size.width);
        leftViewWidth = (leftViewWidth < 1.) ? 1. : leftViewWidth;
        [[NSUserDefaults standardUserDefaults] setFloat:leftViewWidth forKey:@"TDUberView_leftViewWidth"];
    }
}


- (void)storeRightSplitPosition {
    if (rightViewOpen) {
        CGFloat rightViewWidth = abs(rightSuperview.frame.size.width);
        [[NSUserDefaults standardUserDefaults] setFloat:rightViewWidth forKey:@"TDUberView_rightViewWidth"];
    }
}


- (void)storeTopSplitPosition {
    if (topViewOpen) {
        CGFloat topViewHeight = abs(topSuperview.frame.size.height);
        topViewHeight = (topViewHeight < 1.) ? 1. : topViewHeight;
        [[NSUserDefaults standardUserDefaults] setFloat:topViewHeight forKey:@"TDUberView_topViewHeight"];
    }
}


- (void)storeBottomSplitPosition {
    if (bottomViewOpen) {
        CGFloat bottomViewHeight = abs(bottomView.frame.size.height);
        [[NSUserDefaults standardUserDefaults] setFloat:bottomViewHeight forKey:@"TDUberView_bottomViewHeight"];
    }
}


- (void)restoreSplitPositions {
    [self restoreOpenStates];
    [self restoreLeftSplitPosition];
    [self restoreRightSplitPosition];
    [self restoreTopSplitPosition];
    [self restoreBottomSplitPosition];
}


- (void)restoreOpenStates {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    NSNumber *openObj = [userDefaults objectForKey:@"TDUberView_leftViewOpen"];
    if (openObj) {
        self.leftViewOpen = [openObj boolValue];
    }
    openObj = [userDefaults objectForKey:@"TDUberView_rightViewOpen"];
    if (openObj) {
        self.rightViewOpen = [openObj boolValue];
    }
    openObj = [userDefaults objectForKey:@"TDUberView_topViewOpen"];
    if (openObj) {
        self.topViewOpen = [openObj boolValue];
    }
    openObj = [userDefaults objectForKey:@"TDUberView_bottomViewOpen"];
    if (openObj) {
        self.bottomViewOpen = [openObj boolValue];
    }
}


- (CGFloat)storedLeftSplitPosition {
    CGFloat leftViewWidth = 0.;
    
    if (self.isLeftViewOpen) {
        leftViewWidth = preferredLeftSplitWidth;
        NSNumber *leftViewWidthObj = [[NSUserDefaults standardUserDefaults] objectForKey:@"TDUberView_leftViewWidth"];
        if (leftViewWidthObj) {
            leftViewWidth = [leftViewWidthObj floatValue];
        }
    }
    
    return leftViewWidth;
}


- (void)restoreLeftSplitPosition {
    CGFloat leftViewWidth = [self storedLeftSplitPosition];
    NSRect midFrame = hSplitView.frame;
    midFrame.origin.x = leftViewWidth;
    midFrame.size.width -= leftViewWidth;
    hSplitView.frame = midFrame;
    
    NSRect leftFrame = leftSuperview.frame;
    leftFrame.size.width = leftViewWidth;
    leftSuperview.frame = leftFrame;
}


- (CGFloat)storedRightSplitPosition {
    CGFloat rightViewWidth = 0.;
    
    if (self.isRightViewOpen) {
        rightViewWidth = preferredRightSplitWidth;
        NSNumber *rightViewWidthObj = [[NSUserDefaults standardUserDefaults] objectForKey:@"TDUberView_rightViewWidth"];
        if (rightViewWidthObj) {
            rightViewWidth = [rightViewWidthObj floatValue];
        }
    }
    
    return rightViewWidth;
}


- (void)restoreRightSplitPosition {
    CGFloat rightViewWidth = [self storedRightSplitPosition];
    //CGFloat dividerThickness = vSplitView.dividerThickness;
    NSRect midFrame = hSplitView.frame;
    midFrame.size.width = vSplitView.frame.size.width - abs(leftSuperview.frame.size.width) - rightViewWidth;
    hSplitView.frame = midFrame;
    
    NSRect rightFrame = rightSuperview.frame;
    
    rightFrame.size.width = rightViewWidth;
    rightFrame.origin.x = (vSplitView.frame.size.width - rightViewWidth);
    rightSuperview.frame = rightFrame;
}


- (CGFloat)storedTopSplitPosition {
    CGFloat topViewHeight = 0.;
    
    if (self.isTopViewOpen) {
        topViewHeight = preferredTopSplitHeight;
        NSNumber *heightObj = [[NSUserDefaults standardUserDefaults] objectForKey:@"TDUberView_topViewHeight"];
        if (heightObj) {
            topViewHeight = [heightObj floatValue];
        }
    }
    
    return topViewHeight;
}


- (void)restoreTopSplitPosition {
    CGFloat topViewHeight = [self storedTopSplitPosition];
    CGFloat dividerThickness = hSplitView.dividerThickness;
    NSRect midFrame = midSuperview.frame;
    midFrame.origin.y = topViewHeight;
    midFrame.size.height -= topViewHeight - dividerThickness;
    midSuperview.frame = midFrame;
    
    NSRect topFrame = topSuperview.frame;
    topFrame.size.height = topViewHeight;
    topSuperview.frame = topFrame;
}


- (CGFloat)storedBottomSplitPosition {
    CGFloat bottomViewHeight = 0.;
    
    if (self.isBottomViewOpen) {
        bottomViewHeight = preferredBottomSplitHeight;
        NSNumber *heightObj = [[NSUserDefaults standardUserDefaults] objectForKey:@"TDUberView_bottomViewHeight"];
        if (heightObj) {
            bottomViewHeight = [heightObj floatValue];
        }
    }
    
    return bottomViewHeight;
}


- (void)restoreBottomSplitPosition {
    CGFloat bottomViewHeight = [self storedBottomSplitPosition];
    CGFloat dividerThickness = hSplitView.dividerThickness;
    NSRect midFrame = midSuperview.frame;
    midFrame.size.height = hSplitView.frame.size.height - abs(topSuperview.frame.size.height) - bottomViewHeight - dividerThickness;
    midSuperview.frame = midFrame;
    
    NSRect bottomFrame = bottomSuperview.frame;
    
    bottomFrame.size.width = MAXFLOAT;
    bottomFrame.size.height = bottomViewHeight;
    bottomFrame.origin.y = (midFrame.origin.y + midFrame.size.height + dividerThickness);
    bottomSuperview.frame = bottomFrame;
}


#pragma mark -
#pragma mark Accessors

- (NSView *)leftView {
    return [[leftView retain] autorelease];
}


- (void)setLeftView:(NSView *)v {
    if (v != leftView) {
        // remove old leftView from view hierarchy
        [leftView removeFromSuperview];
        
        // mem mgmt
        [leftView autorelease];
        leftView = [v retain];
        
        // if leftView is not nil...
        if (leftView) {
            // set sizing of new leftView...
            leftView.autoresizingMask = NSViewHeightSizable|NSViewWidthSizable; //NSViewMinXMargin|NSViewMinYMargin|NSViewMaxXMargin|NSViewMaxYMargin|
            leftView.frame = leftSuperview.bounds;
            
            // & add to leftSuperview
            [leftSuperview addSubview:leftView];
        }
    }
}


- (NSView *)rightView {
    return [[rightView retain] autorelease];
}


- (void)setRightView:(NSView *)v {
    if (v != rightView) {
        // remove old rightView from view hierarchy
        [rightView removeFromSuperview];
        
        // mem mgmt
        [rightView autorelease];
        rightView = [v retain];
        
        // if rightView is not nil...
        if (rightView) {
            // set sizing of new rightView...
            rightView.autoresizingMask = NSViewHeightSizable|NSViewWidthSizable; //NSViewMinXMargin|NSViewMinYMargin|NSViewMaxXMargin|NSViewMaxYMargin|
            rightView.frame = rightSuperview.bounds;
            
            // & add to rightSuperview
            [rightSuperview addSubview:rightView];
            
        }
    }
}


- (NSView *)topView {
    return [[topView retain] autorelease];
}


- (void)setTopView:(NSView *)v {
    if (v != topView) {
        // remove old topView from view hierarchy
        [topView removeFromSuperview];
        
        // mem mgmt
        [topView autorelease];
        topView = [v retain];
        
        // if topView is not nil...
        if (topView) {
            // set sizing of new topView...
            topView.autoresizingMask = NSViewHeightSizable|NSViewWidthSizable; //NSViewMinXMargin|NSViewMinYMargin|NSViewMaxXMargin|NSViewMaxYMargin|
            topView.frame = topSuperview.bounds;
            
            // & add to topSuperview
            [topSuperview addSubview:topView];
            
        }
    }
}


- (NSView *)midView {
    return [[midView retain] autorelease];
}


- (void)setMidView:(NSView *)v {
    if (v != midView) {
        [midView autorelease];
        midView = [v retain];
        midView.autoresizingMask = NSViewHeightSizable|NSViewWidthSizable; //NSViewMinXMargin|NSViewMinYMargin|NSViewMaxXMargin|NSViewMaxYMargin|
        midView.frame = midSuperview.bounds;
        [midSuperview addSubview:midView];
    }
}


- (NSView *)bottomView {
    return [[bottomView retain] autorelease];
}


- (void)setBottomView:(NSView *)v {
    if (v != bottomView) {
        // remove old bottomView from view hierarchy
        [bottomView removeFromSuperview];
        
        // mem mgmt
        [bottomView autorelease];
        bottomView = [v retain];
        
        // if bottomView is not nil...
        if (bottomView) {
            // set sizing of new bottomView...
            bottomView.autoresizingMask = NSViewHeightSizable|NSViewWidthSizable; //NSViewMinXMargin|NSViewMinYMargin|NSViewMaxXMargin|NSViewMaxYMargin|
            bottomView.frame = bottomSuperview.bounds;
            
            // & add to bottomSuperview
            [bottomSuperview addSubview:bottomView];
            
        }
    }
}


- (NSSplitViewDividerStyle)splitViewDividerStyle {
    return splitViewDividerStyle;
}


- (void)setSplitViewDividerStyle:(NSSplitViewDividerStyle)s {
    splitViewDividerStyle = s;
    [self setNeedsDisplay:YES];
}


- (void)resetCapturing {
    dragStartMidWidth = -1;
    dragStartMidWidth = -1;
    dragStartRightRatio = -1;
    dragStartLeftRatio = -1;
    dragStartMidHeight = -1;
    dragStartTopRatio = -1;
    dragStartBottomRatio = -1;
}

@synthesize vSplitView;
@synthesize hSplitView;

@synthesize leftSuperview;
@synthesize rightSuperview;
@synthesize bottomSuperview;
@synthesize topSuperview;
@synthesize midSuperview;

@dynamic leftView;
@dynamic rightView;
@dynamic bottomView;
@dynamic topView;
@dynamic midView;

@dynamic splitViewDividerStyle;

@synthesize timer;

@synthesize preferredLeftSplitWidth;
@synthesize preferredRightSplitWidth;
@synthesize preferredTopSplitHeight;
@synthesize preferredBottomSplitHeight;
@synthesize snapsToPreferredSplitWidths;

@synthesize snapTolerance;

@synthesize leftViewOpen;
@synthesize rightViewOpen;
@synthesize topViewOpen;
@synthesize bottomViewOpen;
@end

static NSComparisonResult TDVSplitViewSubviewComparatorFunc(id viewA, id viewB, TDUberView *self) {
    if (viewA == self.leftSuperview) {
        return NSOrderedAscending;
    } else if (viewA == self.rightSuperview) {
        return NSOrderedDescending;
    } else { // (viewA == self.hSplitView)
        return (viewB == self.leftSuperview) ? NSOrderedDescending : NSOrderedAscending;
    }
}

static NSComparisonResult TDHSplitViewSubviewComparatorFunc(id viewA, id viewB, TDUberView *self) {
    if (viewA == self.topSuperview) {
        return NSOrderedAscending;
    } else if (viewA == self.bottomSuperview) {
        return NSOrderedDescending;
    } else { // (viewA == self.mid)
        return (viewB == self.topSuperview) ? NSOrderedDescending : NSOrderedAscending;
    }
}
