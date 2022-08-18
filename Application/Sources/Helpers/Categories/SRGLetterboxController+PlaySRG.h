//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import SRGLetterbox;

NS_ASSUME_NONNULL_BEGIN

@interface SRGLetterboxController (PlaySRG)

@property (nonatomic, readonly, nullable) NSDateInterval *play_dateInterval;

@property (nonatomic, readonly, nullable) SRGMedia *play_mainMedia;

@end

NS_ASSUME_NONNULL_END
