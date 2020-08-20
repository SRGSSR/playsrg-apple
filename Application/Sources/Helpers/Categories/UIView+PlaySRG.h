//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import CoreMedia;
@import SRGLetterbox;
@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface UIView (PlaySRG)

/**
 *  Return `YES` iff the receiver is actually hidden from view, i.e. is itself hidden or hidden because one of its parents
 *  is.
 */
@property (nonatomic, readonly, getter=play_isActuallyHidden) BOOL play_actuallyHidden;

/**
 * Return the nearest view controller which displays the view, nil if none
 */
@property (nonatomic, readonly, weak, nullable) __kindof UIViewController *play_nearestViewController;

@end

NS_ASSUME_NONNULL_END
