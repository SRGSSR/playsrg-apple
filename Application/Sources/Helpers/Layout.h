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
OBJC_EXPORT const CGFloat LayoutStandardCellHeight;

/**
 *  Live media grid large dimensions (iOS).
 */
OBJC_EXPORT const CGFloat LayoutLiveMediaGridLargeBoundWidth;
OBJC_EXPORT const CGFloat LayoutLiveMediaGridLargeCellWidth;

/**
 *  Standard margin.
 */
OBJC_EXPORT const CGFloat LayoutStandardMargin;

/**
 *  Featured spacer height.
 */
OBJC_EXPORT const CGFloat LayoutFeaturedSpacerHeight;

/**
 *  Standard collection view padding.
 */
OBJC_EXPORT const UIEdgeInsets LayoutStandardCollectionViewPaddingInsets;

/**
 *  Standard table view padding.
 */
OBJC_EXPORT const UIEdgeInsets LayoutStandardTableViewPaddingInsets;

/**
 *  Layout collection item types
 */
typedef NS_ENUM(NSInteger, LayoutCollectionItemType) {
    /**
     *  Hero layout.
     */
    LayoutCollectionItemTypeHero = 0,
    /**
     *  Highlight layout.
     */
    LayoutCollectionItemTypeHighlight,
    /**
     *  Media swimlane layout.
     */
    LayoutCollectionItemTypeMediaSwimlaneOrGrid,
    /**
     *  Show swimlane layout.
     */
    LayoutCollectionItemTypeShowSwimlaneOrGrid,
    /**
     *  Live media grid layout (iOS).
     */
    LayoutCollectionItemTypeLiveMediaGrid
};

/**
 *  Badge top leading padding.
 */
OBJC_EXPORT const CGFloat LayoutBadgeTopLeadingPadding;

/**
 *  Progress bar height.
 */
OBJC_EXPORT const CGFloat LayoutProgressBarHeight;


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
OBJC_EXPORT CGFloat LayoutCollectionItemFeaturedWidth(CGFloat layoutWidth, LayoutCollectionItemType collectionItemType);

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
 *  Collection cell (16:9 artwork + text area) size for collection layouts, for a given item width and collection layout type.
 *
 *  @param itemWidth The width of the item.
 *  @param collectionItemType Collection item layout (e.g. hero, highlight or swimlanes).
 *  @param horizontalSizeClass The horizontal size class.
 */
OBJC_EXPORT CGSize LayoutCollectionItemSize(CGFloat itemWidth, LayoutCollectionItemType collectionItemType, UIUserInterfaceSizeClass horizontalSizeClass);

/**
 *  Topic cell (16:9 artwork) size for collection layouts.
 */
OBJC_EXPORT CGSize LayoutTopicCollectionItemSize(void);

/**
 *  Show access cell size for collection layouts.
 */
OBJC_EXPORT CGSize LayoutShowAccessCollectionItemSize(CGFloat itemWidth);

NS_ASSUME_NONNULL_END
