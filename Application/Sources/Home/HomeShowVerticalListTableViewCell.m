//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "HomeShowVerticalListTableViewCell.h"

#import "Layout.h"
#import "ShowCollectionViewCell.h"
#import "ShowViewController.h"

#import <SRGAppearance/SRGAppearance.h>

static const CGFloat kLayoutHorizontalInset = 10.f;
static const CGFloat kLayoutMinimumInteritemSpacing = 10.f;
static const CGFloat kLayoutMinimumLineSpacing = 10.f;

@interface HomeShowVerticalListTableViewCell ()

@property (nonatomic, weak) UIView *wrapperView;
@property (nonatomic, weak) UICollectionView *collectionView;

@end

@implementation HomeShowVerticalListTableViewCell

#pragma mark Overrides

+ (CGSize)itemSizeForHomeSectionInfo:(HomeSectionInfo *)homeSectionInfo bounds:(CGRect)bounds
{
    static NSDictionary<NSString *, NSNumber *> *s_textHeights;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_textHeights = @{ UIContentSizeCategoryExtraSmall : @26,
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
    
    NSString *contentSizeCategory = UIApplication.sharedApplication.preferredContentSizeCategory;
    CGFloat minTextHeight = s_textHeights[contentSizeCategory].floatValue;
    CGFloat itemWidth = GridLayoutItemWidth(210.f, CGRectGetWidth(bounds), kLayoutHorizontalInset, kLayoutHorizontalInset, kLayoutMinimumInteritemSpacing);
    return CGSizeMake(itemWidth, ceilf(itemWidth * 9.f / 16.f + minTextHeight));
}

+ (CGFloat)heightForHomeSectionInfo:(HomeSectionInfo *)homeSectionInfo bounds:(CGRect)bounds featured:(BOOL)featured
{
    CGSize itemSize = [self itemSizeForHomeSectionInfo:homeSectionInfo bounds:bounds];
    NSInteger numberOfItemsPerRow = floorf((CGRectGetWidth(bounds) - 2 * kLayoutHorizontalInset + kLayoutMinimumInteritemSpacing) / (itemSize.width + kLayoutMinimumInteritemSpacing));
    NSInteger numberOfItems = (homeSectionInfo.items.count != 0) ? homeSectionInfo.items.count : 4;
    NSInteger numberOfLines = MAX(ceilf((float)numberOfItems / numberOfItemsPerRow), 1);
    return itemSize.height * numberOfLines + (numberOfLines - 1) * kLayoutMinimumLineSpacing;
}

#pragma mark Object lifecycle

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.backgroundColor = UIColor.clearColor;
        self.selectedBackgroundView.backgroundColor = UIColor.clearColor;
        
        UIView *wrapperView = [[UIView alloc] initWithFrame:self.contentView.bounds];
        wrapperView.backgroundColor = UIColor.clearColor;
        wrapperView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        [self.contentView addSubview:wrapperView];
        self.wrapperView = wrapperView;
        
        UICollectionViewFlowLayout *collectionViewLayout = [[UICollectionViewFlowLayout alloc] init];
        collectionViewLayout.scrollDirection = UICollectionViewScrollDirectionVertical;
        collectionViewLayout.minimumLineSpacing = kLayoutMinimumLineSpacing;
        collectionViewLayout.minimumInteritemSpacing = kLayoutMinimumInteritemSpacing;
        
        UICollectionView *collectionView = [[UICollectionView alloc] initWithFrame:wrapperView.bounds collectionViewLayout:collectionViewLayout];
        collectionView.backgroundColor = UIColor.clearColor;
        collectionView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
        collectionView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
        // Important. If > 1 view on-screen is found on iPhone with this property enabled, none will scroll to top
        collectionView.scrollsToTop = NO;
        collectionView.delegate = self;
        collectionView.dataSource = self;
        [wrapperView addSubview:collectionView];
        self.collectionView = collectionView;
        
        // Remark: The collection view is nested in a dummy view to workaround an accessibility bug
        //         See https://stackoverflow.com/a/38798448/760435
        wrapperView.accessibilityElements = @[collectionView];
        
        NSString *showCellIdentifier = NSStringFromClass(ShowCollectionViewCell.class);
        UINib *showCellNib = [UINib nibWithNibName:showCellIdentifier bundle:nil];
        [collectionView registerNib:showCellNib forCellWithReuseIdentifier:showCellIdentifier];
    }
    return self;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    [self.collectionView.collectionViewLayout invalidateLayout];
}

#pragma mark Getters and setters

- (void)setHomeSectionInfo:(HomeSectionInfo *)homeSectionInfo featured:(BOOL)featured
{
    [super setHomeSectionInfo:homeSectionInfo featured:featured];
    
    [self.collectionView reloadData];
}

#pragma mark UICollectionViewDataSource protocol

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return ! [self isEmpty] ? self.homeSectionInfo.items.count : 4;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(ShowCollectionViewCell.class) forIndexPath:indexPath];
}

#pragma mark UICollectionViewDelegate protocol

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(ShowCollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    SRGShow *show = ! [self isEmpty] ? self.homeSectionInfo.items[indexPath.row] : nil;
    [cell setShow:show featured:NO];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (! [self isEmpty]) {
        SRGShow *show = self.homeSectionInfo.items[indexPath.row];
        ShowViewController *showViewController = [[ShowViewController alloc] initWithShow:show fromPushNotification:NO];
        [self.nearestViewController.navigationController pushViewController:showViewController animated:YES];
    }
}

#pragma mark UICollectionViewDelegateFlowLayout protocol

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(0.f, kLayoutHorizontalInset, 0.f, kLayoutHorizontalInset);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewFlowLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [HomeShowVerticalListTableViewCell itemSizeForHomeSectionInfo:self.homeSectionInfo bounds:collectionView.bounds];
}

@end
