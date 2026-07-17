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

+ (NSString *)play_businessUnitIdentifier
{
    return [NSBundle.mainBundle objectForInfoDictionaryKey:@"BusinessUnitIdentifier"];
}

+ (NSURL *)play_sharedBusinessUnitContainerURL
{
    NSString *groupIdentifier = [NSBundle.mainBundle objectForInfoDictionaryKey:@"SharedApplicationGroupIdentifier"];
    NSString *businessUnit = self.play_businessUnitIdentifier;
    if (groupIdentifier.length == 0 || businessUnit.length == 0) {
        return nil;
    }
    NSURL *containerURL = [self.defaultManager containerURLForSecurityApplicationGroupIdentifier:groupIdentifier];
    return [containerURL URLByAppendingPathComponent:businessUnit isDirectory:YES];
}

@end
