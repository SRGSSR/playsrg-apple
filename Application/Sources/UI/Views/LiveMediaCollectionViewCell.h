//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Previewing.h"

#import <SRGDataProvider/SRGDataProvider.h>

NS_ASSUME_NONNULL_BEGIN

@interface LiveMediaCollectionViewCell : UICollectionViewCell <Previewing>

+ (CGFloat)heightForMedia:(SRGMedia *)media withWidth:(CGFloat)width;

@property (nonatomic, nullable) SRGMedia *media;

@end

NS_ASSUME_NONNULL_END
