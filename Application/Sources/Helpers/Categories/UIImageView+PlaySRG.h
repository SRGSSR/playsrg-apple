//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UIImage+PlaySRG.h"

@import SRGDataProviderModel;

NS_ASSUME_NONNULL_BEGIN

@interface UIImageView (PlaySRG)

/**
 *  Standard loading indicators (animation already started).
 */
+ (UIImageView *)play_loadingImageViewWithTintColor:(nullable UIColor *)tintColor;
+ (UIImageView *)play_largeLoadingImageViewWithTintColor:(nullable UIColor *)tintColor;

/**
 *  Standard loading animations (must be managed with `-startAnimating` and `-stopAnimating`).
 */
- (void)play_setLargeLoadingAnimationWithTintColor:(nullable UIColor *)tintColor;

/**
 *  Standard download animations (must be managed with `-startAnimating` and `-stopAnimating`).
 */
- (void)play_setSmallDownloadAnimationWithTintColor:(nullable UIColor *)tintColor;
- (void)play_setDownloadAnimationWithTintColor:(nullable UIColor *)tintColor;
- (void)play_setLargeDownloadAnimationWithTintColor:(nullable UIColor *)tintColor;

/**
 *  Standard playback animations (must be managed with `-startAnimating` and `-stopAnimating`).
 */
- (void)play_setWaveformAnimationWithTintColor:(nullable UIColor *)tintColor;
- (void)play_setPlayAnimationWithTintColor:(nullable UIColor *)tintColor;

/**
 *  Request an image of the specified object. Use `SRGImageTypeDefault` for the default image.
 *
 *  @param object                The object for which the image must be requested.
 *  @param scale                 The image scale.
 *  @param type                  The image type.
 *  @param placeholder           The image placeholder.
 *  @param unavailabilityHandler An optional handler called when the image is invalid (no object was provided or its
 *                               associated image is invalid). You can implement this block to respond to such cases,
 *                               e.g. to retrieve another image. If the block is set, no image will be set, otherwise
 *                               the default placeholder will automatically be set.
 */
- (void)play_requestImageForObject:(nullable id<SRGImage>)object
                         withScale:(ImageScale)scale
                              type:(SRGImageType)type
                       placeholder:(ImagePlaceholder)placeholder
             unavailabilityHandler:(nullable void (^)(void))unavailabilityHandler;

/**
 *  Same as `-play_requestImageForObject:withScale:type:placeholder:unavailabilityHandler:`, with no unavailability handler (thus
 *  setting the default placeholder if no image is available).
 */
- (void)play_requestImageForObject:(nullable id<SRGImage>)object
                         withScale:(ImageScale)scale
                              type:(SRGImageType)type
                       placeholder:(ImagePlaceholder)placeholder;

/**
 *  Reset the image and cancel any pending image request.
 */
- (void)play_resetImage;

@end

NS_ASSUME_NONNULL_END
