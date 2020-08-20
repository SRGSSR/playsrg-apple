//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/**
 *  A timer class, similar to `NSTimer`, but only active in foreground (the usual `NSTimer` can continue in background
 *  if background audio is active).
 */
@interface ForegroundTimer : NSObject

/**
 *  Convenience constructor.
 */
+ (ForegroundTimer *)timerWithTimeInterval:(NSTimeInterval)interval
                                   repeats:(BOOL)repeats
                                     block:(void (^)(ForegroundTimer *timer))block;

/**
 *  Create a timer.
 *
 *  @param interval   The interval at which the block must be executed.
 *  @param repeats    Whether the timer repeats until invalidated.
 *  @param block      The block to be executed.
 */
- (instancetype)initWithTimeInterval:(NSTimeInterval)interval
                             repeats:(BOOL)repeats
                               block:(void (^)(ForegroundTimer *timer))block NS_DESIGNATED_INITIALIZER;

/**
 *  Invalidate the timer (which does not fire anymore afterwards).
 */
- (void)invalidate;

@end

@interface ForegroundTimer (Unavailable)

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
