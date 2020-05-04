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
 *  Image overrides.
 */
OBJC_EXPORT NSString * _Nullable RadioChannelImageOverridePath(RadioChannel * _Nullable radioChannel, NSString *type);

/**
 *  Represent a radio channel in the application configuration.
 */
@interface RadioChannel : Channel

/**
 *  Return `YES` iff the status bar should be dark for this channel.
 */
@property (nonatomic, readonly, getter=hasDarkStatusBar) BOOL darkStatusBar;

/**
 *  Set to `YES` to hide the badge stroke (the badge stroke color matches title color). Default is `NO`.
 */
@property (nonatomic, readonly, getter=isBadgeStrokeHidden) BOOL badgeStrokeHidden;

/**
 *  The home sections ordered list.
 */
@property (nonatomic, readonly) NSArray<NSNumber *> *homeSections;                      // wrap `HomeSection` values

@end

NS_ASSUME_NONNULL_END
