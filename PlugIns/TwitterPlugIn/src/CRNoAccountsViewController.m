//
//  CRNoAccountsViewController.m
//  TwitterPlugIn
//
//  Created by Todd Ditchendorf on 11/3/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import "CRNoAccountsViewController.h"
#import "CRTwitterPlugIn.h"
#import "CRTwitterPlugInPrefsViewController.h"
#import "FUPlugInAPI.h"

@implementation CRNoAccountsViewController

- (id)init {
    return [self initWithNibName:@"CRNoAccountsView" bundle:[NSBundle bundleForClass:[CRNoAccountsViewController class]]];
}


- (id)initWithNibName:(NSString *)s bundle:(NSBundle *)b {
    if (self = [super initWithNibName:s bundle:b]) {
        
    }
    return self;
}


- (void)dealloc {    
    [super dealloc];
}


- (void)showPrefs:(id)sender {
    [[CRTwitterPlugIn instance] showPrefs:sender];
}

@end
