//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Program guide layout.
 */
typedef NS_CLOSED_ENUM(NSInteger, ProgramGuideLayout) {
    ProgramGuideLayoutGrid,
    ProgramGuideLayoutList
};

/**
 *  Poster image setting.
 */
typedef NS_ENUM(NSInteger, SettingPosterImages) {
    /**
     *  Default (Firebase configuration).
     */
    SettingPosterImagesDefault,
    /**
     *  Forced poster images.
     */
    SettingPosterImagesForced,
    /**
     *  Ignored poster images.
     */
    SettingPosterImagesIgnored
};

OBJC_EXPORT ProgramGuideLayout ApplicationSettingProgramGuideRecentlyUsedLayout(void);
OBJC_EXPORT void ApplicationSettingSetProgramGuideRecentlyUsedLayout(ProgramGuideLayout layout);

OBJC_EXPORT BOOL ApplicationSettingSectionWideSupportEnabled(void);
OBJC_EXPORT SettingPosterImages ApplicationSettingPosterImages(void);

OBJC_EXPORT NSURL *ApplicationSettingServiceURL(void);
OBJC_EXPORT void ApplicationSettingSetServiceURL(NSURL * _Nullable serviceURL);

OBJC_EXPORT NSDictionary<NSString *, NSString *> * _Nullable ApplicationSettingGlobalParameters(void);

OBJC_EXPORT float ApplicationSettingLastSelectedPlaybackRate(void);
OBJC_EXPORT void ApplicationSettingSetLastSelectedPlaybackRate(float playbackRate);

OBJC_EXPORT NSString * _Nullable ApplicationSettingLastSelectedAudioLanguageCode(void);
OBJC_EXPORT void ApplicationSettingSetLastSelectedAudioLanguageCode(NSString * _Nullable languageCode);

NS_ASSUME_NONNULL_END
