//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "AnalyticsConstants.h"

@import CoreMedia;
@import SRGDataProviderModel;
@import UIKit;

NS_ASSUME_NONNULL_BEGIN

/**
 *  An item which can be used for sharing purposes.
 */
@interface SharingItem : NSObject <UIActivityItemSource>

+ (nullable instancetype)sharingItemForMedia:(SRGMedia *)media atTime:(CMTime)time;
+ (nullable instancetype)sharingItemForCurrentClip:(SRGMedia *)media;
+ (nullable instancetype)sharingItemForShow:(SRGShow *)show;
+ (nullable instancetype)sharingItemForContentSection:(SRGContentSection *)contentSection;

@end

@interface UIActivityViewController (SharingItem)

/**
 *  Create an activity view controller for sharing the specified item.
 *
 *  @param source The source of the action.
 */
- (instancetype)initWithSharingItem:(SharingItem *)sharingItem
                             source:(AnalyticsSource)source
                withCompletionBlock:(nullable void (^)(UIActivityType activityType))completionBlock;

@end

NS_ASSUME_NONNULL_END
