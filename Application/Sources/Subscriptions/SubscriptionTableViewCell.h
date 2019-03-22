//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Previewing.h"

#import <MGSwipeTableCell/MGSwipeTableCell.h>
#import <SRGDataProvider/SRGDataProvider.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SubscriptionTableViewCell : MGSwipeTableCell <Previewing>

@property (nonatomic, nullable) SRGShow *show;

@end

NS_ASSUME_NONNULL_END
