//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import FXReachability;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Check from an `FXRechability` notificaton whether the network became available again (testing `reachable`
 *  yields false positives on application startup, when the status usually changes from unknown to reachable).
 */
OBJC_EXPORT BOOL ReachabilityBecameReachable(NSNotification *notification);

NS_ASSUME_NONNULL_END
