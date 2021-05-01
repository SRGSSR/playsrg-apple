//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Layout.h"

const CGFloat LayoutStandardLabelCornerRadius = 2.f;
const CGFloat LayoutStandardViewCornerRadius = 4.f;

#if TARGET_OS_TV
const CGFloat LayoutStandardMargin = 40.f;

const CGFloat LayoutFeaturedSpacerHeight = 10.f;

const NSDirectionalEdgeInsets LayoutStandardSectionContentInsets = { 20.f, 0.f, 20.f, 0.f };
const NSDirectionalEdgeInsets LayoutTopicSectionContentInsets = { 40.f, 0.f, 40.f, 0.f };

const CGFloat LayoutStandardCellHeight = 150.f;

const CGFloat LayoutMediaBadgePadding = 8.f;
const CGFloat LayoutProgressBarHeight = 8.f;

#else
const CGFloat LayoutStandardMargin = 10.f;

const CGFloat LayoutFeaturedSpacerHeight = 5.f;

const NSDirectionalEdgeInsets LayoutStandardSectionContentInsets = { 10.f, 10.f, 10.f, 10.f };
const NSDirectionalEdgeInsets LayoutTopicSectionContentInsets = { 20.f, 10.f, 20.f, 10.f };

const CGFloat LayoutStandardCellHeight = 84.f;

const CGFloat LayoutMediaBadgePadding = 6.f;
const CGFloat LayoutProgressBarHeight = 3.f;

#endif

const UIEdgeInsets LayoutStandardCollectionViewPaddingInsets = { 0.f, 0.f, 0.f, 0.f };

const UIEdgeInsets LayoutStandardTableViewPaddingInsets = { LayoutStandardMargin, 0.f, LayoutStandardMargin, 0.f };

static CGFloat LayoutOptimalGridCellWidth(CGFloat approximateWidth, CGFloat layoutWidth, CGFloat spacing, NSInteger minimumNumberOfColumns)
{
    NSCParameterAssert(minimumNumberOfColumns >= 1);
    NSInteger numberOfItemsPerRow = MAX((layoutWidth + spacing) / (approximateWidth + spacing), minimumNumberOfColumns);
    return (layoutWidth - (numberOfItemsPerRow - 1) * spacing) / numberOfItemsPerRow;
}

CGSize LayoutSwimlaneCellSize(CGFloat width, CGFloat aspectRatio, CGFloat heightOffset)
{
    return CGSizeMake(width, width / aspectRatio + heightOffset);
}

CGSize LayoutGridCellSize(CGFloat approximateWidth, CGFloat aspectRatio, CGFloat heightOffset, CGFloat layoutWidth, CGFloat spacing, NSInteger minimumNumberOfColumns)
{
    CGFloat width = LayoutOptimalGridCellWidth(approximateWidth, layoutWidth, spacing, minimumNumberOfColumns);
    return LayoutSwimlaneCellSize(width, aspectRatio, heightOffset);
}

CGSize LayoutFractionedCellSize(CGFloat width, CGFloat contentAspectRatio, CGFloat fraction)
{
    CGFloat height = width * fraction / contentAspectRatio;
    return CGSizeMake(width, height);
}
