//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface PreviewingDelegate : NSObject <UIViewControllerPreviewingDelegate>

- (instancetype)initWithRealDelegate:(id<UIViewControllerPreviewingDelegate>)realDelegate;

@end

NS_ASSUME_NONNULL_END
