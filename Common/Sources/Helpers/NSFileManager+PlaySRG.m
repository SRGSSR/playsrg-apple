//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NSFileManager+PlaySRG.h"

@implementation NSFileManager (PlaySRG)

+ (NSURL *)play_applicationGroupContainerURL
{
    static dispatch_once_t s_onceToken;
    static NSURL *s_groupContainerURL;
    dispatch_once(&s_onceToken, ^{
        NSString *groupIdentifier = [NSBundle.mainBundle objectForInfoDictionaryKey:@"ApplicationGroupIdentifier"];
        s_groupContainerURL = [self.defaultManager containerURLForSecurityApplicationGroupIdentifier:groupIdentifier];
        NSAssert(s_groupContainerURL, @"The group container cannot be accessed");
    });
    return s_groupContainerURL;
}

@end
