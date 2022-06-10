//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Channel.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Represent a radio channel in the application configuration.
 */
@interface RadioChannel : Channel

/**
 *  Create a radio channel.
 */
- (nullable instancetype)initWithDictionary:(NSDictionary *)dictionary
                        defaultHomeSections:(nullable NSArray<NSNumber *> *)defaultHomeSections NS_DESIGNATED_INITIALIZER;

/**
 *  `YES` iff a homepage can be displayed for the radio channel.
 */
@property (nonatomic, readonly) BOOL hasHomepage;

/**
 *  The home sections ordered list.
 */
@property (nonatomic, readonly) NSArray<NSNumber *> *homeSections;                      // wrap `HomeSection` values

@end

/**
 *  Images associated with the radio channel.
 */
OBJC_EXPORT UIImage *RadioChannelLogoImage(RadioChannel * _Nullable radioChannel);
OBJC_EXPORT UIImage *RadioChannelLargeLogoImage(RadioChannel * _Nullable radioChannel);
OBJC_EXPORT UIImage *RadioChannelLogoImageWithTraitCollection(RadioChannel * _Nullable radioChannel, UITraitCollection * _Nullable traitCollection);

NS_ASSUME_NONNULL_END
