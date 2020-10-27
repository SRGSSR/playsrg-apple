//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import SRGDataProviderModel;
@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface SearchShowListCollectionViewCell : UICollectionViewCell <UICollectionViewDataSource, UICollectionViewDelegate>

@property (class, nonatomic, readonly) CGFloat height;

@property (nonatomic, nullable) NSArray<SRGShow *> *shows;

@end

NS_ASSUME_NONNULL_END
