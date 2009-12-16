//
//  CRTwitterPlugInPrefsViewController.h
//  TwitterPlugIn
//
//  Created by Todd Ditchendorf on 10/11/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface CRTwitterPlugInPrefsViewController : NSViewController {
	IBOutlet NSArrayController *arrayController;
    NSMutableArray *accounts;
    NSMutableArray *accountIDs;
}

- (void)insertObject:(NSMutableDictionary *)dict inAccountsAtIndex:(NSInteger)i;
- (void)removeObjectFromAccountsAtIndex:(NSInteger)i;

@property (nonatomic, retain) NSMutableArray *accounts;
@property (nonatomic, retain) NSMutableArray *accountIDs;

- (NSArray *)usernames;
- (NSString *)passwordFor:(NSString *)username;
@end
