//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "HomeSection.h"

NSString *TitleForHomeSection(HomeSection homeSection)
{
    static NSDictionary<NSNumber *, NSString *> *s_names;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_names = @{ @(HomeSectionTVTrending) : NSLocalizedString(@"Trending videos", @"Title label used to present trending TV videos"),
                     @(HomeSectionTVLive) : NSLocalizedString(@"TV channels", @"Title label to present main TV livestreams"),
                     @(HomeSectionTVEvents) : NSLocalizedString(@"Highlights", @"Title label used to present TV event modules while loading. It appears if no network connection is available and no cache is available"),
                     @(HomeSectionTVTopics) : NSLocalizedString(@"Topics", @"Title label used to present TV topics while loading. It appears if no network connection is available and no cache is available"),
                     @(HomeSectionTVTopicsAccess) : NSLocalizedString(@"Topics", @"Title label used to present TV topics"),
                     @(HomeSectionTVLatest) : NSLocalizedString(@"Latest videos", @"Title label used to present the latest videos"),
                     @(HomeSectionTVMostPopular) : NSLocalizedString(@"Most popular", @"Title label used to present the TV most popular videos"),
                     @(HomeSectionTVSoonExpiring) : NSLocalizedString(@"Available for a limited time", @"Title label used to present the soon expiring videos"),
                     @(HomeSectionTVScheduledLivestreams) : NSLocalizedString(@"Events", @"Title label used to present scheduled livestream medias"),
                     @(HomeSectionTVLiveCenter) : NSLocalizedString(@"Sport", @"Title label used to present live center medias"),
                     @(HomeSectionTVShowsAccess) : NSLocalizedString(@"Shows", @"Title label used to present the TV shows AZ and TV shows by date access buttons"),
                     @(HomeSectionTVFavoriteShows) : NSLocalizedString(@"Favorites", @"Title label used to present the TV favorite shows"),
                     @(HomeSectionRadioLive) : NSLocalizedString(@"Radio channels", @"Title label to present main radio livestreams"),
                     @(HomeSectionRadioLiveSatellite) : NSLocalizedString(@"Thematic radios", @"Title label to present Swiss satellite radios"),
                     @(HomeSectionRadioLatestEpisodes) : NSLocalizedString(@"The latest episodes", @"Title label used to present the radio latest audio episodes"),
                     @(HomeSectionRadioMostPopular) : NSLocalizedString(@"Most listened to", @"Title label used to present the radio most popular audio medias"),
                     @(HomeSectionRadioLatest) : NSLocalizedString(@"The latest audios", @"Title label used to present the radio latest audios"),
                     @(HomeSectionRadioLatestVideos) : NSLocalizedString(@"Latest videos", @"Title label used to present the radio latest videos"),
                     @(HomeSectionRadioAllShows) : NSLocalizedString(@"Shows", @"Title label used to present radio associated shows"),
                     @(HomeSectionRadioShowsAccess) : NSLocalizedString(@"Shows", @"Title label used to present the radio shows AZ and radio shows by date access buttons"),
                     @(HomeSectionRadioFavoriteShows) : NSLocalizedString(@"Favorites", @"Title label used to present the radio favorite shows") };
    });
    return s_names[@(homeSection)];
}
