//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NSString+PlaySRG.h"

@implementation NSString (PlaySRG)

#pragma

#pragma mark Class methods

+ (NSString *)play_relativeTimeAccessibilityStringFromDate:(NSDate *)date
{
    NSDateComponents * hourComponents = [[NSCalendar currentCalendar] components:NSCalendarUnitHour | NSCalendarUnitMinute
                                                                        fromDate:date];
    
    return [NSDateComponentsFormatter localizedStringFromDateComponents:hourComponents
                                                             unitsStyle:NSDateComponentsFormatterUnitsStyleSpellOut];
}

#pragma mark Getters and setters

- (NSString *)play_localizedUppercaseFirstLetterString
{
    NSString *firstUppercaseCharacter = [self substringToIndex:1].localizedUppercaseString;
    return [firstUppercaseCharacter stringByAppendingString:[self substringFromIndex:1]];
}

@end
