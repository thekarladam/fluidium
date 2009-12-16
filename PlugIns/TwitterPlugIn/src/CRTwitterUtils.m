//
//  CRTwitterUtils.m
//  TwitterPlugIn
//
//  Created by Todd Ditchendorf on 10/17/09.
//  Copyright 2009 Todd Ditchendorf. All rights reserved.
//

#import "CRTwitterUtils.h"
#import "CRTwitterPlugIn.h"
#import <ParseKit/ParseKit.h>

static NSString *CRMarkedUpHashtag(PKTokenizer *t, PKToken *inTok, PKToken *poundTok);
static NSString *CRMarkedUpUsername(PKTokenizer *t, PKToken *inTok, PKToken *atTok, NSString **outUsername);
static NSString *CRMarkedUpURL(PKTokenizer *t, PKToken *inTok, PKToken *colonSlashSlashTok);

NSString *CRMarkedUpStatus(NSString *inStatus, NSArray **outMentions) {
    NSMutableArray *mentions = nil;
    NSMutableString *ms = [NSMutableString stringWithCapacity:[inStatus length]];
    
    static PKTokenizer *t = nil;
    static PKToken *ltTok = nil;
    static PKToken *atTok = nil;
    static PKToken *poundTok = nil;
    static PKToken *httpTok = nil;
    static PKToken *httpsTok = nil;
    static PKToken *colonSlashSlashTok = nil;
    if (!t) {
        //PKToken *wwwTok = [PKToken tokenWithTokenType:PKTokenTypeSymbol stringValue:@"www." floatValue:0];
        ltTok = [[PKToken alloc] initWithTokenType:PKTokenTypeSymbol stringValue:@"<" floatValue:0];
        atTok = [[PKToken alloc] initWithTokenType:PKTokenTypeSymbol stringValue:@"@" floatValue:0];
        poundTok = [[PKToken alloc] initWithTokenType:PKTokenTypeSymbol stringValue:@"#" floatValue:0];
        httpTok = [[PKToken alloc] initWithTokenType:PKTokenTypeWord stringValue:@"http" floatValue:0];
        httpsTok = [[PKToken alloc] initWithTokenType:PKTokenTypeWord stringValue:@"https" floatValue:0];
        colonSlashSlashTok = [[PKToken alloc] initWithTokenType:PKTokenTypeSymbol stringValue:@"://" floatValue:0];

        t = [[PKTokenizer alloc] init];
        [t.symbolState remove:@"<="];
        [t.symbolState remove:@">="];
        [t.symbolState remove:@"!="];
        [t.symbolState remove:@"=="];

        // no comments
        [t setTokenizerState:t.symbolState from:'/' to:'/'];
        [t setTokenizerState:t.symbolState from:'#' to:'#'];

        // no quotes
        [t.wordState setWordChars:NO from:'\'' to:'\''];
        [t setTokenizerState:t.whitespaceState from:'"' to:'"'];
        [t.whitespaceState setWhitespaceChars:YES from:'"' to:'"'];
        [t setTokenizerState:t.whitespaceState from:'\'' to:'\''];
        [t.whitespaceState setWhitespaceChars:YES from:'\'' to:'\''];

        t.whitespaceState.reportsWhitespaceTokens = YES;
        [t setTokenizerState:t.whitespaceState from:'(' to:')'];
        [t.whitespaceState setWhitespaceChars:YES from:'(' to:')'];
        
        [t.symbolState add:[colonSlashSlashTok stringValue]];
        //[t.symbolState add:[wwwTok stringValue]];
        
        [t setTokenizerState:t.wordState from:'0' to:'9'];
   }
    
    t.string = inStatus;

    PKToken *eof = [PKToken EOFToken];
    PKToken *tok = nil;
    NSString *s = nil;
    
    while ((tok = [t nextToken]) != eof) {
        if ([atTok isEqual:tok]) {
            NSString *uname = nil;
            s = CRMarkedUpUsername(t, tok, atTok, &uname);
            if (uname && [uname length]) {
                if (!mentions) {
                    mentions = [NSMutableArray array];
                }
                [mentions addObject:uname];
            }
        } else if ([poundTok isEqual:tok]) {
            s = CRMarkedUpHashtag(t, tok, poundTok);
        } else if ([httpTok isEqual:tok] || [httpsTok isEqual:tok]) {
            s = CRMarkedUpURL(t, tok, colonSlashSlashTok);
        } else if ([ltTok isEqual:tok]) {
            s = @"&lt;";
        } else {
            s = [tok stringValue];
        }
        
        [ms appendString:s];
    }
	
    if (mentions) {
        *outMentions = mentions;
    }
    return [[ms copy] autorelease];
}


static NSString *CRMarkedUpHashtag(PKTokenizer *t, PKToken *inTok, PKToken *poundTok) {
    PKToken *eof = [PKToken EOFToken];
    NSMutableString *ms = [NSMutableString stringWithString:[inTok stringValue]];
    
    PKToken *tok = nil;
    while (tok = [t nextToken]) {
        NSString *s = [tok stringValue];
        
        if (eof == tok) {
            break;
        } else if ([poundTok isEqual:tok]) {
            [ms appendString:s];
            continue;
        } else if (tok.isWord) {
            [ms setString:@""];
            [ms appendFormat:@"<a class='hashtag' href='http://twitter.com/search?q=%%23%@' onclick='cruz.linkClicked(\"http://twitter.com/search?q=%%23%@\"); return false;'>#%@</a>", s, s, s];
            break;
        } else {
            [ms appendString:s];
            break;
        }
    }
    return ms;
}


static NSString *CRMarkedUpUsername(PKTokenizer *t, PKToken *inTok, PKToken *atTok, NSString **outUsername) {
    PKToken *eof = [PKToken EOFToken];
    NSMutableString *ms = [NSMutableString stringWithString:[inTok stringValue]];
    
    PKToken *tok = nil;
    while (tok = [t nextToken]) {
        NSString *s = [tok stringValue];
        
        if (eof == tok) {
            break;
        } else if ([atTok isEqual:tok]) {
            [ms appendString:s];
            continue;
        } else if (tok.isWord) {
            [ms setString:@""];
            [ms appendFormat:@"<a title='nostatus' class='username' href='http://twitter.com/%@' onclick='cruz.usernameClicked(\"%@\"); return false;'><span class='at'>@</span>%@</a>", s, s, s];
            if (outUsername) {
                *outUsername = s;
            }
            break;
        } else {
            [ms appendString:s];
            break;
        }
    }
    return ms;
}


static NSString *CRMarkedUpURL(PKTokenizer *t, PKToken *inTok, PKToken *colonSlashSlashTok) {
    PKToken *tok = [t nextToken];
    if (![colonSlashSlashTok isEqual:tok]) {
        return [NSString stringWithFormat:@"%@%@", [inTok stringValue], [tok stringValue]];
    }
    
    PKToken *eof = [PKToken EOFToken];
    NSMutableString *ms = [NSMutableString string];
    
    NSString *s = nil;
    while (tok = [t nextToken]) {
        s = [tok stringValue];
        
        if (eof == tok || tok.isWhitespace) {
            break;
        } else if ([s length] && ((PKUniChar)[s characterAtIndex:0]) > 255) { // no non-ascii chars plz
            break;
        } else {
            [ms appendString:s];
        }
    }
    
    NSString *display = [[ms copy] autorelease];
    NSInteger maxLen = 32;
    if ([display length] > maxLen) {
        display = [NSString stringWithFormat:@"%@%C", [display substringToIndex:maxLen], 0x2026];
    }
    
    if ([display hasSuffix:@"/"]) {
        display = [display substringToIndex:[display length] - 1];
    }
    
    ms = [NSMutableString stringWithFormat:@"<a class='url' href='http://%@' onclick='cruz.linkClicked(\"http://%@\"); return false;'>%@</a>", ms, ms, display];
    if (s) [ms appendString:s];
    return ms;
}


NSString *CRDefaultProfileImageURLString() {
    static NSString *sDefaultProfileImageURLString = nil;
    
    if (!sDefaultProfileImageURLString) {
        sDefaultProfileImageURLString = [[[NSBundle bundleForClass:[CRTwitterPlugIn class]] pathForResource:@"default_profile_pic" ofType:@"png"] retain];
    }

    return sDefaultProfileImageURLString;
}


NSURL *CRDefaultProfileImageURL() {
    static NSURL *sDefaultProfileImageURL = nil;
    
    if (!sDefaultProfileImageURL) {
        sDefaultProfileImageURL = [[NSURL alloc] initFileURLWithPath:CRDefaultProfileImageURLString()];
    }

    return sDefaultProfileImageURL;
}


NSImage *CRDefaultProfileImage() {
    static NSImage *sDefaultProfileImage = nil;
    
    if (!sDefaultProfileImage) {
        sDefaultProfileImage = [[NSImage alloc] initWithContentsOfURL:CRDefaultProfileImageURL()];
    }
    
    return sDefaultProfileImage;
}


NSString *CRFormatDateString(NSString *inStr) {
    static NSDateFormatter *fmt = nil;
    if (!fmt) {
        fmt = [[NSDateFormatter alloc] init];
        [fmt setDateFormat:@"yyyy-MM-dd HH:mm:SS zzzz"]; // 2009-10-17 17:31:01 -0700
    }
    
    NSDate *date = [fmt dateFromString:inStr];
    return CRFormatDate(date);
}


NSString *CRFormatDate(NSDate *inDate) {
    NSTimeInterval secs = abs([inDate timeIntervalSinceNow]);
    
    NSString *s = nil;
    if (secs < 60) {
        float seconds = (float)round((float)secs);
        if (1 == seconds) {
            s = [NSString stringWithFormat:NSLocalizedString(@"%2.0f sec ago", @""), seconds];
        } else {
            s = [NSString stringWithFormat:NSLocalizedString(@"%2.0f secs ago", @""), seconds];
        }
    } else if (secs < 120) {
        s = NSLocalizedString(@"1 min ago", @"");
    } else if (secs < 60 * 60) {
        s = [NSString stringWithFormat:NSLocalizedString(@"%1.0f mins ago", @""), (float)round((float)secs/(float)60.0)];
    } else if (secs < 60 * 60 * 24) {
        float hours = (float)round((float)secs /(float)(60. * 60.));
        if (1 == hours) {
            s = [NSString stringWithFormat:NSLocalizedString(@"%1.0f hour ago", @""), hours];
        } else {
            s = [NSString stringWithFormat:NSLocalizedString(@"%1.0f hours ago", @""), hours];
        }
    } else {
        static NSDateFormatter *fmt = nil;
        if (!fmt) {
            fmt = [[NSDateFormatter alloc] init];
            //            [fmt setDateFormat:@"HH:mm 'on' EEEE MMMM d"]; // 2009-07-08T:02:08:14Z
            [fmt setDateFormat:@"MMM d"]; // 2009-07-08T:02:08:14Z
        }
        s = [fmt stringFromDate:inDate];
    }
    
    return s;
}


NSString *CRStringByTrimmingCruzPrefixFromString(NSString *inStr) {
    static NSString *prefix = nil;
    if (!prefix) {
        prefix = [[NSString alloc] initWithString:@"cruz:"];
    }
    
    if ([inStr hasPrefix:prefix]) {
        return [inStr substringFromIndex:5];
    } else {
        return inStr;
    }
}


NSString *CRStringByTrimmingCruzPrefixFromURL(NSURL *URL) {
    return CRStringByTrimmingCruzPrefixFromString([URL absoluteString]);
}

