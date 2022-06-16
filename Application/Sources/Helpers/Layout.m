//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Layout.h"

@import SRGAppearance;

const CGFloat LayoutStandardLabelCornerRadius = 2.f;
const CGFloat LayoutStandardViewCornerRadius = 4.f;

#if TARGET_OS_TV
const CGFloat LayoutProgressBarHeight = 8.f;
#else
const CGFloat LayoutProgressBarHeight = 3.f;
#endif

const CGFloat LayoutHeaderHeightZero = 0.001f;
const CGFloat LayoutBlurActivationDistance = 10.f;

const CGFloat LayoutMargin = 8.f;
const UIEdgeInsets LayoutPaddingContentInsets = { LayoutMargin, 0.f, LayoutMargin, 0.f };
const UIEdgeInsets LayoutTableViewPaddingContentInsets = { LayoutMargin / 2.f, 0.f, LayoutMargin / 2.f, 0.f };

const CGFloat LayoutLargeNavigationBarHeightContribution = 52.f;

static const CGFloat LayoutSearchBarHeightContribution = 52.f;

static CGFloat LayoutOptimalGridCellWidth(CGFloat approximateWidth, CGFloat layoutWidth, CGFloat spacing, NSInteger minimumNumberOfColumns)
{
    NSCParameterAssert(minimumNumberOfColumns >= 1);
    NSInteger numberOfItemsPerRow = MAX((layoutWidth + spacing) / (approximateWidth + spacing), minimumNumberOfColumns);
    return (layoutWidth - (numberOfItemsPerRow - 1) * spacing) / numberOfItemsPerRow;
}

NSCollectionLayoutSize *LayoutSwimlaneCellSize(CGFloat width, CGFloat aspectRatio, CGFloat heightOffset)
{
    // Use body as scaling curve; should offer pretty standard behavior covering all needs
    UIFontMetrics *fontMetrics = [SRGFont metricsForFontWithStyle:SRGFontStyleBody];
    CGFloat height = width / aspectRatio + [fontMetrics scaledValueForValue:heightOffset];
    return [NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension absoluteDimension:width]
                                          heightDimension:[NSCollectionLayoutDimension absoluteDimension:height]];
}

NSCollectionLayoutSize *LayoutGridCellSize(CGFloat approximateWidth, CGFloat aspectRatio, CGFloat heightOffset, CGFloat layoutWidth, CGFloat spacing, NSInteger minimumNumberOfColumns)
{
    CGFloat width = LayoutOptimalGridCellWidth(approximateWidth, layoutWidth, spacing, minimumNumberOfColumns);
    return LayoutSwimlaneCellSize(width, aspectRatio, heightOffset);
}

NSCollectionLayoutSize *LayoutFractionedCellSize(CGFloat width, CGFloat contentAspectRatio, CGFloat fraction)
{
    CGFloat height = width * fraction / contentAspectRatio;
    return [NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension absoluteDimension:width]
                                          heightDimension:[NSCollectionLayoutDimension absoluteDimension:height]];
}

NSCollectionLayoutSize *LayoutFullWidthCellSize(CGFloat height)
{
    // Use body as scaling curve; should offer pretty standard behavior covering all needs
    UIFontMetrics *fontMetrics = [SRGFont metricsForFontWithStyle:SRGFontStyleBody];
    CGFloat scaledHeight = [fontMetrics scaledValueForValue:height];
    return [NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension fractionalWidthDimension:1.f]
                                          heightDimension:[NSCollectionLayoutDimension absoluteDimension:scaledHeight]];
}

static CGFloat LayoutStandardNavigationBarHeightContribution(void)
{
    return (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) ? 50.f : 44.f;
}

LayoutNavigationBarState LayoutNavigationBarStateForNavigationController(UINavigationController *navigationController)
{
    UISearchController *searchController = navigationController.topViewController.navigationItem.searchController;
    if (searchController) {
        if (! searchController.hidesNavigationBarDuringPresentation || ! searchController.active) {
            UINavigationBar *navigationBar = navigationController.navigationBar;
            CGFloat navigationBarHeight = CGRectGetHeight(navigationBar.frame);
            if (navigationBarHeight <= LayoutStandardNavigationBarHeightContribution() + LayoutSearchBarHeightContribution) {
                return LayoutNavigationBarStateNormal;
            }
            else if (navigationBarHeight >= LayoutStandardNavigationBarHeightContribution() + LayoutSearchBarHeightContribution + LayoutLargeNavigationBarHeightContribution) {
                return LayoutNavigationBarStateLarge;
            }
            else {
                return LayoutNavigationBarStateResizing;
            }
        }
        else {
            return LayoutNavigationBarStateNormal;
        }
    }
    else {
        UINavigationBar *navigationBar = navigationController.navigationBar;
        CGFloat navigationBarHeight = CGRectGetHeight(navigationBar.frame);
        if (navigationBarHeight <= LayoutStandardNavigationBarHeightContribution()) {
            return LayoutNavigationBarStateNormal;
        }
        else if (navigationBarHeight >= LayoutStandardNavigationBarHeightContribution() + LayoutLargeNavigationBarHeightContribution) {
            return LayoutNavigationBarStateLarge;
        }
        else {
            return LayoutNavigationBarStateResizing;
        }
    }
}

