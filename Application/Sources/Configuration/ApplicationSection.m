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
                     @(ApplicationSectionNotifications) : NSLocalizedString(@"Notifications", @"Label to present Notifications"),
                     
                     @(ApplicationSectionFAQs) : NSLocalizedString(@"FAQs", @"Label to present FAQs"),
                     @(ApplicationSectionSupportForm) : NSLocalizedString(@"Contact support / Make a suggestion", @"Label to present support form"),
                     @(ApplicationSectionEvaluateApplication) : NSLocalizedString(@"Evaluate the application", @"Label to present the rate the application AppStore view"),
                     
                     @(ApplicationSectionSearch) : NSLocalizedString(@"Search", @"Label to present the search view"),
                     @(ApplicationSectionShowByDate) : NSLocalizedString(@"Shows by date", @"Label to present shows (episodes) by date (radio or TV)"),
                     @(ApplicationSectionOverview) : NSLocalizedString(@"Overview", @"Label to present the main Videos / Audios views"),
                     @(ApplicationSectionLive) : NSLocalizedString(@"Livestreams", @"Label to present the Livestreams view"),
                     @(ApplicationSectionShowAZ) : NSLocalizedString(@"Shows A to Z", @"Label to present shows A to Z (radio or TV)"),
                     @(ApplicationSectionWatchLater) : NSLocalizedString(@"Later", @"Label to present the later list") };
    });
    return s_names[@(applicationSection)];
}
