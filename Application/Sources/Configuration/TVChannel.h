//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Channel.h"

NS_ASSUME_NONNULL_BEGIN

// Forward declarations
@class TVChannel;

/**
 *  Images associated with the TV channel.
 */
OBJC_EXPORT UIImage *TVChannelBanner22Image(TVChannel * _Nullable tvChannel);

/**
 *  Image overrides.
 */
OBJC_EXPORT NSString * _Nullable TVChannelImageOverridePath(TVChannel * _Nullable tvChannel, NSString *type);

/**
 *  Represent a TV channel in the application configuration.
 */
@interface TVChannel : Channel

@end

NS_ASSUME_NONNULL_END
