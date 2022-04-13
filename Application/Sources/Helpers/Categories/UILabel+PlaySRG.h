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
 *  Use this method to display the correct duration label for some media metadata.
 */
- (void)play_displayDurationLabelForMediaMetadata:(id<SRGMediaMetadata>)mediaMetadata;

/**
 *  Use this method to display the correct date label for some media metadata.
 */
- (void)play_displayDateLabelForMediaMetadata:(id<SRGMediaMetadata>)mediaMetadata;

/**
 *  Use this method to display the correct availability label for some media metadata.
 */
- (void)play_displayAvailabilityBadgeForMediaMetadata:(id<SRGMediaMetadata>)mediaMetadata;

/**
 *  Call to display the standard "web first" badge.
*/
- (void)play_setWebFirstBadge;

@end

NS_ASSUME_NONNULL_END
