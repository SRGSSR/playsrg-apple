//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface NSFileManager (PlaySRG)

@property (class, nonatomic, readonly) NSURL *play_applicationGroupContainerURL;

/**
 *  The business unit short identifier (e.g. `srf`), read from the `BusinessUnitIdentifier` Info.plist key.
 */
@property (class, nonatomic, readonly, nullable) NSString *play_businessUnitIdentifier;

/**
 *  The per-business-unit directory inside the shared App Group container (`<shared group>/<bu>`).
 *  Returns `nil` (without asserting) when the shared group is unavailable, so callers can no-op safely.
 */
@property (class, nonatomic, readonly, nullable) NSURL *play_sharedBusinessUnitContainerURL;

@end

NS_ASSUME_NONNULL_END
