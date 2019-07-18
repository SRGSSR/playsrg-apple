//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "RequestViewController.h"

#import <SRGDataProvider/SRGDataProvider.h>

NS_ASSUME_NONNULL_BEGIN

@class SearchSettingsViewController;

@protocol SearchSettingsViewControllerDelegate <NSObject>

/**
 *  Called when settings have been updated.
 */
- (void)searchSettingsViewController:(SearchSettingsViewController *)searchSettingsViewController didUpdateSettings:(nullable SRGMediaSearchSettings *)settings;

@end

@interface SearchSettingsViewController : RequestViewController <UITableViewDataSource, UITableViewDelegate>

/**
 *  Instantiate a setting screen with allowed values matching a given query and / or an existing setting set.
 */
- (instancetype)initWithQuery:(nullable NSString *)query settings:(nullable SRGMediaSearchSettings *)settings;

/**
 *  The delegate.
 */
@property (nonatomic, weak) id<SearchSettingsViewControllerDelegate> delegate;

@end

@interface SearchSettingsViewController (Unavailable)

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
