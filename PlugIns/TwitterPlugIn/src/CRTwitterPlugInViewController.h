//
//  CRTwitterPlugInViewController.h
//  TwitterPlugIn
//
//  Created by Todd Ditchendorf on 10/11/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <UMEKit/UMEKit.h>

@class CRTwitterPlugIn;
@class CRTimelineViewController;
@class CRNoAccountsViewController;

@interface CRTwitterPlugInViewController : NSViewController {
	CRTwitterPlugIn *plugIn;
        
    UMETabBarController *tabBarController;

    CRNoAccountsViewController *noAccountsViewController;
    CRTimelineViewController *homeViewController;
    CRTimelineViewController *mentionsViewController;
    
    UMENavigationController *homeNavController;
    UMENavigationController *mentionsNavController;
}

- (void)willAppear;
- (void)didAppear;
- (void)willDisappear;
- (void)didDisappear;

- (void)setUpTimelineAndMentionsIfNecessary;
- (void)setUpTimelineAndMentions;

@property (nonatomic, assign) CRTwitterPlugIn *plugIn;

@property (nonatomic, retain) CRNoAccountsViewController *noAccountsViewController;
@property (nonatomic, retain) UMETabBarController *tabBarController;
@property (nonatomic, retain) CRTimelineViewController *homeViewController;
@property (nonatomic, retain) UMENavigationController *homeNavController;
@property (nonatomic, retain) CRTimelineViewController *mentionsViewController;
@property (nonatomic, retain) UMENavigationController *mentionsNavController;
@end
