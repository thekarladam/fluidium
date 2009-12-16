//
//  DOMNode+FUAdditions.h
//  Fluidium
//
//  Created by Todd Ditchendorf on 5/25/08.
//  Copyright 2008 Todd Ditchendorf. All rights reserved.
//

#import <WebKit/WebKit.h>

@interface DOMNode (FUAdditions)
- (DOMElement *)FU_firstAncestorOrSelfByTagName:(NSString *)tagName;
- (CGFloat)FU_totalOffsetTop;
- (CGFloat)FU_totalOffsetLeft;
@end
