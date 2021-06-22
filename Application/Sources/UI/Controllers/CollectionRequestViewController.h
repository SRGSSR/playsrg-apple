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
 *  Abstract base view controller class for custom collection-based view controllers retrieving paginated lists of objects. Subclasses must
 *  implement methods from the Subclassing protocol to specify the data retrieval process. Only collections with flow layouts are supported
 *
 *  In addition of all features of ListRequestViewController, this class provides the following features:
 *    - Pull-to-refresh
 *    - Automatic display of a load more footer if more data is available
 *    - Clean display of empty collections, whether because of an error or because no items are available
 */
@interface CollectionRequestViewController : ListRequestViewController <ContentInsets, DZNEmptyDataSetSource, DZNEmptyDataSetDelegate, TabBarActionable, UICollectionViewDelegateFlowLayout, UICollectionViewDataSource, UICollectionViewDelegate>

/**
 *  The collection view. A flow layout is required
 */
@property (nonatomic, weak, nullable) IBOutlet UICollectionView *collectionView;

/**
 *  The title displayed when the collection is empty. If nil, a default "No results" text is displayed
 */
@property (nonatomic, copy, null_resettable) NSString *emptyCollectionTitle;

/**
 *  The subtitle displayed when the collection is empty. If nil, a default "Pull to reload" text is displayed
 */
@property (nonatomic, copy, null_resettable) NSString *emptyCollectionSubtitle;

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
@interface CollectionRequestViewController (OptionalOverrides)

// See ListRequestViewController documentation for more information
- (void)refreshDidStart NS_REQUIRES_SUPER;
- (void)refreshDidFinishWithError:(nullable NSError *)error NS_REQUIRES_SUPER;

// See UICollectionView documentation for more information
- (UICollectionReusableView *)collectionView:(UICollectionView *)collectionView viewForSupplementaryElementOfKind:(NSString *)kind atIndexPath:(NSIndexPath *)indexPath NS_REQUIRES_SUPER;
- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewFlowLayout *)collectionViewLayout referenceSizeForFooterInSection:(NSInteger)section NS_REQUIRES_SUPER;
- (UIContextMenuConfiguration *)collectionView:(UICollectionView *)collectionView contextMenuConfigurationForItemAtIndexPath:(NSIndexPath *)indexPath point:(CGPoint)point NS_REQUIRES_SUPER;
- (void)collectionView:(UICollectionView *)collectionView willPerformPreviewActionForMenuWithConfiguration:(UIContextMenuConfiguration *)configuration animator:(id<UIContextMenuInteractionCommitAnimating>)animator NS_REQUIRES_SUPER;
- (UITargetedPreview *)collectionView:(UICollectionView *)collectionView previewForHighlightingContextMenuWithConfiguration:(UIContextMenuConfiguration *)configuration NS_REQUIRES_SUPER;
- (UITargetedPreview *)collectionView:(UICollectionView *)collectionView previewForDismissingContextMenuWithConfiguration:(UIContextMenuConfiguration *)configuration NS_REQUIRES_SUPER;
- (UITargetedPreview *)previewForConfiguration:(UIContextMenuConfiguration *)configuration inCollectionView:(UICollectionView *)collectionView NS_REQUIRES_SUPER;

// See UIScrollView documentation for more information
- (void)scrollViewDidScroll:(UIScrollView *)scrollView NS_REQUIRES_SUPER;

// See DZNEmptyDataSetSource documentation for more information
- (CGFloat)verticalOffsetForEmptyDataSet:(UIScrollView *)scrollView NS_REQUIRES_SUPER;

@end

NS_ASSUME_NONNULL_END
