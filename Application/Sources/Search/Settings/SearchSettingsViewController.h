//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "RequestViewController.h"

@import SRGAnalytics;
@import SRGDataProvider;

NS_ASSUME_NONNULL_BEGIN

@class SearchSettingsViewController;

@protocol SearchSettingsViewControllerDelegate <NSObject>

/**
 *  Called when settings have been updated.
 */
- (void)searchSettingsViewController:(SearchSettingsViewController *)searchSettingsViewController didUpdateSettings:(SRGMediaSearchSettings *)settings;

@end

@interface SearchSettingsViewController : RequestViewController <SRGAnalyticsViewTracking, UITableViewDataSource, UITableViewDelegate>

/**
 *  The default settings (including aggregations). Returns a fresh instance with every call.
 */
@property (class, nonatomic, readonly) SRGMediaSearchSettings *defaultSettings;

/**
 *  Instantiate a setting screen with allowed values matching a given query and / or an existing setting set.
 */
- (instancetype)initWithQuery:(nullable NSString *)query settings:(SRGMediaSearchSettings *)settings;

/**
 *  The delegate.
 */
@property (nonatomic, weak) id<SearchSettingsViewControllerDelegate> delegate;

@end

@interface SearchSettingsViewController (Unavailable)

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
