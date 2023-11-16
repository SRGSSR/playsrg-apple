//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Channel.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  TV guide bouquet.
 */
typedef NS_CLOSED_ENUM(NSInteger, TVGuideBouquet) {
    /**
     *  Third party bouquet.
     */
    TVGuideBouquetThirdParty = 0,
    /**
     *  SRG SSR bouquets.
     */
    TVGuideBouquetRSI,
    TVGuideBouquetRTS,
    TVGuideBouquetSRF
};

/**
 *  Represent a TV channel in the application configuration.
 */
@interface TVChannel : Channel

@end

/**
 *  Images associated with the TV channel.
 */
OBJC_EXPORT UIImage *TVChannelLogoImage(TVChannel * _Nullable tvChannel);
OBJC_EXPORT UIImage *TVChannelLargeLogoImage(TVChannel * _Nullable tvChannel);

NS_ASSUME_NONNULL_END
