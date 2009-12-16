//
//  CRThreadViewController.m
//  TwitterPlugIn
//
//  Created by Todd Ditchendorf on 11/8/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import "CRThreadViewController.h"
#import "CRTwitterPlugIn.h"
#import "CRTwitterUtils.h"
#import "MGTemplateEngine.h"
#import "ICUTemplateMatcher.h"
#import <WebKit/WebKit.h>

@interface CRThreadViewController ()
- (NSDictionary *)varsWithStatus:(NSDictionary *)d;
- (void)prepareAndDisplayMarkup;
- (void)appendStatusToMarkup;
- (void)fetchInReplyToStatus;
- (void)done;

- (NSString *)markedUpStatus:(NSString *)inStatus;
- (NSString *)formattedDate:(NSString *)inDate;    
@end

@implementation CRThreadViewController

- (id)init {
    return [self initWithNibName:@"CRThreadView" bundle:[NSBundle bundleForClass:[CRThreadViewController class]]];
}


- (id)initWithNibName:(NSString *)s bundle:(NSBundle *)b {
    if (self = [super initWithNibName:s bundle:b]) {
        self.hidesBottomBarWhenPushed = YES;
    }
    return self;
}


- (void)dealloc {
    self.status = nil;
    self.usernameA = nil;
    self.usernameB = nil;
    [super dealloc];
}


#pragma mark -
#pragma mark UMEViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self.navigationItem.rightBarButtonItem = [[[UMEActivityBarButtonItem alloc] init] autorelease];
    self.navigationItem.rightBarButtonItem.enabled = NO;

    [self prepareAndDisplayMarkup];
}


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
}


- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    
}


- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    
}


- (void)viewDidDisappear:(BOOL)animated {
    [super viewDidDisappear:animated];
    
}


#pragma mark -
#pragma mark Private

- (void)setUpTemplateEngine {
    self.templateEngine = [MGTemplateEngine templateEngine];
    [templateEngine setMatcher:[ICUTemplateMatcher matcherWithTemplateEngine:templateEngine]];

    NSString *path = [[NSBundle bundleForClass:[self class]] pathForResource:@"thread" ofType:@"html"];
    NSString *threadStr = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    
    path = [[NSBundle bundleForClass:[self class]] pathForResource:@"timeline" ofType:@"css"];
    NSString *cssStr = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    threadStr = [threadStr stringByReplacingOccurrencesOfString:@"___CSS___" withString:cssStr];
    
    path = [[NSBundle bundleForClass:[self class]] pathForResource:@"status" ofType:@"html"];
    self.statusTemplateString = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    threadStr = [threadStr stringByReplacingOccurrencesOfString:@"___STATUS___" withString:statusTemplateString];
    
    self.templateString = threadStr;
}


- (NSDictionary *)varsWithStatus:(NSDictionary *)d {
    id displayUsernames = [[NSUserDefaults standardUserDefaults] objectForKey:kCRTwitterDisplayUsernamesKey];
    
    NSDictionary *vars = [NSDictionary dictionaryWithObjectsAndKeys:
                          [NSArray arrayWithObject:d], @"statuses",
                          displayUsernames, @"displayUsernames",
                          //CRDefaultProfileImageURLString(), @"defaultAvatarURLString",
                          nil];
    
    return vars;
}


- (void)prepareAndDisplayMarkup {
    NSAssert([status count], @"");
    
    NSMutableDictionary *d = [[status mutableCopy] autorelease];
    [d setObject:[NSNumber numberWithBool:NO] forKey:@"isReply"];
    
    NSDictionary *vars = [self varsWithStatus:d];
    NSString *htmlStr = [templateEngine processTemplate:templateString withVariables:vars];
    [[webView mainFrame] loadHTMLString:htmlStr baseURL:nil];
}


- (void)appendStatusToMarkup {
    if (![NSThread isMainThread]) {
        [self performSelectorOnMainThread:@selector(appendStatusToMarkup) withObject:nil waitUntilDone:NO];
        return;
    }    
    
    NSMutableDictionary *d = [[status mutableCopy] autorelease];
    [d setObject:[NSNumber numberWithBool:NO] forKey:@"isReply"];

    NSDictionary *vars = [self varsWithStatus:d];
    NSString *newStatusHTMLStr = [templateEngine processTemplate:statusTemplateString withVariables:vars];

    DOMDocument *doc = [[webView mainFrame] DOMDocument];
    
    DOMHTMLElement *threadEl = (DOMHTMLElement *)[doc getElementById:@"thread"];
    [super appendMarkup:newStatusHTMLStr toElement:threadEl];
    
    [self fetchInReplyToStatus];
}


- (void)fetchInReplyToStatus {
    NSNumber *statusID = [status objectForKey:@"inReplyToStatusID"];
    if (statusID) {
        [twitterEngine getUpdate:[statusID longLongValue]];
    } else {
        [self done];
    }
}


- (void)statusesReceived:(NSArray *)inStatuses forRequest:(NSString *)requestID {
    NSMutableArray *newStatuses = [super processStatuses:inStatuses];

    if (![newStatuses count]) {
        return;
    }
    
    NSAssert(1 == [newStatuses count], @"");
    
    NSMutableDictionary *d = [newStatuses objectAtIndex:0];
    [d setObject:CRFormatDate([status objectForKey:@"created_at"]) forKey:@"date"];
    self.status = d;
    
    [self appendStatusToMarkup];
}


- (void)requestFailed:(NSString *)connectionIdentifier withError:(NSError *)error {
    [super requestFailed:connectionIdentifier withError:error];
    [self done];
}


- (void)done {
    self.navigationItem.rightBarButtonItem = nil;
}


- (NSString *)markedUpStatus:(NSString *)inStatus {
    NSArray *mentions = nil;
    return CRMarkedUpStatus(inStatus, &mentions);
}


- (NSString *)formattedDate:(NSString *)inDate {
    return CRFormatDateString(inDate);
}


#pragma mark -
#pragma mark WebFrameLoadDelegate

- (void)webView:(WebView *)wv didClearWindowObject:(WebScriptObject *)wso forFrame:(WebFrame *)frame {
    if (frame != [wv mainFrame]) return;

    [wso setValue:self forKey:@"cruz"];
}


- (void)webView:(WebView *)wv didFinishLoadForFrame:(WebFrame *)frame {
    if (frame != [wv mainFrame]) return;

    [self fetchInReplyToStatus];
}


#pragma mark -
#pragma mark WebScripting

- (void)linkClicked:(NSString *)URLString {
    [self openURLInNewTabOrWindow:URLString];
}


- (void)avatarClicked:(NSString *)username {
    [self openUserPageInNewTabOrWindow:username];
}


- (void)usernameClicked:(NSString *)username {
    [super handleUsernameClicked:username];
}


+ (BOOL)isKeyExcludedFromWebScript:(const char *)name {
    return YES;
}


+ (BOOL)isSelectorExcludedFromWebScript:(SEL)sel {
    if (@selector(avatarClicked:) == sel ||
        @selector(linkClicked:) == sel ||
        @selector(usernameClicked:) == sel) {
        return NO;
    } else {
        return YES;
    }
}


+ (NSString *)webScriptNameForKey:(const char *)name {
    return nil;
}


+ (NSString *)webScriptNameForSelector:(SEL)sel {
    if (@selector(usernameClicked:) == sel) {
        return @"usernameClicked";
    } else if (@selector(avatarClicked:) == sel) {
        return @"avatarClicked";
    } else if (@selector(linkClicked:) == sel) {
        return @"linkClicked";
    } else {
        return nil;
    }
}

@synthesize status;
@synthesize usernameA;
@synthesize usernameB;
@end
