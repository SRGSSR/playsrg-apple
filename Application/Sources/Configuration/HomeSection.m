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
        s_names = @{ @(HomeSectionTVLive) : NSLocalizedString(@"TV channels", @"Title label to present main TV livestreams"),
                     @(HomeSectionTVScheduledLivestreams) : NSLocalizedString(@"Events", @"Title label used to present scheduled livestream medias"),
                     @(HomeSectionTVLiveCenter) : NSLocalizedString(@"Sport", @"Title label used to present live center medias"),
                     @(HomeSectionRadioLive) : NSLocalizedString(@"Radio channels", @"Title label to present main radio livestreams"),
                     @(HomeSectionRadioLiveSatellite) : NSLocalizedString(@"Music radios", @"Title label to present musical Swiss satellite radios"),
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
