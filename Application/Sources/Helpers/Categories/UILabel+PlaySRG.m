//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UILabel+PlaySRG.h"

#import "Layout.h"
#import "NSBundle+PlaySRG.h"
#import "NSString+PlaySRG.h"
#import "PlayAccessibilityFormatter.h"
#import "PlayDurationFormatter.h"
#import "PlaySRG-Swift.h"

@import SRGAppearance;

static const NSInteger kDayNearExpirationThreshold = 3;

static NSString *LabelFormattedDuration(NSTimeInterval duration)
{
    if (duration >= 60. * 60. * 24.) {
        return PlayFormattedDays(duration);
    }
    else if (duration >= 60. * 60.) {
        return PlayFormattedHours(duration);
    }
    else {
        return PlayFormattedMinutes(duration);
    }
}

@implementation UILabel (PlaySRG)

#pragma mark Public

- (void)play_displayDateLabelForMedia:(SRGMedia *)media
{
    NSDate *nowDate = NSDate.date;
    SRGTimeAvailability timeAvailability = [media timeAvailabilityAtDate:nowDate];
    
    if (media.date
        && timeAvailability != SRGTimeAvailabilityNotYetAvailable
        && media.contentType != SRGContentTypeLivestream
        && !(media.contentType == SRGContentTypeScheduledLivestream && timeAvailability == SRGTimeAvailabilityAvailable)) {
        NSString *text = [NSDateFormatter.play_shortDateAndTime stringFromDate:media.date].play_localizedUppercaseFirstLetterString;
        NSString *accessibilityLabel = PlayAccessibilityDateAndTimeFromDate(media.date);
        
        BOOL isWebFirst = [media.date compare:nowDate] == NSOrderedDescending && timeAvailability == SRGTimeAvailabilityAvailable && media.contentType == SRGContentTypeEpisode;
        
        if (isWebFirst) {
            NSString *webFirst = NSLocalizedString(@"In advance", @"Short text replacing date for a web first content.");
            
            // Unbreakable spaces before / after the separator
            text = webFirst;
            
            accessibilityLabel = webFirst;
        }
        
        if (timeAvailability == SRGTimeAvailabilityAvailable && media.endDate
                && media.contentType != SRGContentTypeScheduledLivestream && media.contentType != SRGContentTypeLivestream && media.contentType != SRGContentTypeTrailer) {
            NSDateComponents *remainingDateComponents = [NSCalendar.srg_defaultCalendar components:NSCalendarUnitDay fromDate:nowDate toDate:media.endDate options:0];
            if (remainingDateComponents.day > kDayNearExpirationThreshold) {
                NSString *expiration = [NSString stringWithFormat:NSLocalizedString(@"Available until %@", @"Availability until date, specified as parameter"), [NSDateFormatter.play_shortDate stringFromDate:media.endDate].play_localizedUppercaseFirstLetterString];
                // Unbreakable spaces before / after the separator
                text = [text stringByAppendingFormat:@" · %@", expiration];
                
                NSString *expirationAccessibilityLabel = [NSString stringWithFormat:NSLocalizedString(@"Available until %@", @"Availability until date, specified as parameter"), PlayAccessibilityDateFromDate(media.endDate)];
                accessibilityLabel = [accessibilityLabel stringByAppendingFormat:@", %@", expirationAccessibilityLabel];
            }
        }
        
        self.text = text;
        self.accessibilityLabel = accessibilityLabel;
    }
    else {
        self.text = nil;
        self.accessibilityLabel = nil;
    }
}

- (void)play_displayAvailabilityBadgeForMedia:(SRGMedia *)media
{
    self.layer.cornerRadius = LayoutStandardLabelCornerRadius;
    self.layer.masksToBounds = YES;
    self.font = [SRGFont fontWithStyle:SRGFontStyleLabel];
    self.textAlignment = NSTextAlignmentCenter;
    self.textColor = UIColor.whiteColor;
    
    NSString *text = nil;
    
    NSDate *nowDate = NSDate.date;
    SRGTimeAvailability timeAvailability = [media timeAvailabilityAtDate:nowDate];
    if (timeAvailability == SRGTimeAvailabilityNotYetAvailable) {
        self.backgroundColor = UIColor.play_black80a;
        
        NSDate *startDate = media.startDate != nil ? media.startDate : media.date;
        text = [[NSDateFormatter play_relativeShortDateAndTime] stringFromDate:startDate].play_localizedUppercaseFirstLetterString;
    }
    else if (timeAvailability == SRGTimeAvailabilityNotAvailableAnymore) {
        self.backgroundColor = UIColor.srg_gray96Color;
        
        text = NSLocalizedString(@"Expired", @"Short label identifying content which has expired.");
    }
    else if (timeAvailability == SRGTimeAvailabilityAvailable && media.endDate
             && (media.contentType == SRGContentTypeEpisode || media.contentType == SRGContentTypeClip)) {
        self.backgroundColor = UIColor.play_orange;
        
        NSDateComponents *monthsDateComponents = [NSCalendar.srg_defaultCalendar components:NSCalendarUnitDay fromDate:nowDate toDate:media.endDate options:0];
        if (monthsDateComponents.day <= kDayNearExpirationThreshold) {
            NSTimeInterval timeIntervalBeforeEnd = [media.endDate timeIntervalSinceDate:nowDate];
            text = [NSString stringWithFormat:NSLocalizedString(@"%@ left", @"Short label displayed on a media expiring soon"), LabelFormattedDuration(timeIntervalBeforeEnd)];
        }
    }
    else if (media.contentType == SRGContentTypeLivestream
             || (media.contentType == SRGContentTypeScheduledLivestream && timeAvailability == SRGTimeAvailabilityAvailable)) {
        self.backgroundColor = UIColor.srg_lightRedColor;
        
        text = NSLocalizedString(@"Live", @"Short label identifying a livestream. Display in uppercase.").uppercaseString;
    }
    
    if (text) {
        self.text = [NSString stringWithFormat:@"%@    ", text];
        self.hidden = NO;
    }
    else {
        self.text = nil;
        self.hidden = YES;
    }
}

- (void)play_setWebFirstBadge
{
    self.backgroundColor = UIColor.srg_darkRedColor;
    self.layer.cornerRadius = LayoutStandardLabelCornerRadius;
    self.layer.masksToBounds = YES;
    self.font = [SRGFont fontWithStyle:SRGFontStyleCaption];
    self.text = [NSString stringWithFormat:@"%@    ", NSLocalizedString(@"Web first", @"Short label identifying a web first content.")];
    self.textAlignment = NSTextAlignmentCenter;
    self.textColor = UIColor.whiteColor;
}

@end
