//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ApplicationSectionInfo.h"

NS_ASSUME_NONNULL_BEGIN

@interface ProfileTableViewCell : UITableViewCell

@property (class, nonatomic, readonly) CGFloat height;

@property (nonatomic) ApplicationSectionInfo *applicationSectionInfo;

@end

NS_ASSUME_NONNULL_END
