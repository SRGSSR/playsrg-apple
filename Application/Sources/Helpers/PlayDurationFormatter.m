//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "PlayDurationFormatter.h"

NSString *PlayFormattedMinutes(NSTimeInterval duration)
{
    static NSDateComponentsFormatter *s_dateComponentsFormatter;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_dateComponentsFormatter = [[NSDateComponentsFormatter alloc] init];
        s_dateComponentsFormatter.allowedUnits = NSCalendarUnitMinute;
        s_dateComponentsFormatter.unitsStyle = NSDateComponentsFormatterUnitsStyleFull;
        s_dateComponentsFormatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorPad;
    });
    return [s_dateComponentsFormatter stringFromTimeInterval:fmax(60., duration)];
}

NSString *PlayFormattedHours(NSTimeInterval duration)
{
    static NSDateComponentsFormatter *s_dateComponentsFormatter;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_dateComponentsFormatter = [[NSDateComponentsFormatter alloc] init];
        s_dateComponentsFormatter.allowedUnits = NSCalendarUnitHour;
        s_dateComponentsFormatter.unitsStyle = NSDateComponentsFormatterUnitsStyleFull;
        s_dateComponentsFormatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorPad;
    });
    return [s_dateComponentsFormatter stringFromTimeInterval:fmax(60. * 60., duration)];
}

NSString *PlayFormattedDays(NSTimeInterval duration)
{
    static NSDateComponentsFormatter *s_dateComponentsFormatter;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_dateComponentsFormatter = [[NSDateComponentsFormatter alloc] init];
        s_dateComponentsFormatter.allowedUnits = NSCalendarUnitDay;
        s_dateComponentsFormatter.unitsStyle = NSDateComponentsFormatterUnitsStyleFull;
        s_dateComponentsFormatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorPad;
    });
    return [s_dateComponentsFormatter stringFromTimeInterval:fmax(24 * 60. * 60., duration)];
}

NSString *PlayShortFormattedMinutes(NSTimeInterval duration)
{
    static NSDateComponentsFormatter *s_dateComponentsFormatter;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_dateComponentsFormatter = [[NSDateComponentsFormatter alloc] init];
        s_dateComponentsFormatter.allowedUnits = NSCalendarUnitMinute;
        s_dateComponentsFormatter.unitsStyle = NSDateComponentsFormatterUnitsStyleShort;
        s_dateComponentsFormatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorPad;
    });
    return [s_dateComponentsFormatter stringFromTimeInterval:fmax(60., duration)];
}

NSString *PlayShortFormattedHours(NSTimeInterval duration)
{
    static NSDateComponentsFormatter *s_dateComponentsFormatter;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_dateComponentsFormatter = [[NSDateComponentsFormatter alloc] init];
        s_dateComponentsFormatter.allowedUnits = NSCalendarUnitHour;
        s_dateComponentsFormatter.unitsStyle = NSDateComponentsFormatterUnitsStyleShort;
        s_dateComponentsFormatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorPad;
    });
    return [s_dateComponentsFormatter stringFromTimeInterval:fmax(60. * 60., duration)];
}

NSString *PlayShortFormattedDays(NSTimeInterval duration)
{
    static NSDateComponentsFormatter *s_dateComponentsFormatter;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_dateComponentsFormatter = [[NSDateComponentsFormatter alloc] init];
        s_dateComponentsFormatter.allowedUnits = NSCalendarUnitDay;
        s_dateComponentsFormatter.unitsStyle = NSDateComponentsFormatterUnitsStyleShort;
        s_dateComponentsFormatter.zeroFormattingBehavior = NSDateComponentsFormatterZeroFormattingBehaviorPad;
    });
    return [s_dateComponentsFormatter stringFromTimeInterval:fmax(24 * 60. * 60., duration)];
}

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

NSString *PlayRemainingTimeFormattedDuration(NSTimeInterval duration)
{
    if (duration >= 60. * 60.) {
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
        static NSDateComponentsFormatter *s_dateComponentsFormatter;
        static dispatch_once_t s_onceToken;
        dispatch_once(&s_onceToken, ^{
            s_dateComponentsFormatter = [[NSDateComponentsFormatter alloc] init];
            s_dateComponentsFormatter.allowedUnits = NSCalendarUnitMinute;
            s_dateComponentsFormatter.unitsStyle = NSDateComponentsFormatterUnitsStyleFull;
        });
        return [s_dateComponentsFormatter stringFromTimeInterval:fmax(60., duration)];
    }
}
