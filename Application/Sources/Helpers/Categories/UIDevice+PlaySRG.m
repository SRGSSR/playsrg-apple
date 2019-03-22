//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UIDevice+PlaySRG.h"

@implementation UIDevice (PlaySRG)

#pragma mark Class methods

+ (DeviceType)play_deviceType
{
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone) {
        CGRect screenBounds = UIScreen.mainScreen.bounds;
        CGFloat screenLength = fmaxf(CGRectGetWidth(screenBounds), CGRectGetHeight(screenBounds));
        if (screenLength == 736.f) {
            return DeviceTypePhonePlus;
        }
        else {
            return DeviceTypePhoneOther;
        }
    }
    else {
        return DeviceTypePad;
    }
}

@end
