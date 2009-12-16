/*
 * Copyright (c) 2006 KATO Kazuyoshi <kzys@8-p.info>
 * This source code is released under the MIT license.
 */

#import "FUWildcardPattern.h"

#define TLD_PATTERN @"(\\.([a-z]+))?\\.(ac|ad|ae|aero|af|ag|ai|al|am|an|ao|aq|ar|arpa|as|asia|at|au|aw|ax|az|ba|bb|bd|be|bf|bg|bh|bi|biz|bj|bm|bn|bo|br|bs|bt|bv|bw|by|bz|ca|cat|cc|cd|cf|cg|ch|ci|ck|cl|cm|cn|co|com|coop|cr|cu|cv|cx|cy|cz|de|dj|dk|dm|do|dz|ec|edu|ee|eg|er|es|et|eu|fi|fj|fk|fm|fo|fr|ga|gb|gd|ge|gf|gg|gh|gi|gl|gm|gn|gov|gp|gq|gr|gs|gt|gu|gw|gy|hk|hm|hn|hr|ht|hu|id|ie|il|im|in|info|int|io|iq|ir|is|it|je|jm|jo|jobs|jp|ke|kg|kh|ki|km|kn|kp|kr|kw|ky|kz|la|lb|lc|li|lk|lr|ls|lt|lu|lv|ly|ma|mc|md|me|mg|mh|mil|mk|ml|mm|mn|mo|mobi|mp|mq|mr|ms|mt|mu|museum|mv|mw|mx|my|mz|na|name|nc|ne|net|nf|ng|ni|nl|no|np|nr|nu|nz|om|org|pa|pe|pf|pg|ph|pk|pl|pm|pn|pr|pro|ps|pt|pw|py|qa|re|ro|root|rs|ru|rw|sa|sb|sc|sd|se|sg|sh|si|sj|sk|sl|sm|sn|so|sr|st|su|sv|sy|sz|tc|td|tel|tf|tg|th|tj|tk|tl|tm|tn|to|tp|tr|travel|tt|tv|tw|tz|ua|ug|uk|um|us|uy|uz|va|vc|ve|vg|vi|vn|vu|wf|ws|ye|yt|yu|za|zm|zw)"

static NSCharacterSet *sRegexMetaCharSet = nil;

@interface FUWildcardPattern ()
+ (NSString *)escapeRegexpMetaCharactors:(NSString *)src;
+ (NSString *)regexpFromURIGlob:(NSString *)src;
@end

@implementation FUWildcardPattern

+ (void)initialize {
    if ([FUWildcardPattern class] == self) {
        if (!sRegexMetaCharSet) {
            sRegexMetaCharSet = [[NSCharacterSet characterSetWithCharactersInString:@".*+?^$()[]{}"] retain];
        }
    }
}


+ (id)patternWithString:(NSString *)s {
    return [[[self alloc] initWithString:s] autorelease];
}


+ (NSString *)escapeRegexpMetaCharactors:(NSString *)src {
    NSMutableString *result = [NSMutableString string];
    NSInteger i = 0;
    NSInteger n = [src length];
    for ( ; i < n; i++) {
        unichar c = [src characterAtIndex:i];
        if (c == (unichar)'*') {
            [result appendString:@".*"];
        } else {
            if ([sRegexMetaCharSet characterIsMember:c]) {
                [result appendString:@"\\"];
            }
            [result appendFormat:@"%C", c];
        }
    }
    return result;
}


+ (NSString *)regexpFromURIGlob:(NSString *)src {
    // .tld
    NSRange r = [src rangeOfString:@".tld"];
    if (r.length > 0) {
        NSMutableString *result = [NSMutableString string];
        NSString *s = [src substringToIndex:r.location];
        [result appendString:[self escapeRegexpMetaCharactors:s]];
        [result appendString:TLD_PATTERN];

        s = [src substringFromIndex:r.location + r.length];
        [result appendString:[self regexpFromURIGlob:s]]; // recursive
        return result;
    } else {
        return [self escapeRegexpMetaCharactors:src];
    }
}


- (id)initWithString:(NSString *)s {
    if (self = [self init]) {
        self.string = s;
    }
    return self;
}


- (void)dealloc {
    self.string = nil;
    [super dealloc];
}


- (void)setString:(NSString *)s {
    if (s != string) {
        [string release];
        string = [s copy];
        regfree(&pattern);

        if (string) {
            NSString *tmp = [[self class] regexpFromURIGlob:string];
            regcomp(&pattern, [[NSString stringWithFormat:@"^%@$", tmp] UTF8String], REG_NOSUB|REG_EXTENDED);
        }
    }
}


- (BOOL)isMatch:(NSString *)s {
    return 0 == regexec(&pattern, [s UTF8String], 0, NULL, 0);
}


- (NSString *)description {
    return [NSString stringWithFormat:@"<FUWildcardPattern %@>", string];
}

@synthesize string;
@end
