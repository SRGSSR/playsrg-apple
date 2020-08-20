//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Previewing.h"

#import <MGSwipeTableCell/MGSwipeTableCell.h>

@import SRGDataProvider;
@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@class FavoriteTableViewCell;

@protocol FavoriteTableViewCellDelegate <NSObject>

- (void)favoriteTableViewCell:(FavoriteTableViewCell *)favoriteTableViewCell deleteShow:(SRGShow *)show;

@end

@interface FavoriteTableViewCell : MGSwipeTableCell <Previewing>

@property (nonatomic, nullable) SRGShow *show;
@property (nonatomic, weak) id<FavoriteTableViewCellDelegate> cellDelegate;

@end

NS_ASSUME_NONNULL_END
