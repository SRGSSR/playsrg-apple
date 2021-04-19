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

const CGFloat LayoutProgressBarHeight = 8.f;

#else
const CGFloat LayoutStandardMargin = 10.f;

const CGFloat LayoutFeaturedSpacerHeight = 5.f;

const NSDirectionalEdgeInsets LayoutStandardSectionContentInsets = { 10.f, 10.f, 10.f, 10.f };
const NSDirectionalEdgeInsets LayoutTopicSectionContentInsets = { 20.f, 10.f, 20.f, 10.f };

const CGFloat LayoutStandardCellWidth = 210.f;
const CGFloat LayoutTopicCellWidth = 150.f;
const CGFloat LayoutStandardCellHeight = 84.f;

const CGFloat LayoutProgressBarHeight = 2.f;

#endif

const UIEdgeInsets LayoutStandardCollectionViewPaddingInsets = { 0.f, 0.f, 0.f, 0.f };

const UIEdgeInsets LayoutStandardTableViewPaddingInsets = { LayoutStandardMargin, 0.f, LayoutStandardMargin, 0.f };

CGFloat LayoutCollectionItemOptimalWidth(CGFloat itemApproximateWidth, CGFloat layoutWidth, CGFloat leadingInset, CGFloat trailingInset, CGFloat spacing)
{
    CGFloat availableWidth = layoutWidth - leadingInset - trailingInset;
    if (availableWidth <= 0.f) {
        return 0.f;
    }
    
    // For a grid, two items are required at least
    NSInteger numberOfItemsPerRow = MAX((availableWidth + spacing) / (itemApproximateWidth + spacing), 2);
    return (availableWidth - (numberOfItemsPerRow - 1) * spacing) / numberOfItemsPerRow;
}

CGFloat LayoutCollectionItemFeaturedWidth(CGFloat itemWidth, LayoutCollectionItemType collectionItemType)
{
#if TARGET_OS_TV
    return 1740;
#else
    switch (collectionItemType) {
        case LayoutCollectionItemTypeHero:
            // TODO: Could be only 2 if hero section has only 1 item.
            return itemWidth - 4 * LayoutStandardMargin;
            break;
        case LayoutCollectionItemTypeHighlight:
            return itemWidth - 2 * LayoutStandardMargin;
            break;
        case LayoutCollectionItemTypeSwimlane:
            return LayoutStandardCellWidth;
            break;
    }
    return itemWidth - 2 * LayoutStandardMargin;
#endif
}

OBJC_EXPORT CGFloat LayoutCollectionSectionHeaderTitleHeight()
{
#if TARGET_OS_TV
    return 60.f;
#else
    static NSDictionary<UIContentSizeCategory, NSNumber *> *s_headerHeights;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_headerHeights = @{ UIContentSizeCategoryExtraSmall : @25,
                             UIContentSizeCategorySmall : @30,
                             UIContentSizeCategoryMedium : @35,
                             UIContentSizeCategoryLarge : @35,
                             UIContentSizeCategoryExtraLarge : @35,
                             UIContentSizeCategoryExtraExtraLarge : @35,
                             UIContentSizeCategoryExtraExtraExtraLarge : @40,
                             UIContentSizeCategoryAccessibilityMedium : @40,
                             UIContentSizeCategoryAccessibilityLarge : @40,
                             UIContentSizeCategoryAccessibilityExtraLarge : @40,
                             UIContentSizeCategoryAccessibilityExtraExtraLarge : @40,
                             UIContentSizeCategoryAccessibilityExtraExtraExtraLarge : @40 };
    });
    
    UIContentSizeCategory contentSizeCategory = UIApplication.sharedApplication.preferredContentSizeCategory;
    return s_headerHeights[contentSizeCategory].floatValue;
#endif
}

CGFloat LayoutStandardTableSectionHeaderHeight(BOOL hasBackgroundColor)
{
    CGFloat headerHeight = LayoutCollectionSectionHeaderTitleHeight();
    if (hasBackgroundColor) {
        headerHeight += 6.f;
    }
    return headerHeight;
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

CGSize LayoutMediaStandardCollectionItemSize(CGFloat itemWidth, LayoutCollectionItemType collectionItemType)
{
#if TARGET_OS_TV
    return CGSizeMake(itemWidth, 360.f);
#else
    static NSDictionary<UIContentSizeCategory, NSNumber *> *s_largeTextHeights;
    static NSDictionary<UIContentSizeCategory, NSNumber *> *s_standardTextHeights;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_largeTextHeights = @{ UIContentSizeCategoryExtraSmall : @79,
                                UIContentSizeCategorySmall : @81,
                                UIContentSizeCategoryMedium : @84,
                                UIContentSizeCategoryLarge : @89,
                                UIContentSizeCategoryExtraLarge : @94,
                                UIContentSizeCategoryExtraExtraLarge : @102,
                                UIContentSizeCategoryExtraExtraExtraLarge : @108,
                                UIContentSizeCategoryAccessibilityMedium : @108,
                                UIContentSizeCategoryAccessibilityLarge : @108,
                                UIContentSizeCategoryAccessibilityExtraLarge : @108,
                                UIContentSizeCategoryAccessibilityExtraExtraLarge : @108,
                                UIContentSizeCategoryAccessibilityExtraExtraExtraLarge : @108 };
        
        s_standardTextHeights = @{ UIContentSizeCategoryExtraSmall : @63,
                                   UIContentSizeCategorySmall : @65,
                                   UIContentSizeCategoryMedium : @67,
                                   UIContentSizeCategoryLarge : @70,
                                   UIContentSizeCategoryExtraLarge : @75,
                                   UIContentSizeCategoryExtraExtraLarge : @82,
                                   UIContentSizeCategoryExtraExtraExtraLarge : @90,
                                   UIContentSizeCategoryAccessibilityMedium : @90,
                                   UIContentSizeCategoryAccessibilityLarge : @90,
                                   UIContentSizeCategoryAccessibilityExtraLarge : @90,
                                   UIContentSizeCategoryAccessibilityExtraExtraLarge : @90,
                                   UIContentSizeCategoryAccessibilityExtraExtraExtraLarge : @90 };
    });
    
    BOOL large = (collectionItemType == LayoutCollectionItemTypeHero || collectionItemType == LayoutCollectionItemTypeHighlight);
    UIContentSizeCategory contentSizeCategory = UIApplication.sharedApplication.preferredContentSizeCategory;
    CGFloat minTextHeight = large ? s_largeTextHeights[contentSizeCategory].floatValue : s_standardTextHeights[contentSizeCategory].floatValue;
    return CGSizeMake(itemWidth, ceilf(itemWidth * 9.f / 16.f + minTextHeight));
#endif
}

CGSize LayoutMediaFeaturedCollectionItemSize(CGFloat itemWidth, LayoutCollectionItemType collectionItemType)
{
#if TARGET_OS_TV
    switch (collectionItemType) {
        case LayoutCollectionItemTypeHero:
            return CGSizeMake(itemWidth, 680.f);
            break;
        case LayoutCollectionItemTypeHighlight:
            return CGSizeMake(itemWidth, 480.f);
            break;
        case LayoutCollectionItemTypeSwimlane:
            return LayoutMediaStandardCollectionItemSize(itemWidth, false);
            break;
    }
#else
    UITraitCollection *traitCollection = UIApplication.sharedApplication.keyWindow.traitCollection;
    BOOL isCompact = (traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact);
    
    switch (collectionItemType) {
        case LayoutCollectionItemTypeHero:
            return isCompact ? LayoutMediaStandardCollectionItemSize(itemWidth, true) : CGSizeMake(itemWidth, itemWidth * 3.f / 5.f * 9.f / 16.f);
            break;
        case LayoutCollectionItemTypeHighlight:
            return isCompact ? LayoutMediaStandardCollectionItemSize(itemWidth, true) : CGSizeMake(itemWidth, itemWidth * 2.f / 5.f * 9.f / 16.f);
            break;
        case LayoutCollectionItemTypeSwimlane:
            return LayoutMediaStandardCollectionItemSize(itemWidth, false);
            break;
    }
#endif
}

CGSize LayoutLiveMediaStandardCollectionItemSize(CGFloat itemWidth)
{
    return CGSizeMake(itemWidth, ceilf(itemWidth * 9.f / 16.f + 11.f));
}

CGSize LayoutShowStandardCollectionItemSize(CGFloat itemWidth, LayoutCollectionItemType collectionItemType)
{
#if TARGET_OS_TV
    switch (collectionItemType) {
        case LayoutCollectionItemTypeHero:
            return CGSizeMake(itemWidth, 680.f);
            break;
        case LayoutCollectionItemTypeHighlight:
            return CGSizeMake(itemWidth, 480.f);
            break;
        case LayoutCollectionItemTypeSwimlane:
            return CGSizeMake(itemWidth, 280.f);
            break;
    }
#else
    static NSDictionary<UIContentSizeCategory, NSNumber *> *s_largeTextHeights;
    static NSDictionary<UIContentSizeCategory, NSNumber *> *s_standardTextHeights;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_largeTextHeights = @{ UIContentSizeCategoryExtraSmall : @28,
                                UIContentSizeCategorySmall : @28,
                                UIContentSizeCategoryMedium : @29,
                                UIContentSizeCategoryLarge : @31,
                                UIContentSizeCategoryExtraLarge : @33,
                                UIContentSizeCategoryExtraExtraLarge : @36,
                                UIContentSizeCategoryExtraExtraExtraLarge : @38,
                                UIContentSizeCategoryAccessibilityMedium : @38,
                                UIContentSizeCategoryAccessibilityLarge : @38,
                                UIContentSizeCategoryAccessibilityExtraLarge : @38,
                                UIContentSizeCategoryAccessibilityExtraExtraLarge : @38,
                                UIContentSizeCategoryAccessibilityExtraExtraExtraLarge : @38 };
        
        s_standardTextHeights = @{ UIContentSizeCategoryExtraSmall : @26,
                                   UIContentSizeCategorySmall : @26,
                                   UIContentSizeCategoryMedium : @27,
                                   UIContentSizeCategoryLarge : @29,
                                   UIContentSizeCategoryExtraLarge : @31,
                                   UIContentSizeCategoryExtraExtraLarge : @34,
                                   UIContentSizeCategoryExtraExtraExtraLarge : @36,
                                   UIContentSizeCategoryAccessibilityMedium : @36,
                                   UIContentSizeCategoryAccessibilityLarge : @36,
                                   UIContentSizeCategoryAccessibilityExtraLarge : @36,
                                   UIContentSizeCategoryAccessibilityExtraExtraLarge : @36,
                                   UIContentSizeCategoryAccessibilityExtraExtraExtraLarge : @36 };
    });
    
    BOOL large = (collectionItemType == LayoutCollectionItemTypeHero || collectionItemType == LayoutCollectionItemTypeHighlight);
    UIContentSizeCategory contentSizeCategory = UIApplication.sharedApplication.preferredContentSizeCategory;
    CGFloat minTextHeight = large ? s_largeTextHeights[contentSizeCategory].floatValue : s_standardTextHeights[contentSizeCategory].floatValue;
    return CGSizeMake(itemWidth, ceilf(itemWidth * 9.f / 16.f + minTextHeight));
#endif
}

CGSize LayoutTopicCollectionItemSize(void)
{
    return CGSizeMake(LayoutTopicCellWidth, LayoutTopicCellWidth * 9.f / 16.f);
}

CGSize LayoutShowAccessCollectionItemSize(CGFloat itemWidth)
{
    return CGSizeMake(itemWidth - 2 * LayoutStandardMargin, 50.f);
}
