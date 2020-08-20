//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface UIStackView (PlaySRG)

/**
 *  Set the stack and all its arranged subviews as hidden or visible. The state of the views is not preserved for later
 *  restoration.
 *
 *  This avoids constraints breaking because a stack with item spacing is hidden within another stack (its width
 *  or height is then set to 0 and, if some items in it cannot be resized, margins will create constraint conflicts).
 *
 *  Also see http://stackoverflow.com/questions/33073127/nested-uistackviews-broken-constraints
 */
- (void)play_setHidden:(BOOL)hidden;

@end

NS_ASSUME_NONNULL_END
