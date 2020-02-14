//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "LiveMediaCollectionViewCell.h"

#import "AnalyticsConstants.h"
#import "ChannelService.h"
#import "NSBundle+PlaySRG.h"
#import "NSDateFormatter+PlaySRG.h"
#import "NSString+PlaySRG.h"
#import "PlayDurationFormatter.h"
#import "SRGChannel+PlaySRG.h"
#import "SRGMedia+PlaySRG.h"
#import "SRGProgram+PlaySRG.h"
#import "UIColor+PlaySRG.h"
#import "UIImageView+PlaySRG.h"
#import "UILabel+PlaySRG.h"

#import <libextobjc/libextobjc.h>
#import <SRGAnalytics/SRGAnalytics.h>
#import <SRGAppearance/SRGAppearance.h>

static NSMutableDictionary<NSString *, NSNumber *> *s_cachedHeights;

@interface LiveMediaCollectionViewCell ()

@property (nonatomic) SRGChannel *channel;

@property (nonatomic, weak) IBOutlet UIImageView *logoImageView;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *subtitleLabel;
@property (nonatomic, weak) IBOutlet UIImageView *thumbnailImageView;
@property (nonatomic, weak) IBOutlet UILabel *durationLabel;

@property (nonatomic, weak) IBOutlet UIView *blockingOverlayView;
@property (nonatomic, weak) IBOutlet UIImageView *blockingReasonImageView;

@property (nonatomic, weak) IBOutlet UIProgressView *progressView;

@end

@implementation LiveMediaCollectionViewCell

#pragma mark Class methods

+ (CGFloat)heightForMedia:(SRGMedia *)media withWidth:(CGFloat)width
{
    static NSDictionary<NSString *, NSNumber *> *s_textHeigths;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_textHeigths = @{ UIContentSizeCategoryExtraSmall : @63,
                           UIContentSizeCategorySmall : @65,
                           UIContentSizeCategoryMedium : @67,
                           UIContentSizeCategoryLarge : @70,
                           UIContentSizeCategoryExtraLarge : @75,
                           UIContentSizeCategoryExtraExtraLarge : @82,
                           UIContentSizeCategoryExtraExtraExtraLarge : @90,
                           UIContentSizeCategoryAccessibilityMedium : @90,
                           UIContentSizeCategoryAccessibilityLarge : @90,
                           UIContentSizeCategoryAccessibilityExtraLarge : @90,
                           UIContentSizeCategoryAccessibilityExtraExtraLarge : @90,
                           UIContentSizeCategoryAccessibilityExtraExtraExtraLarge : @90 };
    });
    
    NSString *contentSizeCategory = UIApplication.sharedApplication.preferredContentSizeCategory;
    CGFloat minTextHeight = s_textHeigths[contentSizeCategory].floatValue;
    return ceilf(width * 9.f / 16.f + minTextHeight);
}

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    UIColor *backgroundColor = UIColor.play_blackColor;
    self.backgroundColor = backgroundColor;
    
    self.progressView.progressTintColor = UIColor.play_progressRedColor;
    
    self.titleLabel.backgroundColor = backgroundColor;
    
    self.subtitleLabel.backgroundColor = backgroundColor;
    self.subtitleLabel.textColor = UIColor.play_lightGrayColor;
    
    self.thumbnailImageView.backgroundColor = UIColor.play_grayThumbnailImageViewBackgroundColor;
    self.thumbnailImageView.layer.cornerRadius = 4.f;
    self.thumbnailImageView.layer.masksToBounds = YES;
    
    self.durationLabel.backgroundColor = UIColor.play_blackDurationLabelBackgroundColor;
    
    self.blockingOverlayView.hidden = YES;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    [self unregisterChannelUpdatesWithMedia:self.media];
    self.media = nil;
    
    self.channel = nil;
    
    self.progressView.hidden = NO;
    self.progressView.progress = 1.f;
    
    self.blockingOverlayView.hidden = YES;
    
    [self.thumbnailImageView play_resetImage];
}

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    [super willMoveToWindow:newWindow];
    
    if (newWindow) {
        // Ensure proper state when the view is reinserted
        [self registerForChannelUpdatesWithMedia:self.media];
    }
    else {
        [self unregisterChannelUpdatesWithMedia:self.media];
    }
}

- (void)didMoveToWindow
{
    [super didMoveToWindow];
    
    [self play_registerForPreview];
}

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection
{
    [super traitCollectionDidChange:previousTraitCollection];
    
    [self play_registerForPreview];
}

#pragma mark Accessibility

- (BOOL)isAccessibilityElement
{
    return YES;
}

- (NSString *)accessibilityLabel
{
    if (self.media.contentType == SRGContentTypeLivestream) {
        NSMutableString *accessibilityLabel = [NSMutableString stringWithFormat:PlaySRGAccessibilityLocalizedString(@"%@ live", @"Live content label, with a channel title"), self.channel.title];
        if (self.channel.currentProgram) {
            [accessibilityLabel appendFormat:@", %@", self.channel.currentProgram.title];
        }
        return accessibilityLabel.copy;
    }
    else {
        NSMutableString *accessibilityLabel = self.media.title.mutableCopy;
        if (self.media.show.title && ! [self.media.title containsString:self.media.show.title]) {
            [accessibilityLabel appendFormat:@", %@", self.media.show.title];
        }
        return accessibilityLabel.copy;
    }
}

- (NSString *)accessibilityHint
{
    return PlaySRGAccessibilityLocalizedString(@"Plays the content.", @"Media cell hint");
}

#pragma mark Data

- (void)setMedia:(SRGMedia *)media
{
    [self unregisterChannelUpdatesWithMedia:self.media];
    
    _media = media;
    self.channel = media.channel;
    
    [self registerForChannelUpdatesWithMedia:media];
    [self reloadData];
}

#pragma mark Channel updates

- (void)registerForChannelUpdatesWithMedia:(SRGMedia *)media
{
    if (! media || media.contentType != SRGContentTypeLivestream) {
        return;
    }
    
    [ChannelService.sharedService registerObserver:self forChannelUpdatesWithMedia:media block:^(SRGChannel * _Nullable channel) {
        self.channel = channel ?: media.channel;
        [self reloadData];
    }];
}

- (void)unregisterChannelUpdatesWithMedia:(SRGMedia *)media
{
    if (! media || media.contentType != SRGContentTypeLivestream) {
        return;
    }
    
    [ChannelService.sharedService unregisterObserver:self forMedia:media];
}

#pragma mark UI

- (void)reloadData
{
    self.titleLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleBody];
    self.durationLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleCaption];
    
    SRGBlockingReason blockingReason = [self.media blockingReasonAtDate:NSDate.date];
    if (blockingReason == SRGBlockingReasonNone || blockingReason == SRGBlockingReasonStartDate) {
        self.blockingOverlayView.hidden = YES;
        
        self.titleLabel.textColor = UIColor.whiteColor;
    }
    else {
        self.blockingOverlayView.hidden = NO;
        self.blockingReasonImageView.image = [UIImage play_imageForBlockingReason:blockingReason];
        
        self.titleLabel.textColor = UIColor.play_lightGrayColor;
    }
    
    SRGAppearanceFontTextStyle subtitleTextStyle = SRGAppearanceFontTextStyleSubtitle;
    ImageScale imageScale = ImageScaleMedium;
    
    self.subtitleLabel.font = [UIFont srg_mediumFontWithTextStyle:subtitleTextStyle];
    
    [self.durationLabel play_displayDurationLabelForMediaMetadata:self.media];
    
    if (self.channel) {
        UIImage *logoImage = self.channel.play_banner22Image;
        self.logoImageView.image = logoImage;
        self.logoImageView.hidden = (logoImage == nil);
        
        SRGProgram *currentProgram = self.channel.currentProgram;
        if ([currentProgram play_containsDate:NSDate.date]) {
            self.titleLabel.text = currentProgram.title;
            self.subtitleLabel.text = [NSString stringWithFormat:@"%@ - %@", [NSDateFormatter.play_timeFormatter stringFromDate:currentProgram.startDate], [NSDateFormatter.play_timeFormatter stringFromDate:currentProgram.endDate]];
            
            float progress = [NSDate.date timeIntervalSinceDate:currentProgram.startDate] / ([currentProgram.endDate timeIntervalSinceDate:currentProgram.startDate]);
            self.progressView.progress = fmaxf(fminf(progress, 1.f), 0.f);
            
            [self.thumbnailImageView play_requestImageForObject:currentProgram withScale:imageScale type:SRGImageTypeDefault placeholder:ImagePlaceholderMedia unavailabilityHandler:^{
                [self.thumbnailImageView play_requestImageForObject:self.channel withScale:imageScale type:SRGImageTypeDefault placeholder:ImagePlaceholderMedia];
            }];
        }
        else {
            self.titleLabel.text = self.channel.title;
            self.subtitleLabel.text = NSLocalizedString(@"Currently", @"Text displayed on live cells when no program time information is available");
            self.progressView.progress = 1.f;
            
            [self.thumbnailImageView play_requestImageForObject:self.channel withScale:imageScale type:SRGImageTypeDefault placeholder:ImagePlaceholderMedia];
        }
    }
    else {
        self.titleLabel.text = self.media.title;
        self.logoImageView.hidden = YES;
        
        NSString *showTitle = self.media.show.title;
        if (showTitle && ! [self.media.title containsString:showTitle]) {
            NSMutableAttributedString *subtitle = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ - ", showTitle]
                                                                                         attributes:@{ NSFontAttributeName : [UIFont srg_mediumFontWithTextStyle:subtitleTextStyle] }];
            
            NSDateFormatter *dateFormatter = NSDateFormatter.play_relativeDateAndTimeFormatter;
            [subtitle appendAttributedString:[[NSAttributedString alloc] initWithString:[dateFormatter stringFromDate:self.media.date].play_localizedUppercaseFirstLetterString
                                                                             attributes:@{ NSFontAttributeName : [UIFont srg_lightFontWithTextStyle:subtitleTextStyle] }]];
            
            self.subtitleLabel.attributedText = subtitle.copy;
        }
        else {
            self.subtitleLabel.text = [NSDateFormatter.play_relativeDateAndTimeFormatter stringFromDate:self.media.date].play_localizedUppercaseFirstLetterString;
        }
        
        if (self.media.contentType == SRGContentTypeScheduledLivestream && self.media.startDate && self.media.endDate && [self.media timeAvailabilityAtDate:NSDate.date] == SRGTimeAvailabilityAvailable) {
            float progress = [NSDate.date timeIntervalSinceDate:self.media.startDate] / ([self.media.endDate timeIntervalSinceDate:self.media.startDate]);
            self.progressView.progress = fmaxf(fminf(progress, 1.f), 0.f);
        }
        else {
            self.progressView.hidden = YES;
        }
        
        [self.thumbnailImageView play_requestImageForObject:self.media withScale:imageScale type:SRGImageTypeDefault placeholder:ImagePlaceholderMedia];
    }
}

#pragma mark Previewing protocol

- (id)previewObject
{
    return self.media;
}

- (NSValue *)previewAnchorRect
{
    CGRect imageViewFrameInSelf = [self.thumbnailImageView convertRect:self.thumbnailImageView.bounds toView:self];
    return [NSValue valueWithCGRect:imageViewFrameInSelf];
}

@end
