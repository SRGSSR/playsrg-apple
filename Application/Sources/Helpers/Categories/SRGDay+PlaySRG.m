//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGDay+PlaySRG.h"

@implementation SRGDay (PlaySRG)

- (BOOL)isBetweenDay:(SRGDay *)fromDay andDay:(SRGDay *)toDay
{
    return ([self compare:fromDay] != NSOrderedAscending && [self compare:toDay] != NSOrderedDescending);
}

@end
