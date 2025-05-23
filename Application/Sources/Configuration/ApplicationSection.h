//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ApplicationSection) {
    ApplicationSectionUnknown = 0,
    
    ApplicationSectionSearch,
    ApplicationSectionFavorites,
    ApplicationSectionWatchLater,
    ApplicationSectionDownloads,
    ApplicationSectionHistory,
    ApplicationSectionNotifications,
    
    ApplicationSectionFAQs,
    ApplicationSectionSupportForm,
    ApplicationSectionEvaluateApplication,
    
    ApplicationSectionOverview,
    ApplicationSectionLive,
    ApplicationSectionShowByDate,
    ApplicationSectionShowAZ
};

OBJC_EXPORT NSString *TitleForApplicationSection(ApplicationSection applicationSection);

NS_ASSUME_NONNULL_END
