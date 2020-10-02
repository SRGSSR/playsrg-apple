//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import SRGDataProviderModel;

NS_ASSUME_NONNULL_BEGIN

@interface SRGProgramComposition (PlaySRG)

/**
*  Return the program at the specified date, if any.
*/
- (nullable SRGProgram *)play_programAtDate:(NSDate *)date;

/**
 *  Returns only programs matching in a given date range. The range can be open or possibly half-open. If media URNs
 *  are provided, only matching programs will be returned.
 */
- (nullable NSArray<SRGProgram *> *)play_programsFromDate:(nullable NSDate *)fromDate
                                                   toDate:(nullable NSDate *)toDate
                                            withMediaURNs:(nullable NSArray<NSString *> *)mediaURNs;

@end

NS_ASSUME_NONNULL_END
