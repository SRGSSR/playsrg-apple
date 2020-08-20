//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Channel.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Represent a TV channel in the application configuration.
 */
@interface TVChannel : Channel

@end

/**
 *  Images associated with the TV channel.
 */
OBJC_EXPORT UIImage *TVChannelLogo22Image(TVChannel * _Nullable tvChannel);
OBJC_EXPORT UIImage *TVChannelLogo32Image(TVChannel * _Nullable tvChannel);

NS_ASSUME_NONNULL_END
