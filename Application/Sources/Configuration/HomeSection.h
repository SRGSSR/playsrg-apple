//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, HomeSection) {
    HomeSectionUnknown = 0,
    
    // Radio sections
    HomeSectionRadioLatestEpisodes,
    HomeSectionRadioMostPopular,
    HomeSectionRadioLatest,
    HomeSectionRadioLatestVideos,
    HomeSectionRadioAllShows,
    HomeSectionRadioShowsAccess,
    HomeSectionRadioFavoriteShows,
    
    // Live sections
    HomeSectionTVLive,
    HomeSectionRadioLive,
    HomeSectionRadioLiveSatellite,
    HomeSectionTVLiveCenter,
    HomeSectionTVScheduledLivestreams
};

NS_ASSUME_NONNULL_END
