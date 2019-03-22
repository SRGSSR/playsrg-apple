//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Favorite.h"
#import "Previewing.h"

#import <MGSwipeTableCell/MGSwipeTableCell.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface FavoriteTableViewCell : MGSwipeTableCell <Previewing>

@property (nonatomic, nullable) Favorite *favorite;

@end

NS_ASSUME_NONNULL_END
