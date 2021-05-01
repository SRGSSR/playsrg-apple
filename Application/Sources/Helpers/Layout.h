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
OBJC_EXPORT const CGFloat LayoutStandardCellHeight;

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
 *  Media badge padding.
 */
OBJC_EXPORT const CGFloat LayoutMediaBadgePadding;

/**
 *  Progress bar height.
 */
OBJC_EXPORT const CGFloat LayoutProgressBarHeight;

/**
 *  Return the size of a cell having the given width and aspect ratio, suited for display in swimlanes. A height
 *  offset can be provided if more space is required vertically.
 */
OBJC_EXPORT CGSize LayoutSwimlaneCellSize(CGFloat width, CGFloat aspectRatio, CGFloat heightOffset);

/**
 *  Return the size of a cell for a grid layout, so that cells are spaced with the exact required spacing. An
 *  approximate width must be provided as a hint, so that the function can best determine the actual item size
 *  best matching the desired result. A minimal number of columns can be provided (>= 1).
 *
 *  As for `LayoutSwimlaneCellSize`, an aspect ratio must be provided, as well as a height offset is more
 *  space is required vertically.
 */
OBJC_EXPORT CGSize LayoutGridCellSize(CGFloat approximateWidth, CGFloat aspectRatio, CGFloat heightOffset, CGFloat layoutWidth, CGFloat spacing, NSInteger minimumNumberOfColumns);

/**
 *  Return the size for a cell so that content with some aspect ratio is displayed in it, in such a way that the
 *  content width only occupies a given fraction of the cell width.
 *
 *       ┌──────────────────────────────────────────────┬─────────────────────┐
 *       │..............................................│                     │
 *       │..............................................│                     │
 *       │..............................................│                     │
 *       │..............................................│                     │
 *       │..............                 ...............│                     │
 *       │..............     Content     ...............│                     │
 *       │..............                 ...............│                     │
 *       │..............................................│                     │
 *       │..............................................│                     │
 *       │..............................................│                     │
 *       │..............................................│                     │
 *       └──────────────────────────────────────────────┴─────────────────────┘
 *       ◀─────────────────────────────────────────────▶
 *                        content width
 *
 *       ◀──────────────────────────────────────────────────────────────────▶
 *                                   width
 */
OBJC_EXPORT CGSize LayoutFractionedCellSize(CGFloat width, CGFloat contentAspectRatio, CGFloat fraction);

NS_ASSUME_NONNULL_END
