//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "HomeLiveMediaCollectionViewCell.h"

#import "AnalyticsConstants.h"
#import "ApplicationSettings.h"
#import "ChannelService.h"
#import "Layout.h"
#import "NSBundle+PlaySRG.h"
#import "NSDateFormatter+PlaySRG.h"
#import "NSString+PlaySRG.h"
#import "PlayDurationFormatter.h"
#import "SRGChannel+PlaySRG.h"
#import "SRGMedia+PlaySRG.h"
#import "SRGProgram+PlaySRG.h"
#import "SRGProgramComposition+PlaySRG.h"
#import "UIColor+PlaySRG.h"
#import "UIImageView+PlaySRG.h"

#import <libextobjc/libextobjc.h>
#import <SRGAnalytics/SRGAnalytics.h>
#import <SRGAppearance/SRGAppearance.h>

static NSString *RemainingTimeFormattedDuration(NSTimeInterval duration)
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
        // Minimum is 1 minute
        return [s_dateComponentsFormatter stringFromTimeInterval:fmax(60., duration)];
    }
}

@interface HomeLiveMediaCollectionViewCell ()

@property (nonatomic) SRGProgramComposition *programComposition;

@property (nonatomic, weak) IBOutlet UIView *mediaView;
@property (nonatomic, weak) IBOutlet UIView *placeholderView;
@property (nonatomic, weak) IBOutlet UIImageView *placeholderImageView;

@property (nonatomic, weak) IBOutlet UIView *wrapperView;
@property (nonatomic, weak) IBOutlet UIImageView *logoImageView;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *subtitleLabel;
@property (nonatomic, weak) IBOutlet UIImageView *thumbnailImageView;

@property (nonatomic, weak) IBOutlet UIView *blockingOverlayView;
@property (nonatomic, weak) IBOutlet UIImageView *blockingReasonImageView;

@property (nonatomic, weak) IBOutlet UIProgressView *progressView;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *topSpaceConstraint;

@property (nonatomic, weak) id channelRegistration;

@end

@implementation HomeLiveMediaCollectionViewCell

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.backgroundColor = UIColor.clearColor;
    
    self.mediaView.hidden = YES;
    self.placeholderView.hidden = NO;
    
    self.placeholderImageView.layer.cornerRadius = LayoutStandardViewCornerRadius;
    self.placeholderImageView.layer.masksToBounds = YES;
    
    // Accommodate all kinds of usages (medium or small)
    self.placeholderImageView.image = [UIImage play_vectorImageAtPath:FilePathForImagePlaceholder(ImagePlaceholderMedia)
                                                            withScale:ImageScaleMedium];
    
    self.progressView.progressTintColor = UIColor.play_progressRedColor;
    
    self.titleLabel.textColor = UIColor.whiteColor;
    self.subtitleLabel.textColor = UIColor.whiteColor;
    
    self.thumbnailImageView.backgroundColor = UIColor.play_grayThumbnailImageViewBackgroundColor;
    
    self.wrapperView.layer.cornerRadius = LayoutStandardViewCornerRadius;
    self.wrapperView.layer.masksToBounds = YES;
    
    self.blockingOverlayView.hidden = YES;
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    
    self.topSpaceConstraint.constant = (CGRectGetWidth(self.frame) < 170.f) ? 4.f : 12.f;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    self.mediaView.hidden = YES;
    self.placeholderView.hidden = NO;
    
    [self unregisterChannelUpdates];
    self.media = nil;
    
    self.programComposition = nil;
    
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
        [self unregisterChannelUpdates];
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
    SRGChannel *channel = self.programComposition.channel ?: self.media.channel;
    if (channel) {
        NSMutableString *accessibilityLabel = [NSMutableString stringWithFormat:PlaySRGAccessibilityLocalizedString(@"%@ live", @"Live content label, with a channel title"), channel.title];
        SRGProgram *currentProgram = [self.programComposition play_programAtDate:NSDate.date];
        if (currentProgram) {
            [accessibilityLabel appendFormat:@", %@", currentProgram.title];
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
    [self unregisterChannelUpdates];
    
    _media = media;
    
    [self registerForChannelUpdatesWithMedia:media];
    [self reloadData];
}

#pragma mark Channel updates

- (void)registerForChannelUpdatesWithMedia:(SRGMedia *)media
{
    if (media.contentType != SRGContentTypeLivestream || ! media.channel) {
        return;
    }
    
    [ChannelService.sharedService removeObserver:self.channelRegistration];
    self.channelRegistration = [ChannelService.sharedService addObserver:self forUpdatesWithChannel:media.channel livestreamUid:media.uid block:^(SRGProgramComposition * _Nullable programComposition) {
        self.programComposition = programComposition;
        [self reloadData];
    }];
}

- (void)unregisterChannelUpdates
{
    [ChannelService.sharedService removeObserver:self.channelRegistration];
}

#pragma mark UI

- (void)reloadData
{
    if (! self.media) {
        self.mediaView.hidden = YES;
        self.placeholderView.hidden = NO;
        return;
    }
    
    self.mediaView.hidden = NO;
    self.placeholderView.hidden = YES;
    
    self.titleLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleBody];
    
    SRGBlockingReason blockingReason = [self.media blockingReasonAtDate:NSDate.date];
    if (blockingReason == SRGBlockingReasonNone || blockingReason == SRGBlockingReasonStartDate) {
        self.blockingOverlayView.hidden = YES;
    }
    else {
        self.blockingOverlayView.hidden = NO;
        self.blockingReasonImageView.image = [UIImage play_imageForBlockingReason:blockingReason];
    }
    
    CGFloat subtitleFontSize = 11.f;
    ImageScale imageScale = ImageScaleMedium;
    
    self.subtitleLabel.font = [UIFont srg_mediumFontWithSize:subtitleFontSize];
    
    SRGChannel *channel = self.programComposition.channel ?: self.media.channel;
    if (channel) {
        UIImage *logoImage = channel.play_logo32Image;
        self.logoImageView.image = logoImage;
        
        SRGProgram *currentProgram = [self.programComposition play_programAtDate:NSDate.date];
        if (currentProgram) {
            self.titleLabel.text = currentProgram.title;
            
            NSTimeInterval remainingTimeInterval = [currentProgram.endDate timeIntervalSinceDate:NSDate.date];
            self.subtitleLabel.text = [NSString stringWithFormat:NSLocalizedString(@"%@ remaining", "Text displayed on live cells telling how much time remains for a program currently on air"), RemainingTimeFormattedDuration(remainingTimeInterval)];
            
            float progress = [NSDate.date timeIntervalSinceDate:currentProgram.startDate] / ([currentProgram.endDate timeIntervalSinceDate:currentProgram.startDate]);
            self.progressView.progress = fmaxf(fminf(progress, 1.f), 0.f);
            self.progressView.hidden = NO;
            
            [self.thumbnailImageView play_requestImageForObject:currentProgram withScale:imageScale type:SRGImageTypeDefault placeholder:ImagePlaceholderMedia unavailabilityHandler:^{
                [self.thumbnailImageView play_requestImageForObject:channel withScale:imageScale type:SRGImageTypeDefault placeholder:ImagePlaceholderMedia];
            }];
        }
        else {
            self.titleLabel.text = channel.title;
            self.subtitleLabel.text = nil;
            self.progressView.progress = 1.f;
            self.progressView.hidden = NO;
            
            [self.thumbnailImageView play_requestImageForObject:channel withScale:imageScale type:SRGImageTypeDefault placeholder:ImagePlaceholderMedia];
        }
    }
    else {
        self.titleLabel.text = self.media.title;
        self.logoImageView.image = (self.media.mediaType == SRGMediaTypeAudio) ? RadioChannelLogo32Image(nil) : TVChannelLogo32Image(nil);
        
        NSString *showTitle = self.media.show.title;
        if (showTitle && ! [self.media.title containsString:showTitle]) {
            NSMutableAttributedString *subtitle = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ - ", showTitle]
                                                                                         attributes:@{ NSFontAttributeName : [UIFont srg_mediumFontWithSize:subtitleFontSize] }];
            
            NSDateFormatter *dateFormatter = NSDateFormatter.play_relativeDateAndTimeFormatter;
            [subtitle appendAttributedString:[[NSAttributedString alloc] initWithString:[dateFormatter stringFromDate:self.media.date].play_localizedUppercaseFirstLetterString
                                                                             attributes:@{ NSFontAttributeName : [UIFont srg_lightFontWithSize:subtitleFontSize] }]];
            
            self.subtitleLabel.attributedText = subtitle.copy;
        }
        else {
            self.subtitleLabel.text = [NSDateFormatter.play_relativeDateAndTimeFormatter stringFromDate:self.media.date].play_localizedUppercaseFirstLetterString;
        }
        
        if (self.media.contentType == SRGContentTypeLivestream) {
            self.progressView.progress = 1.f;
            self.progressView.hidden = NO;
        }
        else if (self.media.contentType == SRGContentTypeScheduledLivestream && self.media.startDate && self.media.endDate && [self.media timeAvailabilityAtDate:NSDate.date] == SRGTimeAvailabilityAvailable) {
            float progress = [NSDate.date timeIntervalSinceDate:self.media.startDate] / ([self.media.endDate timeIntervalSinceDate:self.media.startDate]);
            self.progressView.progress = fmaxf(fminf(progress, 1.f), 0.f);
            self.progressView.hidden = NO;
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
