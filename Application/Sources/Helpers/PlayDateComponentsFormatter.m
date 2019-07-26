//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "PlayDateComponentsFormatter.h"

#import "NSBundle+PlaySRG.h"
#import "NSDateFormatter+PlaySRG.h"

NSString *PlayFormattedDuration(NSTimeInterval duration)
{
    if (duration <= 60. * 60.) {
        static NSDateComponentsFormatter *s_dateComponentsFormatter;
        static dispatch_once_t s_onceToken;
        dispatch_once(&s_onceToken, ^{
            s_dateComponentsFormatter = [[NSDateComponentsFormatter alloc] init];
            s_dateComponentsFormatter.allowedUnits = NSCalendarUnitSecond | NSCalendarUnitMinute;
            s_dateComponentsFormatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorPad;
        });
        return [s_dateComponentsFormatter stringFromTimeInterval:duration];
    }
    else {
        static NSDateComponentsFormatter *s_dateComponentsFormatter;
        static dispatch_once_t s_onceToken;
        dispatch_once(&s_onceToken, ^{
            s_dateComponentsFormatter = [[NSDateComponentsFormatter alloc] init];
            s_dateComponentsFormatter.allowedUnits = NSCalendarUnitSecond | NSCalendarUnitMinute | NSCalendarUnitHour;
            s_dateComponentsFormatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorPad;
        });
        return [s_dateComponentsFormatter stringFromTimeInterval:duration];
    }
}

NSString *PlayHumanReadableFormattedDuration(NSTimeInterval duration)
{
    if (duration <= 60. * 60.) {
        static NSDateComponentsFormatter *s_dateComponentsFormatter;
        static dispatch_once_t s_onceToken;
        dispatch_once(&s_onceToken, ^{
            s_dateComponentsFormatter = [[NSDateComponentsFormatter alloc] init];
            s_dateComponentsFormatter.allowedUnits = NSCalendarUnitSecond | NSCalendarUnitMinute;
            s_dateComponentsFormatter.unitsStyle = NSDateComponentsFormatterUnitsStyleAbbreviated;
            s_dateComponentsFormatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorPad;
        });
        return [s_dateComponentsFormatter stringFromTimeInterval:duration];
    }
    else {
        static NSDateComponentsFormatter *s_dateComponentsFormatter;
        static dispatch_once_t s_onceToken;
        dispatch_once(&s_onceToken, ^{
            s_dateComponentsFormatter = [[NSDateComponentsFormatter alloc] init];
            s_dateComponentsFormatter.allowedUnits = NSCalendarUnitSecond | NSCalendarUnitMinute | NSCalendarUnitHour;
            s_dateComponentsFormatter.unitsStyle = NSDateComponentsFormatterUnitsStyleAbbreviated;
            s_dateComponentsFormatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorPad;
        });
        return [s_dateComponentsFormatter stringFromTimeInterval:duration];
    }
}

NSString *PlayShortFormattedDuration(NSTimeInterval duration)
{
    // Display days if > 24 hours
    if (duration > 60. * 60. * 24.) {
        static NSDateComponentsFormatter *s_dateComponentsFormatter;
        static dispatch_once_t s_onceToken;
        dispatch_once(&s_onceToken, ^{
            s_dateComponentsFormatter = [[NSDateComponentsFormatter alloc] init];
            s_dateComponentsFormatter.allowedUnits = NSCalendarUnitDay;
            s_dateComponentsFormatter.unitsStyle = NSDateComponentsFormatterUnitsStyleFull;
        });
        return [s_dateComponentsFormatter stringFromTimeInterval:duration];
    }
    // Display hours if > 1 hour
    else if (duration > 60. * 60.) {
        static NSDateComponentsFormatter *s_dateComponentsFormatter;
        static dispatch_once_t s_onceToken;
        dispatch_once(&s_onceToken, ^{
            s_dateComponentsFormatter = [[NSDateComponentsFormatter alloc] init];
            s_dateComponentsFormatter.allowedUnits = NSCalendarUnitHour;
            s_dateComponentsFormatter.unitsStyle = NSDateComponentsFormatterUnitsStyleFull;
        });
        return [s_dateComponentsFormatter stringFromTimeInterval:duration];
    }
    else {
        return NSLocalizedString(@"less than 1 hour", @"Explains that a content has expired, will expire or will be available in less than one hour. Displayed in the media player view.");
    }
}

NSString *PlayRelativeDateAndTimeAccessibilityDate(NSDate *date)
{
    NSString *dateString = [NSDateFormatter.play_relativeDateAccessibilityFormatter stringFromDate:date];
    NSString *timeString = PlayRelativeTimeAccessibilityDate(date);
    
    return [NSString stringWithFormat:PlaySRGAccessibilityLocalizedString(@"%@ at %@", @"Date at time label to spell a date and time value."), dateString, timeString];
}

NSString *PlayRelativeTimeAccessibilityDate(NSDate *date)
{
    static NSDateComponentsFormatter *s_dateComponentsFormatter;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_dateComponentsFormatter = [[NSDateComponentsFormatter alloc] init];
        s_dateComponentsFormatter.allowedUnits = NSCalendarUnitHour | NSCalendarUnitMinute;
        s_dateComponentsFormatter.unitsStyle = NSDateComponentsFormatterUnitsStyleSpellOut;
    });
    
    NSDateComponents * components = [[NSCalendar currentCalendar] components:NSCalendarUnitHour | NSCalendarUnitMinute
                                                                    fromDate:date];
    
    return [s_dateComponentsFormatter stringFromDateComponents:components];
}
