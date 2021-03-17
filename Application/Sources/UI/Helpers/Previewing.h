//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Protocol to be used by views to setup context menu preview.
 */
@protocol Previewing <NSObject>

/**
 *  The preview object attached to the view.
 */
@property (nonatomic, readonly) id previewObject;

@end

@interface UIView (Previewing)

/**
 *  Register the receiver for previewing.
 */
- (void)play_registerForPreview;

@end

NS_ASSUME_NONNULL_END
