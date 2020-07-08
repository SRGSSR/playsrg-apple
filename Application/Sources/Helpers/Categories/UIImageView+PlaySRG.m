//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UIImageView+PlaySRG.h"

#import "NSBundle+PlaySRG.h"
#import "PlayErrors.h"
#import "UIImage+PlaySRG.h"

#import <CoconutKit/CoconutKit.h>
#import <SRGAppearance/SRGAppearance.h>
#import <YYWebImage/YYWebImage.h>

static void (*s_willMoveToWindow)(id, SEL, id) = NULL;

static void swizzled_willMoveToWindow(UIImageView *self, SEL _cmd, UIWindow *window);

@implementation UIImageView (PlaySRG)

#pragma mark Class methods

+ (void)load
{
    HLSSwizzleSelector(self, @selector(willMoveToWindow:), swizzled_willMoveToWindow, &s_willMoveToWindow);
}

+ (UIImageView *)play_loadingImageView48WithTintColor:(UIColor *)tintColor
{
    return [self play_animatedImageViewNamed:@"loading-48" withTintColor:tintColor duration:1.];
}

+ (UIImageView *)play_loadingImageView90WithTintColor:(UIColor *)tintColor
{
    return [self play_animatedImageViewNamed:@"loading-90" withTintColor:tintColor duration:1.];
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

- (void)play_setLoadingAnimation90WithTintColor:(UIColor *)tintColor
{
    [self play_setAnimationImagesNamed:@"loading-90" withTintColor:tintColor duration:1.];
}

#pragma mark Downloading animations

- (void)play_setDownloadAnimation16WithTintColor:(UIColor *)tintColor
{
    [self play_setAnimationImagesNamed:@"downloading-16" withTintColor:tintColor duration:1.];
}

- (void)play_setDownloadAnimation22WithTintColor:(UIColor *)tintColor
{
    [self play_setAnimationImagesNamed:@"downloading-22" withTintColor:tintColor duration:1.];
}

- (void)play_setDownloadAnimation48WithTintColor:(UIColor *)tintColor
{
    [self play_setAnimationImagesNamed:@"downloading-48" withTintColor:tintColor duration:1.];
}

#pragma mark Waveform animation

- (void)play_setWaveformAnimation34WithTintColor:(UIColor *)tintColor
{
    [self play_setAnimationImagesNamed:@"waveform-34" withTintColor:tintColor duration:0.96];
}

- (void)play_setPlayAnimation34WithTintColor:(UIColor *)tintColor
{
    [self play_setAnimationImagesNamed:@"play-34" withTintColor:tintColor duration:1.52];
}

#pragma mark Animation lifecycle

- (void)play_setAnimationImagesNamed:(NSString *)name withTintColor:(UIColor *)tintColor duration:(NSTimeInterval)duration
{
    self.animationImages = [UIImageView animatedImageNamed:name withTintColor:tintColor];
    self.image = self.animationImages.firstObject;
    self.animationDuration = duration;
}

#pragma mark Standard image loading

- (void)play_requestImageForObject:(id<SRGImage>)object
                         withScale:(ImageScale)scale
                              type:(SRGImageType)type
                       placeholder:(ImagePlaceholder)placeholder
             unavailabilityHandler:(void (^)(void))unavailabilityHandler
{
    NSString *filePath = FilePathForImagePlaceholder(placeholder);
    CGSize size = SizeForImageScale(scale);
    UIImage *placeholderImage = filePath ? [UIImage srg_vectorImageAtPath:filePath withSize:size] : nil;
    
    void (^handleUnavailableURL)(void) = ^{
        if (unavailabilityHandler) {
            unavailabilityHandler();
        }
        else {
            [self yy_setImageWithURL:nil placeholder:placeholderImage];
        }
    };
    
    if (! object) {
        handleUnavailableURL();
        return;
    }
    
    NSURL *URL = [object imageURLForDimension:SRGImageDimensionWidth withValue:size.width type:type];
    
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

- (void)play_requestImageForObject:(id<SRGImage>)object
                         withScale:(ImageScale)imageScale
                              type:(SRGImageType)type
                       placeholder:(ImagePlaceholder)placeholder

{
    [self play_requestImageForObject:object withScale:imageScale type:type placeholder:placeholder unavailabilityHandler:nil];
}

- (void)play_resetImage
{
    [self yy_setImageWithURL:nil options:0];
}

@end

static void swizzled_willMoveToWindow(UIImageView *self, SEL _cmd, UIWindow *window)
{
    // Workaround UIImage view tint color bug in cells. See http://stackoverflow.com/a/26042893/760435
    UIImage *image = self.image;
    self.image = nil;
    self.image = image;
}
