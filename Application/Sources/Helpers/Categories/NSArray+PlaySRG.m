//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NSArray+PlaySRG.h"

@implementation NSArray (PlaySRG)

- (NSArray *)play_arrayByRemovingObjectAtIndex:(NSUInteger)index
{
    NSMutableArray *mutableArray = self.mutableCopy;
    [mutableArray removeObjectAtIndex:index];
    return mutableArray.copy;
}

- (NSArray *)play_arrayByRemovingObjectsInArray:(NSArray *)array
{
    NSMutableArray *mutableArray = self.mutableCopy;
    [mutableArray removeObjectsInArray:array];
    return mutableArray.copy;
}

@end
