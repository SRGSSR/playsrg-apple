//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>
#import <SRGDataProvider/SRGDataProvider.h>

NS_ASSUME_NONNULL_BEGIN

// Types
typedef void (^ChannelServiceUpdateBlock)(SRGChannel * _Nullable channel);

/**
 *  Service responsible for retrieving and broadcasting channel detailed information (with current and next program
 *  information). The service periodically retrieves channel data, caches it, and notifies registered observers.
 */
@interface ChannelService : NSObject

/**
 *  Service singleton.
 */
@property (class, nonatomic, readonly) ChannelService *sharedService;

/**
 *  Register an observer to be notified of channel updates for a given media. The provided block is called when
 *  channel information is available.
 */
- (void)registerObserver:(id)observer forChannelUpdatesWithMedia:(SRGMedia *)media block:(ChannelServiceUpdateBlock)block;

/**
 *  Unregister the observer from channel notifications for the specified media.
 */
- (void)unregisterObserver:(id)observer forMedia:(SRGMedia *)media;

@end

NS_ASSUME_NONNULL_END
