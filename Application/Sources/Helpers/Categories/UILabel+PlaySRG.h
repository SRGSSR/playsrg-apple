//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>

#import <SRGDataProvider/SRGDataProvider.h>

NS_ASSUME_NONNULL_BEGIN

@interface UILabel (PlaySRG)

/**
 *  Use it in a duration label, to set it as a live label
 */
- (void)play_displayDurationLabelForLive;

/**
 *  Use this method to display the correct duration label for an object conform to a media metadata
 */
- (void)play_displayDurationLabelForMediaMetadata:(id<SRGMediaMetadata>)object;

/**
 *  Use this method to display the correct availability label for an object conform to a media metadata, if needed
 */
- (void)play_displayAvailabilityLabelForMediaMetadata:(id<SRGMediaMetadata>)object;

/**
*  Call to display the standard subtitle availability badge.
*/
- (void)play_setSubtitlesAvailableBadge;

/**
 *  Call to display the standard "web first" badge.
*/
- (void)play_setWebFirstBadge;

@end

NS_ASSUME_NONNULL_END
