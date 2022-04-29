//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NSDateFormatter+PlaySRG.h"

@import SRGDataProviderModel;

@implementation NSDateFormatter (PlaySRG)

+ (NSDateFormatter *)play_timeFormatter
{
    static dispatch_once_t s_onceToken;
    static NSDateFormatter *s_dateFormatter;
    dispatch_once(&s_onceToken, ^{
        s_dateFormatter = [[NSDateFormatter alloc] init];
        s_dateFormatter.timeZone = NSTimeZone.srg_defaultTimeZone;
        s_dateFormatter.dateStyle = NSDateFormatterNoStyle;
        s_dateFormatter.timeStyle = NSDateFormatterShortStyle;
    });
    return s_dateFormatter;
}

+ (NSDateFormatter *)play_shortDateFormatter
{
    static dispatch_once_t s_onceToken;
    static NSDateFormatter *s_dateFormatter;
    dispatch_once(&s_onceToken, ^{
        s_dateFormatter = [[NSDateFormatter alloc] init];
        s_dateFormatter.timeZone = NSTimeZone.srg_defaultTimeZone;
        s_dateFormatter.dateStyle = NSDateFormatterShortStyle;
        s_dateFormatter.timeStyle = NSDateFormatterNoStyle;
    });
    return s_dateFormatter;
}

+ (NSDateFormatter *)play_shortDateAndTimeFormatter
{
    static NSDateFormatter *s_dateFormatter;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_dateFormatter = [[NSDateFormatter alloc] init];
        s_dateFormatter.timeZone = NSTimeZone.srg_defaultTimeZone;
        s_dateFormatter.dateStyle = NSDateFormatterShortStyle;
        s_dateFormatter.timeStyle = NSDateFormatterShortStyle;
    });
    return s_dateFormatter;
}

+ (NSDateFormatter *)play_relativeDateAndTimeFormatter
{
    static NSDateFormatter *s_dateFormatter;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_dateFormatter = [[NSDateFormatter alloc] init];
        s_dateFormatter.timeZone = NSTimeZone.srg_defaultTimeZone;
        s_dateFormatter.dateStyle = NSDateFormatterLongStyle;
        s_dateFormatter.timeStyle = NSDateFormatterShortStyle;
        s_dateFormatter.doesRelativeDateFormatting = YES;
    });
    return s_dateFormatter;
}

+ (NSDateFormatter *)play_relativeDateFormatter
{
    static NSDateFormatter *s_dateFormatter;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_dateFormatter = [[NSDateFormatter alloc] init];
        s_dateFormatter.timeZone = NSTimeZone.srg_defaultTimeZone;
        s_dateFormatter.dateStyle = NSDateFormatterLongStyle;
        s_dateFormatter.timeStyle = NSDateFormatterNoStyle;
        s_dateFormatter.doesRelativeDateFormatting = YES;
    });
    return s_dateFormatter;
}

+ (NSDateFormatter *)play_relativeFullDateFormatter
{
    static NSDateFormatter *s_dateFormatter;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_dateFormatter = [[NSDateFormatter alloc] init];
        s_dateFormatter.timeZone = NSTimeZone.srg_defaultTimeZone;
        s_dateFormatter.dateStyle = NSDateFormatterFullStyle;
        s_dateFormatter.timeStyle = NSDateFormatterNoStyle;
        s_dateFormatter.doesRelativeDateFormatting = YES;
    });
    return s_dateFormatter;
}

+ (NSDateFormatter *)play_relativeShortDateFormatter
{
    static NSDateFormatter *s_dateFormatter;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_dateFormatter = [[NSDateFormatter alloc] init];
        s_dateFormatter.timeZone = NSTimeZone.srg_defaultTimeZone;
        s_dateFormatter.dateStyle = NSDateFormatterShortStyle;
        s_dateFormatter.timeStyle = NSDateFormatterNoStyle;
        s_dateFormatter.doesRelativeDateFormatting = YES;
    });
    return s_dateFormatter;
}

+ (NSDateFormatter *)play_URLOptionDateFormatter
{
    static NSDateFormatter *s_dateFormatter;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_dateFormatter = [[NSDateFormatter alloc] init];
        s_dateFormatter.timeZone = NSTimeZone.srg_defaultTimeZone;
        s_dateFormatter.dateFormat = @"yyyy-MM-dd";
    });
    return s_dateFormatter;
}

 + (NSDateFormatter *)play_rfc3339DateFormatter
{
    static NSDateFormatter *s_dateFormatter;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_dateFormatter = [[NSDateFormatter alloc] init];
        s_dateFormatter.locale = [NSLocale localeWithLocaleIdentifier:@"en_US_POSIX"];
        s_dateFormatter.timeZone = NSTimeZone.srg_defaultTimeZone;
        s_dateFormatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZZZZZ";
    });
    return s_dateFormatter;
}

@end
