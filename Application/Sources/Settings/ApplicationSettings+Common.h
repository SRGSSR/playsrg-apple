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

/**
 *  Squared image setting.
 */
typedef NS_ENUM(NSInteger, SettingSquareImages) {
    /**
     *  Default (Firebase configuration).
     */
    SettingSquareImagesDefault,
    /**
     *  Forced square images.
     */
    SettingSquareImagesForced,
    /**
     *  Ignored square images.
     */
    SettingSquareImagesIgnored
};

/**
 *  Audio content home page setting.
 */
typedef NS_ENUM(NSInteger, SettingAudioContentHomePage) {
    /**
     *  Default (Firebase configuration).
     */
    SettingAudioContentHomePageDefault,
    /**
     *  Force audio content home page usage.
     */
    SettingAudioContentHomePageForced,
    /**
     *  Ignore audio content home page usage.
     */
    SettingAudioContentHomePageIgnored
};

OBJC_EXPORT ProgramGuideLayout ApplicationSettingProgramGuideRecentlyUsedLayout(BOOL isCompactHorizontalSizeClass);
OBJC_EXPORT void ApplicationSettingSetProgramGuideRecentlyUsedLayout(ProgramGuideLayout layout);

OBJC_EXPORT BOOL ApplicationSettingSectionWideSupportEnabled(void);
OBJC_EXPORT SettingPosterImages ApplicationSettingPosterImages(void);
OBJC_EXPORT SettingSquareImages ApplicationSettingSquareImages(void);
OBJC_EXPORT SettingAudioContentHomePage ApplicationSettingAudioContentHomePage(void);

OBJC_EXPORT NSDictionary<NSString *, NSString *> * _Nullable ApplicationSettingGlobalParameters(void);

OBJC_EXPORT NSString * _Nullable ApplicationSettingLastSelectedAudioLanguageCode(void);
OBJC_EXPORT void ApplicationSettingSetLastSelectedAudioLanguageCode(NSString * _Nullable languageCode);

OBJC_EXPORT NSString *ApplicationSettingServiceIdentifier(void);
OBJC_EXPORT void ApplicationSettingSetServiceIdentifier(NSString * _Nullable identifier);

OBJC_EXPORT NSURL *ApplicationSettingServiceURL(void);

OBJC_EXPORT BOOL ApplicationSettingAutoplayEnabled(void);

OBJC_EXPORT BOOL ApplicationSettingDiscoverySubtitleOptionLanguageRunOnce(void);
OBJC_EXPORT void ApplicationSettingSetDiscoverySubtitleOptionLanguageRunOnce(BOOL discoverySubtitleOptionLanguageRunOnce);

NS_ASSUME_NONNULL_END
