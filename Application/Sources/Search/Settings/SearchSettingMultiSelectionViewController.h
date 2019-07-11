//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "DataViewController.h"
#import "SearchSettingsMultiSelectionItem.h"

NS_ASSUME_NONNULL_BEGIN

@class SearchSettingMultiSelectionViewController;

@protocol SearchSettingsMultiSelectionViewControllerDelegate <NSObject>

- (void)searchSettingMultiSelectionViewController:(SearchSettingMultiSelectionViewController *)searchSettingMultiSelectionViewController didUpdateSelectedValues:(nullable NSArray<NSString *> *)selectedValues;

@end

@interface SearchSettingMultiSelectionViewController : DataViewController <UITableViewDataSource, UITableViewDelegate>

- (instancetype)initWithTitle:(NSString *)title identifier:(NSString *)identifier items:(NSArray<SearchSettingsMultiSelectionItem *> *)items selectedValues:(nullable NSArray<NSString *> *)selectedvalues;

@property (nonatomic, readonly, copy) NSString *identifier;

@property (nonatomic, weak) id<SearchSettingsMultiSelectionViewControllerDelegate> delegate;

@end

@interface SearchSettingMultiSelectionViewController (Unavailable)

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
