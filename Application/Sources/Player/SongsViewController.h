//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ContentInsets.h"
#import "TableRequestViewController.h"

#import <SRGDataProvider/SRGDataProvider.h>

NS_ASSUME_NONNULL_BEGIN

@interface SongsViewController : TableRequestViewController <ContentInsets>

- (instancetype)initWithChannel:(SRGChannel *)channel vendor:(SRGVendor)vendor;

@property (nonatomic, readonly) SRGChannel *channel;
@property (nonatomic, readonly) SRGVendor vendor;

@end

NS_ASSUME_NONNULL_END
