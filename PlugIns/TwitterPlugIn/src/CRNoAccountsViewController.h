//
//  CRNoAccountsViewController.h
//  TwitterPlugIn
//
//  Created by Todd Ditchendorf on 11/3/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import <UMEKit/UMEKit.h>

@interface CRNoAccountsViewController : UMEViewController {
    IBOutlet NSButton *addAccountButton;
}

- (void)showPrefs:(id)sender;
@end
