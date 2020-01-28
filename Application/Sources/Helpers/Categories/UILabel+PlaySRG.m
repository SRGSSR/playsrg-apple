//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "UILabel+PlaySRG.h"

#import "NSBundle+PlaySRG.h"
#import "NSDateFormatter+PlaySRG.h"
#import "PlayDurationFormatter.h"
#import "SRGMedia+PlaySRG.h"
#import "UIColor+PlaySRG.h"

#import <SRGAppearance/SRGAppearance.h>

@interface UIFont (SRGLetterbox_Private)

+ (UIFont *)srg_awesomeFontWithTextStyle:(NSString *)textStyle;

@end

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
    self.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleBody];
    
    NSString *text = nil;
    NSDate *nowDate = NSDate.date;
    SRGTimeAvailability timeAvailability = [object timeAvailabilityAtDate:nowDate];
    if (timeAvailability == SRGTimeAvailabilityNotAvailableAnymore) {
        NSDate *endDate = object.endDate ?: [object.date dateByAddingTimeInterval:object.duration / 1000.];
        NSTimeInterval timeIntervalAfterEnd = [nowDate timeIntervalSinceDate:endDate];
        text = [NSString stringWithFormat:NSLocalizedString(@"Not available since %@", @"Explains that a content has expired (days or hours ago). Displayed in the media player view."), PlayShortFormattedDuration(timeIntervalAfterEnd)];
    }
    else if (timeAvailability == SRGTimeAvailabilityAvailable && object.endDate && object.contentType != SRGContentTypeScheduledLivestream && object.contentType != SRGContentTypeLivestream) {
        NSDateComponents *monthsDateComponents = [NSCalendar.currentCalendar components:NSCalendarUnitDay fromDate:nowDate toDate:object.endDate options:0];
        if (monthsDateComponents.day <= 30) {
            NSTimeInterval timeIntervalBeforeEnd = [object.endDate timeIntervalSinceDate:nowDate];
            text = [NSString stringWithFormat:NSLocalizedString(@"Still available for %@", @"Explains that a content is still online (for days or hours) but will expire. Displayed in the media player view."), PlayShortFormattedDuration(timeIntervalBeforeEnd)];
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

- (void)play_setSubtitlesAvailableBadge
{
    [self play_setMediaBadgeWithString:NSLocalizedString(@"ST", @"Subtitles short label on media cells")];
    self.accessibilityLabel = PlaySRGAccessibilityLocalizedString(@"Subtitled", @"Accessibility label for the subtitled badge");
}

- (void)play_setWebFirstBadge
{
    self.backgroundColor = UIColor.srg_blueColor;
    self.layer.cornerRadius = 2.f;
    self.layer.masksToBounds = YES;
    self.font = [UIFont srg_mediumFontWithSize:11.f];
    self.text = [NSString stringWithFormat:@"  %@  ", NSLocalizedString(@"WEB FIRST", @"Web first label on media cells")].uppercaseString;
}

#pragma mark Private

- (void)play_displayDurationLabelWithTimeAvailability:(SRGTimeAvailability)timeAvailability duration:(NSTimeInterval)duration isLivestreamOrScheduledLivestream:(BOOL)isLivestreamOrScheduledLivestream isLiveEvent:(BOOL)isLiveEvent
{
    self.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleCaption];
    
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
    self.layer.cornerRadius = isLive ? 3.f : 0.f;
    self.layer.masksToBounds = isLive ? YES : NO;
    
    NSMutableAttributedString *attributedText = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"  %@  ", name].uppercaseString
                                                                                       attributes:@{ NSFontAttributeName : [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleCaption],
                                                                                                     NSForegroundColorAttributeName : UIColor.whiteColor }];
    self.attributedText = attributedText.copy;
    self.hidden = NO;
}

- (void)play_setMediaBadgeWithString:(NSString *)string
{
    self.backgroundColor = UIColor.play_whiteBadgeColor;
    self.layer.cornerRadius = 2.f;
    self.layer.masksToBounds = YES;
    self.font = [UIFont srg_mediumFontWithSize:11.f];
    self.text = [NSString stringWithFormat:@"  %@  ", string].uppercaseString;
    self.textColor = UIColor.blackColor;
}

@end
