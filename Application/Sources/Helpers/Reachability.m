//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Reachability.h"

BOOL ReachabilityBecameReachable(NSNotification *notification)
{
    FXReachabilityStatus previousStatus = [notification.userInfo[FXReachabilityNotificationPreviousStatusKey] integerValue];
    if (previousStatus != FXReachabilityStatusNotReachable) {
        return NO;
    }
    
    FXReachabilityStatus status = [notification.userInfo[FXReachabilityNotificationStatusKey] integerValue];
    return status == FXReachabilityStatusReachableViaWWAN || status == FXReachabilityStatusReachableViaWiFi;
}
