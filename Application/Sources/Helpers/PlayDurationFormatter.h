//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Formats a duration in a standard form, e.g. for use in duration labels.
 */
OBJC_EXPORT NSString *PlayFormattedDuration(NSTimeInterval duration);

/**
 *  Formats a duration in a human readable way, with explicit hours, minutes and seconds.
 */
OBJC_EXPORT NSString *PlayHumanReadableFormattedDuration(NSTimeInterval duration);

NS_ASSUME_NONNULL_END
