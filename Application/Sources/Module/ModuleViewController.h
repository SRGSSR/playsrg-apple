//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "MediasViewController.h"

#import <SRGDataProvider/SRGDataProvider.h>

NS_ASSUME_NONNULL_BEGIN

@interface ModuleViewController : MediasViewController <UIGestureRecognizerDelegate>

- (instancetype)initWithModule:(SRGModule *)module NS_DESIGNATED_INITIALIZER;

@end

@interface ModuleViewController (Unavailable)

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
