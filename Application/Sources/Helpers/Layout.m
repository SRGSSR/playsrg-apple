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

const CGFloat LayoutStandardCellWidth = 375.f;
const CGFloat LayoutTopicCellWidth = 250.f;
const CGFloat LayoutStandardCellHeight = 150.f;

const CGFloat LayoutMediaBadgePadding = 8.f;
const CGFloat LayoutProgressBarHeight = 8.f;

#else
const CGFloat LayoutStandardMargin = 10.f;

const CGFloat LayoutFeaturedSpacerHeight = 5.f;

const NSDirectionalEdgeInsets LayoutStandardSectionContentInsets = { 10.f, 10.f, 10.f, 10.f };
const NSDirectionalEdgeInsets LayoutTopicSectionContentInsets = { 20.f, 10.f, 20.f, 10.f };

const CGFloat LayoutStandardCellWidth = 210.f;
const CGFloat LayoutTopicCellWidth = 150.f;
const CGFloat LayoutStandardCellHeight = 84.f;

const CGFloat LayoutMediaBadgePadding = 6.f;
const CGFloat LayoutProgressBarHeight = 3.f;

#endif

const CGFloat LayoutLiveMediaGridLargeBoundWidth = 1000.f;
const CGFloat LayoutLiveMediaGridLargeCellWidth = 275.f;

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

CGFloat LayoutStandardSimpleTableCellHeight(void)
{
    static NSDictionary<UIContentSizeCategory, NSNumber *> *s_heights;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_heights = @{ UIContentSizeCategoryExtraSmall : @42,
                       UIContentSizeCategorySmall : @42,
                       UIContentSizeCategoryMedium : @46,
                       UIContentSizeCategoryLarge : @50,
                       UIContentSizeCategoryExtraLarge : @54,
                       UIContentSizeCategoryExtraExtraLarge : @58,
                       UIContentSizeCategoryExtraExtraExtraLarge : @62,
                       UIContentSizeCategoryAccessibilityMedium : @62,
                       UIContentSizeCategoryAccessibilityLarge : @62,
                       UIContentSizeCategoryAccessibilityExtraLarge : @62,
                       UIContentSizeCategoryAccessibilityExtraExtraLarge : @62,
                       UIContentSizeCategoryAccessibilityExtraExtraExtraLarge : @62 };
    });
    UIContentSizeCategory contentSizeCategory = UIApplication.sharedApplication.preferredContentSizeCategory;
    return s_heights[contentSizeCategory].floatValue;
}

CGFloat LayoutTableTopAlignedCellHeight(CGFloat contentHeight, CGFloat spacing, NSInteger row, NSInteger numberOfItems)
{
    if (row < numberOfItems - 1) {
        return contentHeight + spacing;
    }
    else {
        return contentHeight;
    }
}
