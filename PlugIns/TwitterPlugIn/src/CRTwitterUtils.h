//
//  CRTwitterUtils.h
//  TwitterPlugIn
//
//  Created by Todd Ditchendorf on 10/17/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import <Cocoa/Cocoa.h>

NSString *CRMarkedUpStatus(NSString *inStatus, NSArray **outMentions);

NSString *CRDefaultProfileImageURLString();
NSURL *CRDefaultProfileImageURL();
NSImage *CRDefaultProfileImage();
NSString *CRFormatDateString(NSString *s);
NSString *CRFormatDate(NSDate *inDate);

NSString *CRStringByTrimmingCruzPrefixFromURL(NSURL *URL);
NSString *CRStringByTrimmingCruzPrefixFromString(NSString *s);