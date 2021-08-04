//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "PlayAccessibilityFormatter.h"

#import "NSBundle+PlaySRG.h"

NSString *PlayAccessibilityRelativeDateAndTimeFromDate(NSDate *date)
{
    static NSDateFormatter *s_dateFormatter;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_dateFormatter = [[NSDateFormatter alloc] init];
        s_dateFormatter.dateStyle = NSDateFormatterLongStyle;
        s_dateFormatter.timeStyle = NSDateFormatterNoStyle;
        s_dateFormatter.doesRelativeDateFormatting = YES;
    });
    NSString *dateString = [s_dateFormatter stringFromDate:date];
    
    NSString *timeString = PlayAccessibilityTimeFromDate(date);
    return [NSString stringWithFormat:PlaySRGAccessibilityLocalizedString(@"%1$@ at %2$@", @"Date at time label to spell a date and time value."), dateString, timeString];
}

NSString *PlayAccessibilityTimeFromDate(NSDate *date)
{
    static NSDateComponentsFormatter *s_dateComponentsFormatter;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_dateComponentsFormatter = [[NSDateComponentsFormatter alloc] init];
        s_dateComponentsFormatter.allowedUnits = NSCalendarUnitHour | NSCalendarUnitMinute;
        s_dateComponentsFormatter.unitsStyle = NSDateComponentsFormatterUnitsStyleSpellOut;
        s_dateComponentsFormatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorNone;
    });
    
    NSDateComponents *components = [[NSCalendar currentCalendar] components:NSCalendarUnitHour | NSCalendarUnitMinute
                                                                   fromDate:date];
    return [s_dateComponentsFormatter stringFromDateComponents:components];
}
