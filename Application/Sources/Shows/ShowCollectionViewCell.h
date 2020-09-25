//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Previewing.h"

@import SRGDataProvider;
@import UIKit;

NS_ASSUME_NONNULL_BEGIN

@interface ShowCollectionViewCell : UICollectionViewCell <Previewing>

- (void)setShow:(SRGShow *)show featured:(BOOL)featured;

@end

NS_ASSUME_NONNULL_END
