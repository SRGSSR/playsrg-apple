//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import SRGDataProvider;
@import UIKit;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ImageScale) {
    ImageScaleSmall,
    ImageScaleMedium,
    ImageScaleLarge
};

typedef NS_ENUM(NSInteger, ImagePlaceholder) {
    ImagePlaceholderNone,
    ImagePlaceholderMedia,
    ImagePlaceholderMediaList,
    ImagePlaceholderNotification
};

/**
 *  Return the size corresponding to a given scale. Takes into account the device screen scale.
 */
OBJC_EXPORT CGSize SizeForImageScale(ImageScale imageScale);

/**
 *  Return the file path corresponding to an image placeholder.
 */
OBJC_EXPORT NSString * _Nullable FilePathForImagePlaceholder(ImagePlaceholder imagePlaceholder);

/**
 *  Youth protection image associated with a color, if any.
 */
OBJC_EXPORT UIImage * _Nullable YouthProtectionImageForColor(SRGYouthProtectionColor youthProtectionColor);

@interface UIImage (PlaySRG)

/**
 *  Return the standard image to be used for a given blocking reason.
 */
+ (nullable UIImage *)play_imageForBlockingReason:(SRGBlockingReason)blockingReason;

/**
 *  Return an image generated from the vector image at the specified path.
 *
 *  @param filePath The path of the vector image to use.
 *  @param scale    The scale of the image to create.
 *
 *  @return The generated image, `nil` if generation failed or if the path is `nil`.
 */
+ (nullable UIImage *)play_vectorImageAtPath:(nullable NSString *)filePath withScale:(ImageScale)imageScale;

@end

NS_ASSUME_NONNULL_END
