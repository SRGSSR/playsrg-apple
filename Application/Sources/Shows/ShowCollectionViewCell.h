//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Previewing.h"

#import <SRGDataProvider/SRGDataProvider.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ShowCollectionViewCell : UICollectionViewCell <Previewing>

@property (nonatomic, nullable) SRGShow *show;

@end

NS_ASSUME_NONNULL_END
