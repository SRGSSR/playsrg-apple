//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGDataProvider/SRGDataProvider.h>

NS_ASSUME_NONNULL_BEGIN

@interface SRGProgramComposition (PlaySRG)

/**
 *  Returns only programs matching in a given date range. The range can be open or possibly half-open.
 */
- (nullable NSArray<SRGProgram *> *)play_programsFromDate:(nullable NSDate *)fromDate toDate:(nullable NSDate *)toDate;

@end

NS_ASSUME_NONNULL_END
