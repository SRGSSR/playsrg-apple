//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "PageContainerViewController.h"

@import SRGDataProviderModel;

NS_ASSUME_NONNULL_BEGIN

@interface HomeTopicViewController : PageContainerViewController

- (instancetype)initWithTopic:(SRGTopic *)topic;

@end

@interface HomeTopicViewController (Unavailable)

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
