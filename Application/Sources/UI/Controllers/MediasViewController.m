//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "MediasViewController.h"

#import "Layout.h"
#import "Play-Swift-Bridge.h"
#import "UIViewController+PlaySRG.h"

@import SRGAppearance;

@implementation MediasViewController

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.emptyCollectionImage = [UIImage imageNamed:@"media-90"];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(accessibilityVoiceOverStatusChanged:)
                                               name:UIAccessibilityVoiceOverStatusDidChangeNotification
                                             object:nil];
}

#pragma mark UICollectionViewDataSource protocol

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section
{
    return self.items.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath
{
    return [collectionView mediaCellFor:indexPath media:self.items[indexPath.row]];
}

#pragma mark UICollectionViewDelegate protocol

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath
{
    SRGMedia *media = self.items[indexPath.row];
    [self play_presentMediaPlayerWithMedia:media position:nil airPlaySuggestions:YES fromPushNotification:NO animated:YES completion:nil];
}

#pragma mark UICollectionViewDelegateFlowLayout protocol

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewFlowLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact) {
        return [MediaCellSize fullWidthWithLayoutWidth:CGRectGetWidth(collectionView.frame)];
    }
    else {
        return [MediaCellSize gridWithLayoutWidth:CGRectGetWidth(collectionView.frame) spacing:collectionViewLayout.minimumInteritemSpacing minimumNumberOfColumns:1];
    }
}

#pragma mark Notifications

- (void)accessibilityVoiceOverStatusChanged:(NSNotification *)notification
{
    [self.collectionView reloadData];
}

@end
