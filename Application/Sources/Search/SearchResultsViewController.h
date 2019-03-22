//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ApplicationConfiguration.h"
#import "CollectionRequestViewController.h"

NS_ASSUME_NONNULL_BEGIN

@class SearchResultsViewController;

@protocol SearchResultsViewControllerDelegate <NSObject>

- (void)searchResultsViewControllerWasDragged:(SearchResultsViewController *)searchResultsViewController;

@end

@interface SearchResultsViewController : CollectionRequestViewController

- (instancetype)initWithSearchOption:(SearchOption)searchOption;

@property (nonatomic, weak, nullable) id<SearchResultsViewControllerDelegate> delegate;

- (void)updateWithSearchText:(NSString *)searchText;

@end

NS_ASSUME_NONNULL_END
