//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface NSSet (PlaySRG)

/**
 *  Return the receiver, from which objects from the specified set have been removed.
 */
- (NSSet *)play_setByRemovingObjectsInSet:(NSSet *)set;

@end

NS_ASSUME_NONNULL_END
