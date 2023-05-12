//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NSString+PlaySRG.h"

@import CommonCrypto;

static NSString* digest(NSString *string, unsigned char *(*cc_digest)(const void *, CC_LONG, unsigned char *), CC_LONG digestLength)
{
    // Hash calculation
    unsigned char md[digestLength];     // C99
    memset(md, 0, sizeof(md));
    const char *utf8str = string.UTF8String;
    cc_digest(utf8str, (CC_LONG)strlen(utf8str), md);
    
    // Hexadecimal representation
    NSMutableString *hexHash = [NSMutableString string];
    for (NSUInteger i = 0; i < sizeof(md); ++i) {
        [hexHash appendFormat:@"%02X", md[i]];
    }
    
    return hexHash.lowercaseString;
}

@implementation NSString (PlaySRG)

#pragma mark Getters and setters

- (NSString *)play_localizedUppercaseFirstLetterString
{
    NSString *firstUppercaseCharacter = [self substringToIndex:1].localizedUppercaseString;
    return [firstUppercaseCharacter stringByAppendingString:[self substringFromIndex:1]];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-declarations"

- (NSString *)play_md5hash
{
    // MD5 is deprecated, but still used by gravatar.com
    // https://en.gravatar.com/site/implement
    return digest(self, CC_MD5, CC_MD5_DIGEST_LENGTH);
}

#pragma clang diagnostic pop

@end
