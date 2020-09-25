//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Previewing.h"

@import SRGDataProvider;

NS_ASSUME_NONNULL_BEGIN

@interface HomeLiveMediaCollectionViewCell : UICollectionViewCell <Previewing>

@property (nonatomic, nullable) SRGMedia *media;

@end

NS_ASSUME_NONNULL_END
