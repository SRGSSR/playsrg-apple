//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGDataProvider/SRGDataProvider.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface SearchShowListCollectionViewCell : UICollectionViewCell <UICollectionViewDataSource, UICollectionViewDelegate>

@property (nonatomic, nullable) NSArray<SRGShow *> *shows;

@end

NS_ASSUME_NONNULL_END
