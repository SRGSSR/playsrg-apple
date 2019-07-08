//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "DataViewController.h"

#import <SRGDataProvider/SRGDataProvider.h>

NS_ASSUME_NONNULL_BEGIN

@protocol SearchSettingsMultiSelectionItem <NSObject>

@property (nonatomic, readonly, copy) NSString *name;
@property (nonatomic, readonly) NSUInteger count;
@property (nonatomic, readonly, copy) NSString *value;

@end

@class SearchSettingMultiSelectionViewController;

@protocol SearchSettingsMultiSelectionViewControllerDelegate <NSObject>

- (void)searchSettingsViewController:(SearchSettingMultiSelectionViewController *)searchSettingsViewController didUpdateSelectedItems:(nullable NSArray<NSString *> *)selectedItems forItemClass:(Class)itemClass;

@end

@interface SearchSettingMultiSelectionViewController : DataViewController <UITableViewDataSource, UITableViewDelegate>

- (instancetype)initWithTitle:(NSString *)title items:(NSArray<id <SearchSettingsMultiSelectionItem>> *)items selectedValues:(nullable NSArray<NSString *> *)selectedvalues;

@property (nonatomic, weak) id<SearchSettingsMultiSelectionViewControllerDelegate> delegate;

@end

@interface SearchSettingMultiSelectionViewController (Unavailable)

- (instancetype)init NS_UNAVAILABLE;

@end

@interface SRGTopicBucket (SearchSettingsMultiSelection) <SearchSettingsMultiSelectionItem>

@end

@interface SRGShowBucket (SearchSettingsMultiSelection) <SearchSettingsMultiSelectionItem>

@end

NS_ASSUME_NONNULL_END
