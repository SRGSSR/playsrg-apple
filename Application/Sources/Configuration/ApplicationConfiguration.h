//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "HomeSection.h"
#import "RadioChannel.h"
#import "TVChannel.h"

@import CoreMedia;
@import Foundation;
@import SRGAnalytics;
@import SRGDataProvider;
@import SRGLetterbox;

NS_ASSUME_NONNULL_BEGIN

OBJC_EXPORT void ApplicationConfigurationApplyControllerSettings(SRGLetterboxController *controller);
OBJC_EXPORT NSTimeInterval ApplicationConfigurationEffectiveEndTolerance(NSTimeInterval duration);

OBJC_EXPORT NSString * const ApplicationConfigurationDidChangeNotification;

@interface ApplicationConfiguration : NSObject

@property (class, nonatomic, readonly) ApplicationConfiguration *sharedApplicationConfiguration;

@property (nonatomic, readonly) SRGVendor vendor;

@property (nonatomic, readonly, copy) SRGAnalyticsBusinessUnitIdentifier analyticsBusinessUnitIdentifier;
@property (nonatomic, readonly) NSInteger analyticsContainer;

@property (nonatomic, readonly, copy) NSString *siteName;
@property (nonatomic, readonly, copy) NSString *tvSiteName;

// Might be nil for "exotic" languages like Rumantsch
@property (nonatomic, readonly, copy, nullable) NSString *voiceOverLanguageCode;

@property (nonatomic, readonly, copy) NSNumber *appStoreProductIdentifier;

@property (nonatomic, readonly) NSURL *playURL;
@property (nonatomic, readonly) NSURL *middlewareURL;
@property (nonatomic, readonly, nullable) NSURL *identityWebserviceURL;
@property (nonatomic, readonly, nullable) NSURL *identityWebsiteURL;
@property (nonatomic, readonly, nullable) NSURL *userDataServiceURL;

@property (nonatomic, readonly) NSURL *whatsNewURL;
@property (nonatomic, readonly, nullable) NSURL *feedbackURL;
@property (nonatomic, readonly, nullable) NSURL *impressumURL;
@property (nonatomic, readonly, nullable) NSURL *termsAndConditionsURL;
@property (nonatomic, readonly, nullable) NSURL *dataProtectionURL;
@property (nonatomic, readonly, nullable) NSURL *betaTestingURL;
@property (nonatomic, readonly, nullable) NSURL *sourceCodeURL;

@property (nonatomic, readonly, getter=areDownloadsHintsHidden) BOOL downloadsHintsHidden;
@property (nonatomic, readonly, getter=areShowsUnavailable) BOOL showsUnavailable;
@property (nonatomic, readonly, getter=isSubtitleAvailabilityHidden) BOOL subtitleAvailabilityHidden;
@property (nonatomic, readonly, getter=isAudioDescriptionAvailabilityHidden) BOOL audioDescriptionAvailabilityHidden;

@property (nonatomic, readonly) NSArray<NSNumber *> *liveHomeSections;                  // wrap `HomeSection` values

@property (nonatomic, readonly) NSInteger minimumSocialViewCount;                       // minimum value to display social view count

@property (nonatomic, readonly) NSArray<RadioChannel *> *radioChannels;
@property (nonatomic, readonly) NSArray<TVChannel *> *tvChannels;
@property (nonatomic, readonly) NSArray<RadioChannel *> *satelliteRadioChannels;

@property (nonatomic, readonly) NSUInteger pageSize;                                    // page size to be used in general throughout the app
@property (nonatomic, readonly) NSUInteger detailPageSize;                              // page size to be used in general throughout the app

@property (nonatomic, readonly, getter=isContinuousPlaybackAvailable) BOOL continuousPlaybackAvailable;

@property (nonatomic, readonly) NSTimeInterval continuousPlaybackPlayerViewTransitionDuration;      // If the remote config is empty, returns `SRGLetterboxContinuousPlaybackDisabled`
@property (nonatomic, readonly) NSTimeInterval continuousPlaybackForegroundTransitionDuration;      // If the remote config is empty, returns `SRGLetterboxContinuousPlaybackDisabled`
@property (nonatomic, readonly) NSTimeInterval continuousPlaybackBackgroundTransitionDuration;      // If the remote config is empty, returns `SRGLetterboxContinuousPlaybackDisabled`

@property (nonatomic, readonly) NSTimeInterval endTolerance;
@property (nonatomic, readonly) float endToleranceRatio;

@property (nonatomic, readonly) NSArray<NSString *> *hiddenOnboardingUids;

@property (nonatomic, readonly, getter=areSearchSettingsHidden) BOOL searchSettingsHidden;
@property (nonatomic, readonly, getter=isSearchSettingSubtitledHidden) BOOL searchSettingSubtitledHidden;
@property (nonatomic, readonly, getter=isSearchSortingCriteriumHidden) BOOL searchSortingCriteriumHidden;
@property (nonatomic, readonly, getter=isShowsSearchHidden) BOOL showsSearchHidden;

- (nullable RadioChannel *)radioChannelForUid:(nullable NSString *)uid;
- (nullable TVChannel *)tvChannelForUid:(nullable NSString *)uid;
- (nullable __kindof Channel *)channelForUid:(nullable NSString *)uid;

/**
 *  URLs to be used for sharing
 */
- (nullable NSURL *)sharingURLForMedia:(nullable SRGMedia *)media atTime:(CMTime)time; // Use kCMTimeZero to start at the default location.
- (nullable NSURL *)sharingURLForShow:(nullable SRGShow *)show;
- (nullable NSURL *)sharingURLForContentSection:(nullable SRGContentSection *)contentSection;

#if defined(DEBUG) || defined(NIGHTLY) || defined(BETA)

/**
 *  An optionnal override play URL for test and stage environnements. Use `playURL` property to get the current URL.
 */
- (void)setOverridePlayURL:(nullable NSURL *)overridePlayURL;

#endif

@end

NS_ASSUME_NONNULL_END
