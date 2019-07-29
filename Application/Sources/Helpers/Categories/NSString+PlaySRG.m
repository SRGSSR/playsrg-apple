//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NSString+PlaySRG.h"

#import "NSDateFormatter+PlaySRG.h"

@implementation NSString (PlaySRG)

#pragma mark Getters and setters

- (NSString *)play_localizedUppercaseFirstLetterString
{
    NSString *firstUppercaseCharacter = [self substringToIndex:1].localizedUppercaseString;
    return [firstUppercaseCharacter stringByAppendingString:[self substringFromIndex:1]];
}

@end
