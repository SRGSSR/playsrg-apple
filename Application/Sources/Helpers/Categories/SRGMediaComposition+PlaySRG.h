//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import SRGDataProviderModel;
@import SRGLetterbox;

NS_ASSUME_NONNULL_BEGIN

// Completion block signatures.
typedef void (^PlayPlaybackContextBlock)(SRGResource *resource, NSArray<SRGSegment *> * _Nullable segments);

@interface SRGMediaComposition (PlaySRG)

/**
 *  Check chapters and segments from the receiver and return the first subdivision matching the specified URN. If no
 *  match is found, `nil` is returned.
 */
- (nullable SRGSubdivision *)play_subdivisionWithURN:(NSString *)URN;

/**
 *  Retrieve a playback context for the receiver, trying to use the specified preferred settings. If no exact match can
 *  be found for the specified settings, a recommended approaching valid setup will be used instead.
 *
 *  @discussion See `playbackContextWithPreferredSettings:contextBlock:` documentation in `SRGMediaComposition+SRGAnalyticsDataProvider.h`.
 */
- (BOOL)play_playbackContextWithPreferredSettings:(nullable SRGLetterboxPlaybackSettings *)preferredSettings
                                     contextBlock:(NS_NOESCAPE PlayPlaybackContextBlock)contextBlock;

@end

NS_ASSUME_NONNULL_END
