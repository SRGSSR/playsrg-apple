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

- (nullable instancetype)initWithDictionary:(NSDictionary *)dictionary
                        defaultHomeSections:(NSArray<NSNumber *> *)defaultHomeSections NS_DESIGNATED_INITIALIZER;

/**
 *  The home sections ordered list.
 */
@property (nonatomic, readonly) NSArray<NSNumber *> *homeSections;                      // wrap `HomeSection` values

@end

/**
 *  Images associated with the radio channel.
 */
OBJC_EXPORT UIImage *RadioChannelLogo22Image(RadioChannel * _Nullable radioChannel);
OBJC_EXPORT UIImage *RadioChannelLogo32Image(RadioChannel * _Nullable radioChannel);

NS_ASSUME_NONNULL_END
