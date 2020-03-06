//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "MediasViewController.h"

#import "Layout.h"
#import "MediaCollectionViewCell.h"
#import "UIViewController+PlaySRG.h"

#import <SRGAppearance/SRGAppearance.h>

static const CGFloat kLayoutHorizontalInset = 10.f;

@implementation MediasViewController

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.emptyCollectionImage = [UIImage imageNamed:@"media-90"];
    
    NSString *cellIdentifier = NSStringFromClass(MediaCollectionViewCell.class);
    UINib *cellNib = [UINib nibWithNibName:cellIdentifier bundle:nil];
    [self.collectionView registerNib:cellNib forCellWithReuseIdentifier:cellIdentifier];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(accessibilityVoiceOverStatusChanged:)
                                               name:UIAccessibilityVoiceOverStatusChanged
                                             object:nil];
}

#pragma mark UICollectionViewDataSource protocol

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.items.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [collectionView dequeueReusableCellWithReuseIdentifier:NSStringFromClass(MediaCollectionViewCell.class)
                                                     forIndexPath:indexPath];
}

#pragma mark UICollectionViewDelegate protocol

- (void)collectionView:(UICollectionView *)collectionView willDisplayCell:(MediaCollectionViewCell *)cell forItemAtIndexPath:(NSIndexPath *)indexPath
{
    [cell setMedia:self.items[indexPath.row] withDateFormatter:self.dateFormatter];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    SRGMedia *media = self.items[indexPath.row];
    [self play_presentMediaPlayerWithMedia:media position:nil airPlaySuggestions:YES fromPushNotification:NO animated:YES completion:nil];
}

#pragma mark UICollectionViewDelegateFlowLayout protocol

- (UIEdgeInsets)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout insetForSectionAtIndex:(NSInteger)section
{
    return UIEdgeInsetsMake(10.f, kLayoutHorizontalInset, 10.f, kLayoutHorizontalInset);
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewFlowLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    // Table layout
    if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact) {
        return CGSizeMake(CGRectGetWidth(collectionView.frame) - 2 * kLayoutHorizontalInset, 84.f);
    }
    // Grid layout
    else {
        static NSDictionary<NSString *, NSNumber *> *s_textHeights;
        static dispatch_once_t s_onceToken;
        dispatch_once(&s_onceToken, ^{
            s_textHeights = @{ UIContentSizeCategoryExtraSmall : @63,
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
        
        NSString *contentSizeCategory = UIApplication.sharedApplication.preferredContentSizeCategory;
        CGFloat minTextHeight = s_textHeights[contentSizeCategory].floatValue;
        CGFloat itemWidth = GridLayoutItemWidth(210.f, CGRectGetWidth(collectionView.frame), kLayoutHorizontalInset, kLayoutHorizontalInset, collectionViewLayout.minimumInteritemSpacing);
        return CGSizeMake(itemWidth, ceilf(itemWidth * 9.f / 16.f + minTextHeight));
    }
}

#pragma mark Notifications

- (void)accessibilityVoiceOverStatusChanged:(NSNotification *)notification
{
    [self.collectionView reloadData];
}

@end
