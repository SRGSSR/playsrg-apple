//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ContentInsets.h"
#import "ListRequestViewController.h"
#import "TabBarActionable.h"

@import DZNEmptyDataSet;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Abstract base view controller class for custom table-based view controllers retrieving paginated lists of objects. Subclasses must
 *  implement methods from the Subclassing protocol to specify the data retrieval process.
 *
 *  In addition of all features of ListRequestViewController, this class provides the following features:
 *    - Pull-to-refresh
 *    - Automatic display of a load more footer if more data is available
 *    - Clean display of empty tables, whether because of an error or because no items are available
 */
@interface TableRequestViewController : ListRequestViewController <ContentInsets, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, TabBarActionable, UITableViewDataSource, UITableViewDelegate>

/**
 *  The table view.
 */
@property (nonatomic, weak, nullable) IBOutlet UITableView *tableView;

/**
 *  The title displayed when the table view is empty. If nil, a default "No results" text is displayed
 */
@property (nonatomic, copy, null_resettable) NSString *emptyTableTitle;

/**
 *  The subtitle displayed when the table is empty. If nil, a default "Pull to reload" text is displayed
 */
@property (nonatomic, copy, null_resettable) NSString *emptyTableSubtitle;

/**
 *  The image displayed when the collection is empty
 *
 *  @discussion If an image has been set, an error image will be displayed when an error has been encountered, so that
 *              layouts are similar.
 */
@property (nonatomic, copy, nullable) UIImage *emptyCollectionImage;

@end

/**
 *  The following methods can be optionally implemented and are required to call the parent implementation
 */
@interface TableRequestViewController (OptionalOverrides)

// See ListRequestViewController documentation for more information
- (void)refreshDidStart NS_REQUIRES_SUPER;
- (void)refreshDidFinishWithError:(nullable NSError *)error NS_REQUIRES_SUPER;

// See UIScrollView documentation for more information
- (void)scrollViewDidScroll:(UIScrollView *)scrollView NS_REQUIRES_SUPER;

// See DZNEmptyDataSetSource documentation for more information
- (CGFloat)verticalOffsetForEmptyDataSet:(UIScrollView *)scrollView NS_REQUIRES_SUPER;

@end

NS_ASSUME_NONNULL_END
