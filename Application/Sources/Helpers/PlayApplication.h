//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Function to run a block of code only once during the life of the application (under optional conditions)
 *
 *  @param block  The block to be executed. The completion handler MUST be called after the code has been run. If
 *                the completion handler is called with success = YES, the block won't be run again
 *  @param key    The key to register block execution with
 *  @param object An optional object which must be associated with the key. If both do not match for some future
 *                call, the block will be called again
 */
OBJC_EXPORT void PlayApplicationRunOnce(void (NS_NOESCAPE ^block)(void (^completionHandler)(BOOL success)), NSString *key, id _Nullable object);

/**
 *  Function to get the object associated with a block having been run once, if any.
 *
 *  @param key The key used identifiying the block that was executed.
 */
OBJC_EXPORT _Nullable id PlayApplicationRunOnceObjectForKey(NSString *key);

NS_ASSUME_NONNULL_END
