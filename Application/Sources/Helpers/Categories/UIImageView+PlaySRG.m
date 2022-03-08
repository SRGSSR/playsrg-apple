//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UIImageView+PlaySRG.h"

#import "NSBundle+PlaySRG.h"
#import "PlayErrors.h"
#import "UIImage+PlaySRG.h"

#import <objc/runtime.h>

@import SRGAppearance;
@import SRGDataProviderNetwork;
@import YYWebImage;

@implementation UIImageView (PlaySRG)

#pragma mark Class methods

+ (UIImageView *)play_loadingImageViewWithTintColor:(UIColor *)tintColor
{
    return [self play_animatedImageViewNamed:@"loading_animation" withTintColor:tintColor duration:1.];
}

+ (UIImageView *)play_largeLoadingImageViewWithTintColor:(UIColor *)tintColor
{
    return [self play_animatedImageViewNamed:@"loading_animation-large" withTintColor:tintColor duration:1.];
}

+ (UIImageView *)play_smallDownloadingImageViewWithTintColor:(UIColor *)tintColor;
{
    return [self play_animatedImageViewNamed:@"downloading_animation-small" withTintColor:tintColor duration:1.];
}

+ (UIImageView *)play_downloadingImageViewWithTintColor:(UIColor *)tintColor
{
    return [self play_animatedImageViewNamed:@"downloading_animation-small" withTintColor:tintColor duration:1.];
}

+ (UIImageView *)play_largeDownloadingImageViewWithTintColor:(UIColor *)tintColor
{
    return [self play_animatedImageViewNamed:@"downloading_animation-large" withTintColor:tintColor duration:1.];
}

// Expect a sequence of images named "name-N", where N must begin at 0. Stops when no image is found for some N
+ (UIImageView *)play_animatedImageViewNamed:(NSString *)name withTintColor:(UIColor *)tintColor duration:(NSTimeInterval)duration
{
    NSArray<UIImage *> *images = [self animatedImageNamed:name withTintColor:tintColor];
    UIImageView *imageView = [[UIImageView alloc] initWithImage:images.firstObject];
    imageView.animationImages = images.copy;
    imageView.animationDuration = duration;
    [imageView startAnimating];
    return imageView;
}

+ (NSArray<UIImage *> *)animatedImageNamed:(NSString *)name withTintColor:(UIColor *)tintColor
{
    NSMutableArray<UIImage *> *images = [NSMutableArray array];
    
    NSInteger count = 0;
    while (1) {
        NSString *imageName = [NSString stringWithFormat:@"%@-%@", name, @(count)];
        UIImage *image = [[UIImage imageNamed:imageName] srg_imageTintedWithColor:tintColor];
        if (! image) {
            break;
        }
        [images addObject:image];
        
        ++count;
    }
    
    NSAssert(images.count != 0, @"Invalid asset %@", name);
    return images.copy;
}

#pragma mark Loading animations

- (void)play_setLargeLoadingAnimationWithTintColor:(UIColor *)tintColor
{
    [self play_setAnimationImagesNamed:@"loading_animation-large" withTintColor:tintColor duration:1.];
}

#pragma mark Downloading animations

- (void)play_setSmallDownloadAnimationWithTintColor:(UIColor *)tintColor
{
    [self play_setAnimationImagesNamed:@"downloading_animation-small" withTintColor:tintColor duration:1.];
}

- (void)play_setDownloadAnimationWithTintColor:(UIColor *)tintColor
{
    [self play_setAnimationImagesNamed:@"downloading_animation" withTintColor:tintColor duration:1.];
}

- (void)play_setLargeDownloadAnimationWithTintColor:(UIColor *)tintColor
{
    [self play_setAnimationImagesNamed:@"downloading_animation-large" withTintColor:tintColor duration:1.];
}

#pragma mark Waveform animation

- (void)play_setWaveformAnimationWithTintColor:(UIColor *)tintColor
{
    [self play_setAnimationImagesNamed:@"waveform_animation" withTintColor:tintColor duration:0.96];
}

- (void)play_setPlayAnimationWithTintColor:(UIColor *)tintColor
{
    [self play_setAnimationImagesNamed:@"play_animation" withTintColor:tintColor duration:1.52];
}

#pragma mark Animation lifecycle

- (void)play_setAnimationImagesNamed:(NSString *)name withTintColor:(UIColor *)tintColor duration:(NSTimeInterval)duration
{
    self.animationImages = [UIImageView animatedImageNamed:name withTintColor:tintColor];
    self.image = self.animationImages.firstObject;
    self.animationDuration = duration;
}

#pragma mark Standard image loading

- (void)play_requestImage:(SRGImage *)image
                 withSize:(SRGImageSize)size
              placeholder:(ImagePlaceholder)placeholder
    unavailabilityHandler:(void (^)(void))unavailabilityHandler
{
    NSString *filePath = FilePathForImagePlaceholder(placeholder);
    CGSize recommendedSize = SRGRecommendedImageCGSize(size, image.variant);
    UIImage *placeholderImage = filePath ? [UIImage srg_vectorImageAtPath:filePath withSize:recommendedSize] : nil;
    
    void (^handleUnavailableURL)(void) = ^{
        if (unavailabilityHandler) {
            unavailabilityHandler();
        }
        else {
            [self yy_setImageWithURL:nil placeholder:placeholderImage];
        }
    };
    
    if (! image) {
        handleUnavailableURL();
        return;
    }
    
    NSURL *URL = [SRGDataProvider.currentDataProvider URLForImage:image withSize:size scaling:SRGImageScalingDefault];
    
    // Fix for invalid images, incorrect Kids program images, and incorrect images for sports (RTS)
    // See https://srfmmz.atlassian.net/browse/AIS-15672
    if (! URL || [URL.absoluteString containsString:@"NOT_SPECIFIED.jpg"] || [URL.absoluteString containsString:@"rts.ch/video/jeunesse"]
            || [URL.absoluteString containsString:@".html"]) {
        handleUnavailableURL();
        return;
    }
    
    if (! [URL isEqual:self.yy_imageURL]) {
        // If an image is already displayed, use it as placeholder. This make the transition smooth between both images.
        // Using the placeholder would add an unnecessary intermediate state leading to flickering
        if (self.image) {
            [self yy_setImageWithURL:URL placeholder:self.image options:YYWebImageOptionSetImageWithFadeAnimation completion:nil];
        }
        // If no image is already displayed, check if the image we want to display is already available from the cache.
        // If this is the case, use it as placeholder, avoiding an intermediate step which would lead to flickering
        else {
            YYWebImageManager *webImageManager = YYWebImageManager.sharedManager;
            NSString *key = [webImageManager cacheKeyForURL:URL];
            UIImage *image = [webImageManager.cache getImageForKey:key];
            if (image) {
                // Use the YYWebImage setter so that the URL is properly associated with the image view
                [self yy_setImageWithURL:URL placeholder:image options:YYWebImageOptionSetImageWithFadeAnimation completion:nil];
            }
            else {
                [self yy_setImageWithURL:URL placeholder:placeholderImage options:YYWebImageOptionSetImageWithFadeAnimation completion:nil];
            }
        }
    }
}

- (void)play_requestImage:(SRGImage *)image
                 withSize:(SRGImageSize)size
              placeholder:(ImagePlaceholder)placeholder;

{
    [self play_requestImage:image withSize:size placeholder:placeholder unavailabilityHandler:nil];
}

- (void)play_resetImage
{
    [self yy_setImageWithURL:nil options:0];
}

- (void)play_fixImageTintColor
{
    // Workaround UIImage view tint color bug in cells. See http://stackoverflow.com/a/26042893/760435
    UIImage *image = self.image;
    self.image = nil;
    self.image = image;
}

- (void)UIImageView_PlaySRG_swizzled_willMoveToWindow:(UIWindow *)window
{
    [self UIImageView_PlaySRG_injected_willMoveToWindow:window];
    
    [self play_fixImageTintColor];
}

- (void)UIImageView_PlaySRG_injected_willMoveToWindow:(UIWindow *)window
{
    [super willMoveToWindow:window];
    
    [self play_fixImageTintColor];
}

@end
