//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Channel.h"

NS_ASSUME_NONNULL_BEGIN

// Forward declarations
@class RadioChannel;

/**
 *  Images associated with the radio channel.
 */
OBJC_EXPORT UIImage *RadioChannelBanner22Image(RadioChannel * _Nullable radioChannel);
OBJC_EXPORT UIImage *RadioChannelLogo22Image(RadioChannel * _Nullable radioChannel);

/**
 *  Represent a radio channel in the application configuration.
 */
@interface RadioChannel : Channel

/**
 *  The home sections ordered list.
 */
@property (nonatomic, readonly) NSArray<NSNumber *> *homeSections;                      // wrap `HomeSection` values

@end

NS_ASSUME_NONNULL_END
