//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGLetterbox/SRGLetterbox.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Calculate the wall-clock date corresponding to a date provided in a controller reference frame.
 */
// TODO: Remove when offsets are not needed anymore
// TODO: Could be moved to Letterbox with documented rules (NSDate accepted or returned by the player = controller date
//       and users must convert them)
OBJC_EXPORT NSDate *PlayWallClockDate(NSDate *controllerDate, SRGLetterboxController *controller);
OBJC_EXPORT NSDate *PlayStreamDate(NSDate *wallClockDate, SRGLetterboxController *controller);

@interface SRGProgramComposition (PlaySRG)

/**
 *  Return the program at the specified date, if any.
 *
 *  @discussion `date` must be a wall-clock date, beware if it stems from a player and use `PlayWallClockDate` if
 *              this is the case.
 */
- (nullable SRGProgram *)play_programAtDate:(NSDate *)date;

/**
 *  Returns only programs matching in a given date range. The range can be open or possibly half-open. If media URNs
 *  are provided, only matching programs will be returned.
 *
 *  @discussion `date` must be a wall-clock date, beware if it stems from a player and use `PlayWallClockDate` if
 *              this is the case.
 */
- (nullable NSArray<SRGProgram *> *)play_programsFromDate:(nullable NSDate *)fromDate
                                                   toDate:(nullable NSDate *)toDate
                                            withMediaURNs:(nullable NSArray<NSString *> *)mediaURNs;

@end

NS_ASSUME_NONNULL_END
