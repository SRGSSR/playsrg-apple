//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>
#import <SRGDataProvider/SRGDataProvider.h>

NS_ASSUME_NONNULL_BEGIN

// Types
typedef void (^ChannelProgramsUpdateBlock)(SRGProgramComposition * _Nullable programComposition);
typedef void (^ChannelSongsUpdateBlock)(NSArray<SRGSong *> * _Nullable songs);

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
 *  is available.
 */
- (nullable id)addObserver:(id)observer forProgramUpdatesWithChannel:(SRGChannel *)channel vendor:(SRGVendor)vendor livestreamUid:(NSString *)livestreamUid block:(ChannelProgramsUpdateBlock)block;
- (nullable id)addObserver:(id)observer forSongUpdatesWithChannel:(SRGChannel *)channel vendor:(SRGVendor)vendor block:(ChannelSongsUpdateBlock)block;

/**
 *  Remove the specified observer.
 */
- (void)removeObserver:(nullable id)observer;

@end

NS_ASSUME_NONNULL_END
