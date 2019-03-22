//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Favorite.h"

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface Favorite (Private)

/**
 *  Add favorite object directly
 */
+ (BOOL)addFavorite:(Favorite *)favorite;

/**
 *  Create favorite from a dictionary of its fields
 */
- (nullable instancetype)initWithDictionary:(NSDictionary *)dictionary;

@end

NS_ASSUME_NONNULL_END
