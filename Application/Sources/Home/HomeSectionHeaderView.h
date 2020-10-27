//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import UIKit;

#import "HomeSectionInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface HomeSectionHeaderView : UITableViewHeaderFooterView

@property (nonatomic, nullable) HomeSectionInfo *homeSectionInfo;
@property (nonatomic, readonly, getter=isFeatured) BOOL featured;

@end

NS_ASSUME_NONNULL_END
