//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Layout.h"

const CGFloat LayoutStandardLabelCornerRadius = 2.f;
const CGFloat LayoutStandardViewCornerRadius = 4.f;

#if TARGET_OS_TV
const CGFloat LayoutMediaBadgePadding = 8.f;
const CGFloat LayoutProgressBarHeight = 8.f;
#else
const CGFloat LayoutMediaBadgePadding = 6.f;
const CGFloat LayoutProgressBarHeight = 3.f;
#endif

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
