//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "PageViewController.h"
#import "RadioChannel.h"

#import <SRGAnalytics/SRGAnalytics.h>

NS_ASSUME_NONNULL_BEGIN

@interface RadioShowsViewController : PageViewController <SRGAnalyticsViewTracking>

- (instancetype)initWithRadioChannels:(NSArray<RadioChannel *> *)radioChannels alphabeticalIndex:(nullable NSString *)alphabeticalIndex;

@end

@interface RadioShowsViewController (Unavailable)

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
