//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import Foundation;
@import SRGDataProviderModel;

NS_ASSUME_NONNULL_BEGIN

// Types
typedef void (^ChannelServiceUpdateBlock)(SRGProgramComposition * _Nullable programComposition);

/**
 *  Service responsible for retrieving and broadcasting channel detailed information (program information, mostly).
 *  The service periodically retrieves channel data, caches it, and notifies registered observers.
 */
@interface ChannelService : NSObject

/**
 *  Service singleton.
 */
@property (class, nonatomic, readonly) ChannelService *sharedService;

/**
 *  Register an observer to be notified of updates for a given channel. The provided block is called when channel information
 *  is available. An opaque handle to the observer is returned for unregistration purposes.
 */
- (id)addObserverForUpdatesWithChannel:(SRGChannel *)channel livestreamUid:(NSString *)livestreamUid block:(ChannelServiceUpdateBlock)block;

/**
 *  Remove the specified observer.
 */
- (void)removeObserver:(nullable id)observer;

@end

NS_ASSUME_NONNULL_END
