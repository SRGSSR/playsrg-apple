//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Standard corner radius constants.
 */
OBJC_EXPORT const CGFloat LayoutStandardLabelCornerRadius;
OBJC_EXPORT const CGFloat LayoutStandardViewCornerRadius;

/**
 *  Section content insets.
 */
OBJC_EXPORT const NSDirectionalEdgeInsets LayoutStandardSectionContentInsets;
OBJC_EXPORT const NSDirectionalEdgeInsets LayoutTopicSectionContentInsets;

/**
 *  Standard cell dimensions.
 */
OBJC_EXPORT const CGFloat LayoutStandardCellWidth;
OBJC_EXPORT const CGFloat LayoutTopicCellWidth;
OBJC_EXPORT const CGFloat LayoutStandardCellHeight API_UNAVAILABLE(tvos);

/**
 *  Standard margin.
 */
OBJC_EXPORT const CGFloat LayoutStandardMargin;

/**
 *  Standard collection view padding.
 */
OBJC_EXPORT const UIEdgeInsets LayoutStandardCollectionViewPaddingInsets;

/**
 *  Standard table view padding.
 */
OBJC_EXPORT const UIEdgeInsets LayoutStandardTableViewPaddingInsets;

/**
 *  Media standard collection item types
 */
typedef NS_ENUM(NSInteger, LayoutCollectionItemType) {
    /**
     *  Swimlane layout.
     */
    LayoutCollectionItemTypeSwimlane = 0,
    /**
     *  Hero layout.
     */
    LayoutCollectionItemTypeHero,
    /**
     *  Highlight layout.
     */
    LayoutCollectionItemTypeHighlight
};

/**
 *  Calculate the width to apply to items within a collection so that they approach some desired size, ensuring constant
 *  spacing between items.
 *
 *  @param itemApproximateWidth The desired approximate width for items. The returned width might be smaller or bigger.
 *  @param layoutWidth          The total available width for layout.
 *  @param leadingInset         The leading layout inset.
 *  @param trailingInset        The trailing layout inset.
 *  @param spacing              The desired spacing.
 */
OBJC_EXPORT CGFloat LayoutCollectionItemOptimalWidth(CGFloat itemApproximateWidth, CGFloat layoutWidth, CGFloat leadingInset, CGFloat trailingInset, CGFloat spacing);

/**
 *  Calculate the width to apply to featured items in a collection. Featured items attempt occupying (almost) the full width
 *  of narrow layouts, but still have bounded (larger) size on wide layouts.
 *
 *  @param layoutWidth The total available width for layout.
 */
OBJC_EXPORT CGFloat LayoutCollectionItemFeaturedWidth(CGFloat layoutWidth);

/**
 *  Return the standard height for a collection section header title
 */
OBJC_EXPORT CGFloat LayoutCollectionSectionHeaderTitleHeight(void);

/**
 *  Return the standard height for table view headers.
 */
OBJC_EXPORT CGFloat LayoutStandardTableSectionHeaderHeight(BOOL hasBackgroundColor);

/**
 *  Return the standard height for simple table cells.
 */
OBJC_EXPORT CGFloat LayoutStandardSimpleTableCellHeight(void);

/**
 *  Return the height for a top-aligned table cell with given spacing.
 */
OBJC_EXPORT CGFloat LayoutTableTopAlignedCellHeight(CGFloat contentHeight, CGFloat spacing, NSInteger row, NSInteger numberOfItems);

/**
 *  Standard media cell (16:9 artwork + text area) size for collection layouts, for a given item width.
 *
 *  @param itemWidth The width of the item.
 *  @param collectionItemType Collection item layout (e.g. hero, highlight or swimlane).
 */
OBJC_EXPORT CGSize LayoutMediaStandardCollectionItemSize(CGFloat itemWidth, LayoutCollectionItemType collectionItemType);

/**
 *  Live media cell (16:9 artwork + progress area) size for collection layouts, for a given item width.
 *
 *  @param itemWidth The width of the item.
 */
OBJC_EXPORT CGSize LayoutLiveMediaStandardCollectionItemSize(CGFloat itemWidth);

/**
 *  Standard media cell (16:9 artwork + text area) size for collection layouts, for a given item width.
 *
 *  @param itemWidth                     The width of the item.
 *  @param collectionItemType Collection item layout (e.g. hero, highlight or swimlane).
 */
OBJC_EXPORT CGSize LayoutShowStandardCollectionItemSize(CGFloat itemWidth, LayoutCollectionItemType collectionItemType);

/**
 *  Topic cell (16:9 artwork) size for collection layouts.
 */
OBJC_EXPORT CGSize LayoutTopicCollectionItemSize(void);

/**
 *  Show access cell size for collection layouts.
 */
OBJC_EXPORT CGSize LayoutShowAccessCollectionItemSize(CGFloat itemWidth);

NS_ASSUME_NONNULL_END
