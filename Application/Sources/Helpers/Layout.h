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

NS_ASSUME_NONNULL_END
