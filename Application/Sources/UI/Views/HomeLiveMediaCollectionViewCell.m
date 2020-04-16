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
#import "UIColor+PlaySRG.h"
#import "UIImageView+PlaySRG.h"
#import "UILabel+PlaySRG.h"

#import <libextobjc/libextobjc.h>
#import <SRGAnalytics/SRGAnalytics.h>
#import <SRGAppearance/SRGAppearance.h>

@interface HomeLiveMediaCollectionViewCell ()

@property (nonatomic) SRGChannel *channel;

@property (nonatomic, weak) IBOutlet UIView *mediaView;
@property (nonatomic, weak) IBOutlet UIView *placeholderView;
@property (nonatomic, weak) IBOutlet UIImageView *placeholderImageView;

@property (nonatomic, weak) IBOutlet UIImageView *logoImageView;
@property (nonatomic, weak) IBOutlet UILabel *recentLabel;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *subtitleLabel;
@property (nonatomic, weak) IBOutlet UIImageView *thumbnailImageView;
@property (nonatomic, weak) IBOutlet UILabel *durationLabel;

@property (nonatomic, weak) IBOutlet UIView *blockingOverlayView;
@property (nonatomic, weak) IBOutlet UIImageView *blockingReasonImageView;

@property (nonatomic, weak) IBOutlet UIProgressView *progressView;

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
    
    self.subtitleLabel.textColor = UIColor.play_lightGrayColor;
    
    self.thumbnailImageView.backgroundColor = UIColor.play_grayThumbnailImageViewBackgroundColor;
    self.thumbnailImageView.layer.cornerRadius = LayoutStandardViewCornerRadius;
    self.thumbnailImageView.layer.masksToBounds = YES;
    
    self.recentLabel.layer.cornerRadius = LayoutStandardLabelCornerRadius;
    self.recentLabel.layer.masksToBounds = YES;
    self.recentLabel.backgroundColor = UIColor.play_blackDurationLabelBackgroundColor;
    self.recentLabel.text = [NSString stringWithFormat:@"  %@  ", NSLocalizedString(@"Last played", @"Label on recently played livestreams").uppercaseString];
    self.recentLabel.hidden = YES;
    
    self.durationLabel.backgroundColor = UIColor.play_blackDurationLabelBackgroundColor;
    
    self.blockingOverlayView.hidden = YES;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    self.mediaView.hidden = YES;
    self.placeholderView.hidden = NO;
    
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
        if (! self.recentLabel.hidden) {
            [accessibilityLabel appendFormat:@", %@", PlaySRGAccessibilityLocalizedString(@"Last played", @"Label on recently played livestreams")];
        }
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
    
    [ChannelService.sharedService registerObserver:self forChannelUpdatesWithMedia:media block:^(SRGProgramComposition * _Nullable programComposition) {
        // TODO: Store program list and use last item
        self.channel = programComposition.channel ?: media.channel;
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
    if (! self.media) {
        self.mediaView.hidden = YES;
        self.placeholderView.hidden = NO;
        return;
    }
    
    self.mediaView.hidden = NO;
    self.placeholderView.hidden = YES;
    
    self.titleLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleBody];
    self.durationLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleCaption];
    
    self.recentLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleCaption];
    self.recentLabel.hidden = ! [self.media.URN isEqualToString:ApplicationSettingLastSelectedTVLivestreamURN()]
        && ! [self.media.URN isEqualToString:ApplicationSettingLastSelectedRadioLivestreamURN()];
    
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
