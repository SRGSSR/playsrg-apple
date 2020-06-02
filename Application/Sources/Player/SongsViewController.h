//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "TableRequestViewController.h"

#import <SRGDataProvider/SRGDataProvider.h>

NS_ASSUME_NONNULL_BEGIN

@interface SongsViewController : TableRequestViewController

- (instancetype)initWithChannel:(SRGChannel *)channel vendor:(SRGVendor)vendor;

@end

NS_ASSUME_NONNULL_END
