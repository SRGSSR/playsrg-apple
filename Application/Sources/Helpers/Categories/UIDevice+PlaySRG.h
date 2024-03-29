//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface UIDevice (PlaySRG)

/**
 *  Return YES when the device is locked.
 */
@property (class, nonatomic, readonly) BOOL play_isLocked;

/**
 *  Rotate the device to the specified interface orientation.
 */
- (void)rotateToUserInterfaceOrientation:(UIInterfaceOrientation)orientation;

@end

NS_ASSUME_NONNULL_END
