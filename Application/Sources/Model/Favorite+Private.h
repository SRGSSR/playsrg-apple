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

@interface Favorite (WatchLaterMigration)

/**
 *  Available media favorites, sorted by date at which they were favorited (from the oldest to the most recent)
 */
@property (class, nonatomic, readonly) NSArray<Favorite *> *mediaFavorites;

/**
 *  Remove "old" favorites files (without notifying changes)
 */
+ (void)finishMigrationForFavorites:(NSArray<Favorite *> *)favorites;

@end

NS_ASSUME_NONNULL_END
