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
 */
OBJC_EXPORT void PlayApplicationRunOnce(void (NS_NOESCAPE ^block)(void (^completionHandler)(BOOL success)), NSString *key);

NS_ASSUME_NONNULL_END
