//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Abstract common base view controller class for view controllers in the Play application. On iOS this class provides
 *  context menu management (long-press / 3D touch).
 */
@interface BaseViewController : UIViewController

/**
 *  Use this method to respond to content size category changes in subclasses.
 */
- (void)updateForContentSizeCategory NS_REQUIRES_SUPER;

@end

NS_ASSUME_NONNULL_END
