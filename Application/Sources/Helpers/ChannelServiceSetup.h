//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGDataProvider/SRGDataProvider.h>

NS_ASSUME_NONNULL_BEGIN

@interface ChannelServiceSetup : NSObject <NSCopying>

- (instancetype)initWithChannel:(SRGChannel *)channel vendor:(SRGVendor)vendor livestreamUid:(NSString *)livestreamUid;

@property (nonatomic, readonly) SRGChannel *channel;
@property (nonatomic, readonly) SRGVendor vendor;
@property (nonatomic, readonly, copy) NSString *livestreamUid;

@end

NS_ASSUME_NONNULL_END
