//
//  CRBaseViewController.h
//  TwitterPlugIn
//
//  Created by Todd Ditchendorf on 11/8/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import <UMEKit/UMEKit.h>
#import "MGTwitterEngine.h"

@class WebView;
@class DOMHTMLElement;
@class MGTemplateEngine;

@interface CRBaseViewController : UMEViewController <MGTwitterEngineDelegate> {
    IBOutlet WebView *webView;

    MGTwitterEngine *twitterEngine;
    MGTemplateEngine *templateEngine;
    NSString *templateString;
    NSString *statusTemplateString;
}

- (void)setUpTwitterEngine;
- (void)setUpTemplateEngine;

- (NSMutableArray *)processStatuses:(NSArray *)inStatuses;
- (void)appendMarkup:(NSString *)htmlStr toElement:(DOMHTMLElement *)el;
- (void)insertMarkup:(NSString *)htmlStr toElement:(DOMHTMLElement *)el;
- (void)replaceMarkup:(NSString *)htmlStr inElement:(DOMHTMLElement *)el;


- (void)pushTimelineFor:(NSString *)username;
- (void)handleUsernameClicked:(NSString *)username;
- (void)openUserPageInNewTabOrWindow:(NSString *)username;
- (void)openURLInNewTabOrWindow:(NSString *)URLString;
- (void)openURLString:(NSString *)URLString inNewTab:(BOOL)inTab;
- (void)openURL:(NSURL *)URLString inNewTab:(BOOL)inTab;

@property (nonatomic, retain) MGTwitterEngine *twitterEngine;
@property (nonatomic, retain) MGTemplateEngine *templateEngine;
@property (nonatomic, copy) NSString *templateString;
@property (nonatomic, copy) NSString *statusTemplateString;
@end
