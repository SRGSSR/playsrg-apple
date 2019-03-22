//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NSArray+PlaySRG.h"

@implementation NSArray (PlaySRG)

- (NSArray *)play_arrayByInsertingObject:(id)object atIndex:(NSUInteger)index
{
    NSMutableArray *array = [self mutableCopy];
    [array insertObject:object atIndex:index];
    return [array copy];
}

- (NSArray *)play_arrayByRemovingObjectAtIndex:(NSUInteger)index
{
    NSMutableArray *array = [self mutableCopy];
    [array removeObjectAtIndex:index];
    return [array copy];
}

@end
