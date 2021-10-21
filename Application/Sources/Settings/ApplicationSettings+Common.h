//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Poster image setting.
 */
typedef NS_ENUM(NSInteger, SettingPosterImages) {
    /**
     *  Default (Firebase configuration).
     */
    SettingPosterImagesDefault,
    /**
     *  Force poster images.
     */
    SettingPosterImagesForced,
    /**
     *  Ignored poster images.
     */
    SettingPosterImagesIgnored
};

OBJC_EXPORT BOOL ApplicationSettingSectionWideSupportEnabled(void);
OBJC_EXPORT SettingPosterImages ApplicationSettingPosterImages(void);

NS_ASSUME_NONNULL_END
