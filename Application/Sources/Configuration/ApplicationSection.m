//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ApplicationSection.h"

NSString *TitleForApplicationSection(ApplicationSection applicationSection)
{
    static NSDictionary<NSNumber *, NSString *> *s_names;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_names = @{ @(ApplicationSectionDownloads) : NSLocalizedString(@"Downloads", @"Label to present downloads"),
                     @(ApplicationSectionFavorites) : NSLocalizedString(@"Favorites", @"Label to present Favorites"),
                     @(ApplicationSectionHistory) : NSLocalizedString(@"History", @"Label to present history"),
                     @(ApplicationSectionNotifications) : NSLocalizedString(@"Notifications", @"Label to present the help page"),
                     @(ApplicationSectionSearch) : NSLocalizedString(@"Search", @"Label to present the search view"),
                     @(ApplicationSectionShowByDate) : NSLocalizedString(@"Programmes by date", @"Label to present programmes by date"),
                     @(ApplicationSectionOverview) : NSLocalizedString(@"Overview", @"Label to present the main Videos / Audios views"),
                     @(ApplicationSectionLive) : NSLocalizedString(@"Livestreams", @"Label to present the Livestreams view"),
                     @(ApplicationSectionShowAZ) : NSLocalizedString(@"Programmes A-Z", @"Label to present shows A to Z (radio or TV)"),
                     @(ApplicationSectionWatchLater) : NSLocalizedString(@"Watch later", @"Label to present the watch later list") };
    });
    return s_names[@(applicationSection)];
}
