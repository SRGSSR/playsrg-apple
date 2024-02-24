//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import SRGDataProviderModel;
@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface UILabel (PlaySRG)

/**
 *  Use this method to display the correct availability label for some media.
 */
- (void)play_displayAvailabilityBadgeForMedia:(SRGMedia *)media;

/**
 *  Call to display the standard "web first" badge.
*/
- (void)play_setWebFirstBadge;

@end

NS_ASSUME_NONNULL_END
