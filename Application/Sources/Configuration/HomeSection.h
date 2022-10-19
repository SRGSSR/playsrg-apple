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
    HomeSectionRadioAllShows,
    HomeSectionRadioFavoriteShows,
    HomeSectionRadioLatest,
    HomeSectionRadioLatestEpisodes,
    HomeSectionRadioLatestEpisodesFromFavorites,
    HomeSectionRadioLatestVideos,
    HomeSectionRadioMostPopular,
    HomeSectionRadioResumePlayback,
    HomeSectionRadioShowsAccess,
    HomeSectionRadioWatchLater,
    
    // Live sections
    HomeSectionTVLive,
    HomeSectionTVLiveCenterScheduledLivestreams,
    HomeSectionTVLiveCenterScheduledLivestreamsAll,
    HomeSectionTVLiveCenterEpisodes,
    HomeSectionTVLiveCenterEpisodesAll,
    HomeSectionTVScheduledLivestreams,
    HomeSectionRadioLive,
    HomeSectionRadioLiveSatellite
};

NS_ASSUME_NONNULL_END
