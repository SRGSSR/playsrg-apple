//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Protocol implemented by view controllers to respond to tab bar actions.
 */
API_UNAVAILABLE(tvos)
@protocol TabBarActionable <NSObject>

/**
 *  Called when the currently active tab has been tapped again.
 */
- (void)performActiveTabActionAnimated:(BOOL)animated;

@end

NS_ASSUME_NONNULL_END
