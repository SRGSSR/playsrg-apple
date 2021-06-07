//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UIColor+PlaySRG.h"

@import SRGAppearance;

@implementation UIColor (PlaySRG)

+ (UIColor *)play_notificationRedColor
{
    return [UIColor srg_colorFromHexadecimalString:@"#ed3323"];
}

+ (UIColor *)play_greenColor
{
    return [UIColor srg_colorFromHexadecimalString:@"#347368"];
}

+ (UIColor *)play_orangeColor
{
    return [UIColor srg_colorFromHexadecimalString:@"#df5200"];
}

+ (UIColor *)play_popoverGrayBackgroundColor
{
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        return [UIColor srg_colorFromHexadecimalString:@"#2d2d2d"];
    }
    else {
        return [UIColor srg_colorFromHexadecimalString:@"#1a1a1a"];
    }
}

+ (UIColor *)play_grayThumbnailImageViewBackgroundColor
{
    return [UIColor srg_colorFromHexadecimalString:@"#202020"];
}

+ (UIColor *)play_blackDurationLabelBackgroundColor
{
    return [UIColor colorWithWhite:0.f alpha:0.5f];
}

@end
