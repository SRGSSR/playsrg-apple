//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGDataProvider/SRGDataProvider.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, ImageScale) {
    ImageScaleSmall,
    ImageScaleMedium,
    ImageScaleLarge
};

typedef NS_ENUM(NSInteger, ImagePlaceholder) {
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
OBJC_EXPORT NSString *FilePathForImagePlaceholder(ImagePlaceholder imagePlaceholder);

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
 *  If set to `YES`, only original images available from the service will be used, otherwise some bad images might
 *  be fixed with local versions.
 *
 *  The default behavior is `NO`.
 */
+ (void)play_setUseOriginalImagesOnly:(BOOL)useOriginalImagesOnly;

/**
 *  Return an image generated from the vector image at the specified path.
 *
 *  @param filePath The path of the vector image to use.
 *  @param scale    The scale of the image to create.
 *
 *  @return The generated image, `nil` if generation failed.
 */
+ (nullable UIImage *)play_vectorImageAtPath:(NSString *)filePath withScale:(ImageScale)imageScale;

/**
 *  Return the file URL of an image generated from the vector image at the specified path.
 *
 *  @param filePath The path of the vector image to use.
 *  @param scale    The scale of the image to create.
 *
 *  @return The generated image, `nil` if generation failed.
 */
+ (nullable NSURL *)play_URLForVectorImageAtPath:(NSString *)filePath withScale:(ImageScale)imageScale;

@end

NS_ASSUME_NONNULL_END
