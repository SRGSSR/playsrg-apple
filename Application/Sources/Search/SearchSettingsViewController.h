//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "BaseViewController.h"

#import <SRGDataProvider/SRGDataProvider.h>
#import <XLForm/XLForm.h>

NS_ASSUME_NONNULL_BEGIN

@interface SearchSettingsViewController : XLFormViewController

- (instancetype)initWithSettings:(SRGMediaSearchSettings *)settings aggregations:(nullable SRGMediaAggregations *)aggregations;

@end

@interface SearchSettingsViewController (Unavailable)

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
