//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UIViewController+PlaySRG.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  Private category. For limited implementation purposes only, in (almost) all cases you should use `UIViewController+PlaySRG.h`
 *  instead.
 */
@interface UIViewController (PlaySRG_Private)

@property (nonatomic, nullable) id<UIViewControllerPreviewing> play_previewingContext;

@end

NS_ASSUME_NONNULL_END
