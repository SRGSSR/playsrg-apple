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
 *  Progress bar height.
 */
OBJC_EXPORT const CGFloat LayoutProgressBarHeight;

/**
 *  Zero header height.
 */
OBJC_EXPORT const CGFloat LayoutHeaderHeightZero;

/**
 *  Return the size of a cell whose content has the given width and aspect ratio, suited for display in swimlanes. A
 *  height offset can be provided if more space is required for displaying additional content.
 *
 *  Scales with accessibility font size settings.
 *
 *        ┌────────────────────────────────────┐
 *        │....................................│
 *        │....................................│
 *        │....................................│
 *        │.............          .............│
 *        │............. Content  .............│
 *        │.............          .............│
 *        │....................................│
 *        │....................................│
 *        │....................................│
 *        ├────────────────────────────────────┤    ▲
 *        │                                    │    │
 *        │                                    │    │ height
 *        │                                    │    │ offset
 *        └────────────────────────────────────┘    ▼
 *        ◀────────────────────────────────────▶
 *                       width
 */
OBJC_EXPORT NSCollectionLayoutSize *LayoutSwimlaneCellSize(CGFloat width, CGFloat aspectRatio, CGFloat heightOffset);

/**
 *  Return the size of a cell for a grid layout, so that cells are spaced with the exact required value. An
 *  approximate width must be provided as a hint, so that the function can best determine the actual item size
 *  best matching the desired result. A minimal number of columns must also be provided (>= 1).
 *
 *  As for `LayoutSwimlaneCellSize`, an aspect ratio must be provided, as well as a height offset is more
 *  space is required vertically.
 *
 *  Scales with accessibility font size settings.
 */
OBJC_EXPORT NSCollectionLayoutSize *LayoutGridCellSize(CGFloat approximateWidth, CGFloat aspectRatio, CGFloat heightOffset, CGFloat layoutWidth, CGFloat spacing, NSInteger minimumNumberOfColumns);

/**
 *  Return the size for a cell so that content with some aspect ratio is displayed in it, in such a way that the
 *  content width only occupies a given fraction of the cell width.
 *
 *        ┌──────────────────────────────────────────────┬─────────────────────┐
 *        │..............................................│                     │
 *        │..............................................│                     │
 *        │..............................................│                     │
 *        │..............................................│                     │
 *        │..............                 ...............│                     │
 *        │..............     Content     ...............│                     │
 *        │..............                 ...............│                     │
 *        │..............................................│                     │
 *        │..............................................│                     │
 *        │..............................................│                     │
 *        │..............................................│                     │
 *        └──────────────────────────────────────────────┴─────────────────────┘
 *        ◀─────────────────────────────────────────────▶
 *                         content width
 *
 *        ◀──────────────────────────────────────────────────────────────────▶
 *                                    width
 */
OBJC_EXPORT NSCollectionLayoutSize *LayoutFractionedCellSize(CGFloat width, CGFloat contentAspectRatio, CGFloat fraction);

/**
 *  Simple full-width cell with a fixed height. Scales with accessibility font size settings.
 */
OBJC_EXPORT NSCollectionLayoutSize *LayoutFullWidthCellSize(CGFloat height);

/**
 *  Table and collection view constants.
 */

OBJC_EXPORT const CGFloat LayoutMargin;
OBJC_EXPORT const UIEdgeInsets LayoutPaddingContentInsets;
OBJC_EXPORT const UIEdgeInsets LayoutTableViewPaddingContentInsets;

/**
 *  Miscellaneous constants.
 */
OBJC_EXPORT const CGFloat LayoutBlurActivationDistance;

/**
 *  Contribution associated
 */
OBJC_EXPORT const CGFloat LayoutLargeNavigationBarHeightContribution;

/**
 *  Navigation bar states.
 */
typedef NS_CLOSED_ENUM(NSInteger, LayoutNavigationBarState) {
    LayoutNavigationBarStateNormal = 0,
    LayoutNavigationBarStateResizing,
    LayoutNavigationBarStateLarge
};

/**
 *  Returns the navigation bar state for the specified navigation controller.
 */
OBJC_EXPORT LayoutNavigationBarState LayoutNavigationBarStateForNavigationController(UINavigationController *navigationController);

NS_ASSUME_NONNULL_END
