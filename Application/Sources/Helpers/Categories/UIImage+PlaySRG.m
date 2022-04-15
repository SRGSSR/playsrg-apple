//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UIImage+PlaySRG.h"

#import "ApplicationConfiguration.h"

@import SRGAppearance;

static CGSize DefaultSizeForImageScale(ImageScale imageScale)
{
    static NSDictionary *s_widths;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
#if TARGET_OS_IOS
        if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
            s_widths = @{
                @(ImageScaleSmall) : @200.f,
                @(ImageScaleMedium) : @340.f,
                @(ImageScaleLarge) : @400.f
            };
        }
        else {
            s_widths = @{
                @(ImageScaleSmall) : @200.f,
                @(ImageScaleMedium) : @500.f,
                @(ImageScaleLarge) : @800.f
            };
        }
#else
        s_widths = @{
            @(ImageScaleSmall) : @350.f,
            @(ImageScaleMedium) : @800.f,
            @(ImageScaleLarge) : @1000.f
        };
#endif
    });
    
    // Use 2x maximum as scale. Sufficient for a good result without having to load very large images
    CGFloat width = [s_widths[@(imageScale)] floatValue] * fminf(UIScreen.mainScreen.scale, 2.f);
    return CGSizeMake(width, roundf(width * 3.f / 2.f));
}

static CGSize ShowPosterSizeForImageScale(ImageScale imageScale)
{
    static NSDictionary *s_widths;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
#if TARGET_OS_IOS
        s_widths = @{
            @(ImageScaleSmall) : @150.f,
            @(ImageScaleMedium) : @200.f,
            @(ImageScaleLarge) : @300.f
        };
#else
        s_widths = @{
            @(ImageScaleSmall) : @250.f,
            @(ImageScaleMedium) : @300.f,
            @(ImageScaleLarge) : @400.f
        };
#endif
    });
    
    // Use 2x maximum as scale. Sufficient for a good result without having to load very large images
    CGFloat width = [s_widths[@(imageScale)] floatValue] * fminf(UIScreen.mainScreen.scale, 2.f);
    return CGSizeMake(width, roundf(width * 9.f / 16.f));
}

CGSize SizeForImageScale(ImageScale imageScale, SRGImageType imageType)
{
    if ([imageType isEqualToString:SRGImageTypeShowPoster]) {
        return ShowPosterSizeForImageScale(imageScale);
    }
    else {
        return DefaultSizeForImageScale(imageScale);
    }
}

NSString *FilePathForImagePlaceholder(ImagePlaceholder imagePlaceholder)
{
    switch (imagePlaceholder) {
        case ImagePlaceholderMedia: {
            return [NSBundle.mainBundle pathForResource:@"placeholder_media" ofType:@"pdf"];
            break;
        }
            
        case ImagePlaceholderMediaList: {
            return [NSBundle.mainBundle pathForResource:@"placeholder_media_list" ofType:@"pdf"];
            break;
        }
            
        case ImagePlaceholderNotification: {
            return [NSBundle.mainBundle pathForResource:@"placeholder_notification" ofType:@"pdf"];
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
            return [UIImage imageNamed:@"youth_protection_yellow"];
            break;
        }
            
        case SRGYouthProtectionColorRed: {
            return [UIImage imageNamed:@"youth_protection_red"];
            break;
        }
            
        default: {
            return nil;
            break;
        }
    }
}

UIImage *ImageForBlockingReason(SRGBlockingReason blockingReason)
{
    switch (blockingReason) {
        case SRGBlockingReasonGeoblocking: {
            return [UIImage imageNamed:@"geoblocked"];
            break;
        }
            
        case SRGBlockingReasonLegal: {
            return [UIImage imageNamed:@"legal"];
            break;
        }
            
        case SRGBlockingReasonAgeRating12:
        case SRGBlockingReasonAgeRating18: {
            return [UIImage imageNamed:@"age_rating"];
            break;
        }
            
        case SRGBlockingReasonStartDate:
        case SRGBlockingReasonEndDate:
        case SRGBlockingReasonNone: {
            return nil;
            break;
        }
            
        default: {
            return [UIImage imageNamed:@"generic_blocked"];
            break;
        }
    }
}
