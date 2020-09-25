//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Previewing.h"

@import SRGDataProvider;
@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface MediaCollectionViewCell : UICollectionViewCell <Previewing>

// A default date formatting is applied.
@property (nonatomic) SRGMedia *media;

// An optional date formatter can be provided.
- (void)setMedia:(nullable SRGMedia *)media withDateFormatter:(nullable NSDateFormatter *)dateFormatter;

@end

NS_ASSUME_NONNULL_END
