//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import SRGDataProviderModel;
@import UIKit;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ImagePlaceholder) {
    ImagePlaceholderNone,
    ImagePlaceholderMedia,
    ImagePlaceholderMediaList,
    ImagePlaceholderNotification
};

/**
 *  Return the file path corresponding to an image placeholder.
 */
OBJC_EXPORT NSString * _Nullable FilePathForImagePlaceholder(ImagePlaceholder imagePlaceholder);

/**
 *  Youth protection image associated with a color, if any.
 */
OBJC_EXPORT UIImage * _Nullable YouthProtectionImageForColor(SRGYouthProtectionColor youthProtectionColor);

/**
 *  Return the standard image to be used for a given blocking reason.
 */
OBJC_EXPORT UIImage * _Nullable ImageForBlockingReason(SRGBlockingReason blockingReason);

NS_ASSUME_NONNULL_END
