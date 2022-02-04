//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "RadioChannel.h"

@import SRGLetterbox;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Tab bar item identifier.
 */
typedef NS_ENUM(NSInteger, TabBarItemIdentifier) {
    TabBarItemIdentifierNone,
    TabBarItemIdentifierVideos = TabBarItemIdentifierNone,
    TabBarItemIdentifierAudios,
    TabBarItemIdentifierLivestreams,
    TabBarItemIdentifierSearch,
    TabBarItemIdentifierProfile
};

/**
 *  Program guide layout.
 */
typedef NS_CLOSED_ENUM(NSInteger, ProgramGuideLayout) {
    ProgramGuideLayoutGrid,
    ProgramGuideLayoutList
};

OBJC_EXPORT BOOL ApplicationSettingAlternateRadioHomepageDesignEnabled(void);
OBJC_EXPORT BOOL ApplicationSettingPresenterModeEnabled(void);

OBJC_EXPORT BOOL ApplicationSettingStandaloneEnabled(void);
OBJC_EXPORT SRGQuality ApplicationSettingPreferredQuality(void);
OBJC_EXPORT SRGLetterboxPlaybackSettings *ApplicationSettingPlaybackSettings(void);

OBJC_EXPORT NSTimeInterval ApplicationSettingContinuousPlaybackTransitionDuration(void);

OBJC_EXPORT BOOL ApplicationSettingBackgroundVideoPlaybackEnabled(void);

OBJC_EXPORT BOOL ApplicationSettingSubtitleAvailabilityDisplayed(void);
OBJC_EXPORT BOOL ApplicationSettingAudioDescriptionAvailabilityDisplayed(void);

OBJC_EXPORT NSString * _Nullable ApplicationSettingSelectedLivestreamURNForChannelUid(NSString * _Nullable channelUid);
OBJC_EXPORT void ApplicationSettingSetSelectedLivestreamURNForChannelUid(NSString * channelUid, NSString * _Nullable mediaURN);

OBJC_EXPORT SRGMedia * _Nullable ApplicationSettingSelectedLivestreamMediaForChannelUid(NSString * _Nullable channelUid, NSArray<SRGMedia *> * _Nullable medias);

OBJC_EXPORT TabBarItemIdentifier ApplicationSettingLastOpenedTabBarItemIdentifier(void);
OBJC_EXPORT void ApplicationSettingSetLastOpenedTabBarItemIdentifier(TabBarItemIdentifier tabBarItemIdentifier);

OBJC_EXPORT RadioChannel * _Nullable ApplicationSettingLastOpenedRadioChannel(void);
OBJC_EXPORT void ApplicationSettingSetLastOpenedRadioChannel(RadioChannel * radioChannel);

OBJC_EXPORT NSURL * _Nullable ApplicationSettingServiceURLForKey(NSString *key);
OBJC_EXPORT NSString * _Nullable ApplicationSettingServiceNameForKey(NSString *key);

OBJC_EXPORT BOOL ApplicationSettingBackgroundVideoPlaybackEnabled(void);

OBJC_EXPORT ProgramGuideLayout ApplicationSettingProgramGuideRecentlyUsedLayout(void);
OBJC_EXPORT void ApplicationSettingSetProgramGuideRecentlyUsedLayout(ProgramGuideLayout layout);

NS_ASSUME_NONNULL_END
