//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "MenuItemInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface MenuTableViewCell : UITableViewCell

@property (nonatomic) MenuItemInfo *menuItemInfo;
@property (nonatomic, getter=isCurrent) BOOL current;

@end

NS_ASSUME_NONNULL_END
