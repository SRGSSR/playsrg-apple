//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NSSet+PlaySRG.h"

@implementation NSSet (PlaySRG)

#pragma mark Public methods

- (NSSet *)play_setByRemovingObjectsInSet:(NSSet *)set
{
    NSMutableSet *mutableSet = [self mutableCopy];
    [mutableSet minusSet:set];
    return [mutableSet copy];
}

@end
