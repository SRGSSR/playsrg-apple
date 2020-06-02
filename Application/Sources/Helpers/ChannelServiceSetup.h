//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGDataProvider/SRGDataProvider.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Setup common to a group of channel update registrations.
 */
@interface ChannelServiceSetup : NSObject <NSCopying>

/**
 *  Setup for retrieval of updates for a given channel, vendor and livestream identifier.
 */
- (instancetype)initWithChannel:(SRGChannel *)channel vendor:(SRGVendor)vendor livestreamUid:(NSString *)livestreamUid;

/**
 *  Associated data.
 */
@property (nonatomic, readonly) SRGChannel *channel;
@property (nonatomic, readonly) SRGVendor vendor;
@property (nonatomic, readonly, copy) NSString *livestreamUid;

@end

NS_ASSUME_NONNULL_END
