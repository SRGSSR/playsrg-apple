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
 *  Return the kind of hardware the code is running on.
 */
@property (nonatomic, readonly, copy) NSString *play_hardware;


@end

NS_ASSUME_NONNULL_END
