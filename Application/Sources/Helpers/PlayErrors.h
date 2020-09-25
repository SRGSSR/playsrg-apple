//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Common error codes
 */
typedef NS_ENUM(NSInteger, PlayErrorCode) {
    PlayErrorCodeNotFound,                  // Not found or is not available.
    PlayErrorCodeNotSupported,              // Not supported (e.g. technically).
    PlayErrorCodeForbidden,                 // Access is forbidden.
    PlayErrorCodeReceiver,                  // A problem occurred with the receiver.
    PlayErrorCodeCancelled,                 // An operation was cancelled.
    PlayErrorCodeFailed                     // An operation failed.
};

/**
 *  Common domain for Play application errors
 */
OBJC_EXPORT NSString * const PlayErrorDomain;

NS_ASSUME_NONNULL_END
