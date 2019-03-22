//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface NSArray<__covariant ObjectType> (PlaySRG)

- (NSArray<ObjectType> *)play_arrayByInsertingObject:(ObjectType)object atIndex:(NSUInteger)index;
- (NSArray<ObjectType> *)play_arrayByRemovingObjectAtIndex:(NSUInteger)index;

@end

NS_ASSUME_NONNULL_END
