//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import CoreMedia;
@import SRGDataProviderModel;
@import UIKit;

NS_ASSUME_NONNULL_BEGIN

/**
 *  An item which can be used for sharing purposes.
 */
@interface SharingItem : NSObject <UIActivityItemSource>

+ (nullable instancetype)sharingItemForMedia:(SRGMedia *)media atTime:(CMTime)time;
+ (nullable instancetype)sharingItemForShow:(SRGShow *)show;
+ (nullable instancetype)sharingItemForContentSection:(SRGContentSection *)contentSection;

@property (nonatomic, readonly) NSURL *URL;
@property (nonatomic, readonly, copy) NSString *title;
@property (nonatomic, readonly, copy) NSString *analyticsUid;

@end

NS_ASSUME_NONNULL_END
