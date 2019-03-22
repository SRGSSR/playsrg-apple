//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>

/**
 *  Major types of devices we support slightly differently.
 */
typedef NS_ENUM(NSInteger, DeviceType) {
    DeviceTypePhonePlus = 1,                     // iPhone Plus devices
    DeviceTypePhoneOther,                        // Other iPhone devices
    DeviceTypePad                                // iPad devices
};

NS_ASSUME_NONNULL_BEGIN

@interface UIDevice (PlaySRG)

/**
 *  The type of the current device.
 */
@property (class, nonatomic, readonly) DeviceType play_deviceType;

@end

NS_ASSUME_NONNULL_END
