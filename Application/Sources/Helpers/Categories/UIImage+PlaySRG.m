//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UIImage+PlaySRG.h"

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
