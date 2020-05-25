//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>
#import <SRGDataProvider/SRGDataProvider.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Return the program at the specified date, if any.
 */
// TODO: Category method? Convenience method in data provider?
OBJC_EXPORT SRGProgram * _Nullable SRGChannelServiceProgramAtDate(SRGProgramComposition *programComposition, NSDate *date);

/**
 *  Notification sent when channels have been updated.
 */
OBJC_EXPORT NSString * const ChannelServiceDidUpdateChannelsNotification;

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
 *  is available.
 */
- (id)addObserver:(id)observer forUpdatesWithChannel:(SRGChannel *)channel vendor:(SRGVendor)vendor livestreamUid:(NSString *)livestreamUid block:(ChannelServiceUpdateBlock)block;

/**
 *  Remove the specified observer.
 */
- (void)removeObserver:(nullable id)observer;

@end

NS_ASSUME_NONNULL_END
