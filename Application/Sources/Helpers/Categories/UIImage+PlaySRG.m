//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UIImage+PlaySRG.h"

#import "ApplicationConfiguration.h"

#import <SRGAppearance/SRGAppearance.h>

CGSize SizeForImageScale(ImageScale imageScale)
{
    static NSDictionary *s_widths;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
            s_widths = @{ @(ImageScaleSmall) : @(200.f),
                          @(ImageScaleMedium) : @(340.f),
                          @(ImageScaleLarge) : @(400.f)};
        }
        else {
            s_widths = @{ @(ImageScaleSmall) : @(200.f),
                          @(ImageScaleMedium) : @(500.f),
                          @(ImageScaleLarge) : @(800.f)};
        }
    });
    
    // Use 2x maximum as scale. Sufficient for a good result without having to load very large images
    CGFloat width = [s_widths[@(imageScale)] floatValue] * fminf(UIScreen.mainScreen.scale, 2.f);
    return CGSizeMake(width, roundf(width * 9.f / 16.f));
}

NSString *FilePathForImagePlaceholder(ImagePlaceholder imagePlaceholder)
{
    switch (imagePlaceholder) {
        case ImagePlaceholderMedia: {
            return [NSBundle.mainBundle pathForResource:@"placeholder_media-180" ofType:@"pdf"];
            break;
        }
            
        case ImagePlaceholderMediaList: {
            return [NSBundle.mainBundle pathForResource:@"placeholder_media_list-180" ofType:@"pdf"];
            break;
        }
            
        case ImagePlaceholderNotification: {
            return [NSBundle.mainBundle pathForResource:@"placeholder_notification-180" ofType:@"pdf"];
            break;
        }
            
        default: {
            return nil;
            break;
        }
    }
}

UIImage *YouthProtectionImageForColor(SRGYouthProtectionColor youthProtectionColor)
{
    switch (youthProtectionColor) {
        case SRGYouthProtectionColorYellow: {
            return [UIImage imageNamed:@"youth_protection_yellow-18"];
            break;
        }
            
        case SRGYouthProtectionColorRed: {
            return [UIImage imageNamed:@"youth_protection_red-18"];
            break;
        }
            
        default: {
            return nil;
            break;
        }
    }
}

@implementation UIImage (PlaySRG)

+ (UIImage *)play_imageForBlockingReason:(SRGBlockingReason)blockingReason
{
    switch (blockingReason) {
        case SRGBlockingReasonGeoblocking: {
            return [UIImage imageNamed:@"geoblocked-25"];
            break;
        }
            
        case SRGBlockingReasonLegal: {
            return [UIImage imageNamed:@"legal-25"];
            break;
        }
            
        case SRGBlockingReasonAgeRating12:
        case SRGBlockingReasonAgeRating18: {
            return [UIImage imageNamed:@"age_rating-25"];
            break;
        }
            
        case SRGBlockingReasonStartDate:
        case SRGBlockingReasonEndDate:
        case SRGBlockingReasonNone: {
            return nil;
            break;
        }
            
        default: {
            return [UIImage imageNamed:@"generic_blocked-25"];
            break;
        }
    }
}

+ (UIImage *)play_vectorImageAtPath:(NSString *)filePath withScale:(ImageScale)imageScale
{
    return filePath ? [self srg_vectorImageAtPath:filePath withSize:SizeForImageScale(imageScale)] : nil;
}

@end
