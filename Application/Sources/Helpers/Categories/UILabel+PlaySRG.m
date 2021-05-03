//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UILabel+PlaySRG.h"

#import "Layout.h"
#import "NSBundle+PlaySRG.h"
#import "NSDateFormatter+PlaySRG.h"
#import "PlayDurationFormatter.h"
#import "SRGMedia+PlaySRG.h"
#import "UIColor+PlaySRG.h"

@import SRGAppearance;

static NSString *LabelFormattedDuration(NSTimeInterval duration)
{
    if (duration >= 60. * 60. * 24.) {
        static NSDateComponentsFormatter *s_dateComponentsFormatter;
        static dispatch_once_t s_onceToken;
        dispatch_once(&s_onceToken, ^{
            s_dateComponentsFormatter = [[NSDateComponentsFormatter alloc] init];
            s_dateComponentsFormatter.allowedUnits = NSCalendarUnitDay;
            s_dateComponentsFormatter.unitsStyle = NSDateComponentsFormatterUnitsStyleFull;
        });
        return [s_dateComponentsFormatter stringFromTimeInterval:duration];
    }
    else if (duration >= 60. * 60.) {
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

@implementation UILabel (PlaySRG)

#pragma mark Public

- (void)play_displayDurationLabelForMediaMetadata:(id<SRGMediaMetadata>)object
{
    BOOL isLivestreamOrScheduledLivestream = (object.contentType == SRGContentTypeLivestream || object.contentType == SRGContentTypeScheduledLivestream);
    [self play_displayDurationLabelWithTimeAvailability:[object timeAvailabilityAtDate:NSDate.date]
                                               duration:object.duration
                      isLivestreamOrScheduledLivestream:isLivestreamOrScheduledLivestream
                                            isLiveEvent:PlayIsSwissTXTURN(object.URN)];
}

- (void)play_displayAvailabilityLabelForMediaMetadata:(id<SRGMediaMetadata>)object
{
    self.font = [SRGFont fontWithStyle:SRGFontStyleBody];
    
    NSString *text = nil;
    NSDate *nowDate = NSDate.date;
    SRGTimeAvailability timeAvailability = [object timeAvailabilityAtDate:nowDate];
    if (timeAvailability == SRGTimeAvailabilityNotAvailableAnymore) {
        NSDate *endDate = object.endDate ?: [object.date dateByAddingTimeInterval:object.duration / 1000.];
        NSTimeInterval timeIntervalAfterEnd = [nowDate timeIntervalSinceDate:endDate];
        text = [NSString stringWithFormat:NSLocalizedString(@"Not available since %@", @"Explains that a content has expired (days or hours ago). Displayed in the media player view."), LabelFormattedDuration(timeIntervalAfterEnd)];
    }
    else if (timeAvailability == SRGTimeAvailabilityAvailable && object.endDate && object.contentType != SRGContentTypeScheduledLivestream && object.contentType != SRGContentTypeLivestream && object.contentType != SRGContentTypeTrailer) {
        NSDateComponents *monthsDateComponents = [NSCalendar.currentCalendar components:NSCalendarUnitDay fromDate:nowDate toDate:object.endDate options:0];
        if (monthsDateComponents.day <= 30) {
            NSTimeInterval timeIntervalBeforeEnd = [object.endDate timeIntervalSinceDate:nowDate];
            text = [NSString stringWithFormat:NSLocalizedString(@"Still available for %@", @"Explains that a content is still online (for days or hours) but will expire. Displayed in the media player view."), LabelFormattedDuration(timeIntervalBeforeEnd)];
        }
    }
    
    if (text) {
        self.text = text;
        self.hidden = NO;
    }
    else {
        self.text = nil;
        self.hidden = YES;
    }
}

- (void)play_setWebFirstBadge
{
    self.backgroundColor = UIColor.srg_blueColor;
    self.layer.cornerRadius = LayoutStandardLabelCornerRadius;
    self.layer.masksToBounds = YES;
    self.font = [SRGFont fontWithStyle:SRGFontStyleCaption];
    self.text = [NSString stringWithFormat:@"  %@  ", NSLocalizedString(@"Web first", @"Web first label on media cells")].uppercaseString;
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
    self.backgroundColor = isLive ? UIColor.play_liveRedColor : UIColor.play_blackDurationLabelBackgroundColor;
    self.layer.cornerRadius = LayoutStandardLabelCornerRadius;
    self.layer.masksToBounds = YES;
    
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"  %@  ", name].uppercaseString
                                                                                       attributes:@{ NSFontAttributeName : [SRGFont fontWithStyle:SRGFontStyleCaption],
                                                                                                     NSForegroundColorAttributeName : UIColor.whiteColor }];
    self.attributedText = attributedText.copy;
    self.hidden = NO;
}

@end
