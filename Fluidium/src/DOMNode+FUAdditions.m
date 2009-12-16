//
//  DOMNode+FUAdditions.m
//  Fluidium
//
//  Created by Todd Ditchendorf on 5/25/08.
//  Copyright 2008 Todd Ditchendorf. All rights reserved.
//

#import "DOMNode+FUAdditions.h"

@implementation DOMNode (FUAdditions)

- (DOMElement *)FU_firstAncestorOrSelfByTagName:(NSString *)tagName {
    DOMNode *curr = self;
    do {
        if (DOM_ELEMENT_NODE == [curr nodeType] && [[[curr nodeName] lowercaseString] isEqualToString:tagName]) {
            return (DOMElement *)curr;
        }
    } while (curr = [curr parentNode]);
    
    return nil;
}


- (CGFloat)FU_totalOffsetTop {
    DOMElement *curr = (DOMElement *)self;
    CGFloat result = 0;
    do {
        result += [curr offsetTop];
    } while ((curr = (DOMElement *)[curr parentNode]) && ![[[curr nodeName] lowercaseString] isEqualToString:@"html"]);
    
    return result;
}


- (CGFloat)FU_totalOffsetLeft {
    DOMElement *curr = (DOMElement *)self;
    CGFloat result = 0;
    do {
        result += [curr offsetLeft];
    } while ((curr = (DOMElement *)[curr parentNode]) && ![[[curr nodeName] lowercaseString] isEqualToString:@"html"]);
    
    return result;
}

@end
