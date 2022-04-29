//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UILabel+PlaySRG.h"

#import "Layout.h"
#import "NSBundle+PlaySRG.h"
#import "NSDateFormatter+PlaySRG.h"
#import "NSString+PlaySRG.h"
#import "PlayAccessibilityFormatter.h"
#import "PlayDurationFormatter.h"
#import "SRGMedia+PlaySRG.h"
#import "UIColor+PlaySRG.h"

@import SRGAppearance;

static const NSInteger kDayNearExpirationThreshold = 3;

static NSString *LabelFormattedDuration(NSTimeInterval duration)
{
    if (duration >= 60. * 60. * 24.) {
        return PlayFormattedDays(duration);
    }
    else {
        return PlayFormattedHours(fmax(duration, 60. * 60.));
    }
}

@implementation UILabel (PlaySRG)

#pragma mark Public

- (void)play_displayDurationLabelForMediaMetadata:(id<SRGMediaMetadata>)mediaMetadata
{
    BOOL isLivestreamOrScheduledLivestream = (mediaMetadata.contentType == SRGContentTypeLivestream || mediaMetadata.contentType == SRGContentTypeScheduledLivestream);
    [self play_displayDurationLabelWithTimeAvailability:[mediaMetadata timeAvailabilityAtDate:NSDate.date]
                                               duration:mediaMetadata.duration
                      isLivestreamOrScheduledLivestream:isLivestreamOrScheduledLivestream
                                            isLiveEvent:PlayIsSwissTXTURN(mediaMetadata.URN)];
}

- (void)play_displayDateLabelForMediaMetadata:(id<SRGMediaMetadata>)mediaMetadata
{
    if (mediaMetadata.date) {
        NSString *text = [NSDateFormatter.play_dateAndTimeShortFormatter stringFromDate:mediaMetadata.date].play_localizedUppercaseFirstLetterString;
        NSString *accessibilityLabel = PlayAccessibilityDateAndTimeFromDate(mediaMetadata.date);
        
        NSDate *nowDate = NSDate.date;
        SRGTimeAvailability timeAvailability = [mediaMetadata timeAvailabilityAtDate:nowDate];
        if (timeAvailability == SRGTimeAvailabilityAvailable && mediaMetadata.endDate && mediaMetadata.contentType != SRGContentTypeScheduledLivestream && mediaMetadata.contentType != SRGContentTypeLivestream && mediaMetadata.contentType != SRGContentTypeTrailer) {
            NSDateComponents *remainingDateComponents = [NSCalendar.currentCalendar components:NSCalendarUnitDay fromDate:nowDate toDate:mediaMetadata.endDate options:0];
            if (remainingDateComponents.day > kDayNearExpirationThreshold) {
                NSString *expiration = [NSString stringWithFormat:NSLocalizedString(@"Available until %@", @"Availability until date, specified as parameter"), [NSDateFormatter.play_shortDateFormatter stringFromDate:mediaMetadata.endDate].play_localizedUppercaseFirstLetterString];
                // Unbreakable spaces before / after the separator
                text = [text stringByAppendingFormat:@" - %@", expiration];
                
                NSString *expirationAccessibilityLabel = [NSString stringWithFormat:NSLocalizedString(@"Available until %@", @"Availability until date, specified as parameter"), PlayAccessibilityDateFromDate(mediaMetadata.endDate)];
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

- (void)play_displayAvailabilityBadgeForMediaMetadata:(id<SRGMediaMetadata>)mediaMetadata
{
    self.layer.cornerRadius = LayoutStandardLabelCornerRadius;
    self.layer.masksToBounds = YES;
    self.font = [SRGFont fontWithStyle:SRGFontStyleLabel];
    self.textAlignment = NSTextAlignmentCenter;
    self.textColor = UIColor.whiteColor;
    
    NSString *text = nil;
    NSString *accessibilityLabel = nil;
    
    NSDate *nowDate = NSDate.date;
    SRGTimeAvailability timeAvailability = [mediaMetadata timeAvailabilityAtDate:nowDate];
    if (timeAvailability == SRGTimeAvailabilityNotAvailableAnymore) {
        self.backgroundColor = UIColor.srg_gray96Color;
        
        text = NSLocalizedString(@"Expired", @"Short label identifying content which has expired.");
    }
    else if (timeAvailability == SRGTimeAvailabilityAvailable && mediaMetadata.endDate && mediaMetadata.contentType != SRGContentTypeScheduledLivestream && mediaMetadata.contentType != SRGContentTypeLivestream && mediaMetadata.contentType != SRGContentTypeTrailer) {
        self.backgroundColor = UIColor.play_orangeColor;
        
        NSDateComponents *monthsDateComponents = [NSCalendar.currentCalendar components:NSCalendarUnitDay fromDate:nowDate toDate:mediaMetadata.endDate options:0];
        if (monthsDateComponents.day <= kDayNearExpirationThreshold) {
            NSTimeInterval timeIntervalBeforeEnd = [mediaMetadata.endDate timeIntervalSinceDate:nowDate];
            text = [NSString stringWithFormat:NSLocalizedString(@"%@ left", @"Short label displayed on a media expiring soon"), LabelFormattedDuration(timeIntervalBeforeEnd)];
            accessibilityLabel = [NSString stringWithFormat:NSLocalizedString(@"%@ left", @"Short label displayed on a media expiring soon"), LabelFormattedDuration(timeIntervalBeforeEnd)];
        }
    }
    
    if (text) {
        self.text = [NSString stringWithFormat:@"%@    ", text];
        self.accessibilityLabel = accessibilityLabel;
        self.hidden = NO;
    }
    else {
        self.text = nil;
        self.accessibilityLabel = nil;
        self.hidden = YES;
    }
}

- (void)play_setWebFirstBadge
{
    self.backgroundColor = UIColor.srg_blueColor;
    self.layer.cornerRadius = LayoutStandardLabelCornerRadius;
    self.layer.masksToBounds = YES;
    self.font = [SRGFont fontWithStyle:SRGFontStyleCaption];
    self.text = [NSString stringWithFormat:@"%@    ", NSLocalizedString(@"Web first", @"Web first label on media cells")];
    self.textAlignment = NSTextAlignmentCenter;
    self.textColor = UIColor.whiteColor;
}

#pragma mark Private

- (void)play_displayDurationLabelWithTimeAvailability:(SRGTimeAvailability)timeAvailability duration:(NSTimeInterval)duration isLivestreamOrScheduledLivestream:(BOOL)isLivestreamOrScheduledLivestream isLiveEvent:(BOOL)isLiveEvent
{
    self.font = [SRGFont fontWithStyle:SRGFontStyleCaption];
    
    if (timeAvailability == SRGTimeAvailabilityNotYetAvailable) {
        [self play_displayDurationLabelWithName:NSLocalizedString(@"Soon", @"Short label identifying content which will be available soon.") isLive:NO];
    }
    else if (timeAvailability == SRGTimeAvailabilityNotAvailableAnymore) {
        [self play_displayDurationLabelWithName:NSLocalizedString(@"Expired", @"Short label identifying content which has expired.") isLive:NO];
    }
    else if (isLivestreamOrScheduledLivestream) {
        [self play_displayDurationLabelWithName:NSLocalizedString(@"Live", @"Short label identifying a livestream. Display in uppercase.") isLive:YES];
    }
    else if (isLiveEvent) {
        [self play_displayDurationLabelWithName:NSLocalizedString(@"Replay", @"Short label identifying a replay sport event. Display in uppercase.") isLive:NO];
    }
    else if (duration != 0.) {
        NSString *durationString = PlayFormattedDuration(duration / 1000.);
        [self play_displayDurationLabelWithName:durationString isLive:NO];
    }
    else {
        self.text = nil;
        self.hidden = YES;
    }
}

- (void)play_displayDurationLabelWithName:(NSString *)name isLive:(BOOL)isLive
{
    self.backgroundColor = isLive ? UIColor.srg_lightRedColor : UIColor.play_blackDurationLabelBackgroundColor;
    self.layer.cornerRadius = LayoutStandardLabelCornerRadius;
    self.layer.masksToBounds = YES;
    
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"  %@  ", name].uppercaseString
                                                                                       attributes:@{ NSFontAttributeName : [SRGFont fontWithStyle:SRGFontStyleCaption],
                                                                                                     NSForegroundColorAttributeName : UIColor.whiteColor }];
    self.attributedText = attributedText.copy;
    self.hidden = NO;
}

@end
