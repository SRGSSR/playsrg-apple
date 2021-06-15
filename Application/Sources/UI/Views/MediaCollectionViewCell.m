//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "MediaCollectionViewCell.h"

#import "AnalyticsConstants.h"
#import "ApplicationConfiguration.h"
#import "ApplicationSettings.h"
#import "Banner.h"
#import "Download.h"
#import "History.h"
#import "Layout.h"
#import "NSBundle+PlaySRG.h"
#import "NSDateFormatter+PlaySRG.h"
#import "NSString+PlaySRG.h"
#import "SRGMedia+PlaySRG.h"
#import "UIColor+PlaySRG.h"
#import "UIImage+PlaySRG.h"
#import "UIImageView+PlaySRG.h"
#import "UILabel+PlaySRG.h"

@import SRGAnalytics;
@import SRGAppearance;
@import SRGUserData;

@interface MediaCollectionViewCell ()

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *subtitleLabel;
@property (nonatomic, weak) IBOutlet UIView *thumbnailWrapperView;
@property (nonatomic, weak) IBOutlet UIImageView *thumbnailImageView;
@property (nonatomic, weak) IBOutlet UILabel *durationLabel;
@property (nonatomic, weak) IBOutlet UIImageView *youthProtectionColorImageView;
@property (nonatomic, weak) IBOutlet UIImageView *downloadStatusImageView;
@property (nonatomic, weak) IBOutlet UIImageView *media360ImageView;
@property (nonatomic, weak) IBOutlet UILabel *webFirstLabel;
@property (nonatomic, weak) IBOutlet UILabel *subtitlesLabel;
@property (nonatomic, weak) IBOutlet UIImageView *audioDescriptionImageView;

@property (nonatomic, weak) IBOutlet UIView *blockingOverlayView;
@property (nonatomic, weak) IBOutlet UIImageView *blockingReasonImageView;

@property (nonatomic, weak) IBOutlet UIProgressView *progressView;

@property (nonatomic) IBOutletCollection(NSLayoutConstraint) NSArray *allSizeLayoutConstraints;
@property (nonatomic) IBOutletCollection(NSLayoutConstraint) NSArray *compactRegularLayoutConstraints;

@property (nonatomic, copy) NSString *progressTaskHandle;

@end

@implementation MediaCollectionViewCell

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.backgroundColor = UIColor.clearColor;
    
    self.thumbnailWrapperView.backgroundColor = UIColor.play_grayThumbnailImageViewBackgroundColor;
    self.thumbnailWrapperView.layer.cornerRadius = LayoutStandardViewCornerRadius;
    self.thumbnailWrapperView.layer.masksToBounds = YES;
    
    self.subtitleLabel.textColor = UIColor.play_lightGrayColor;
    
    self.durationLabel.backgroundColor = UIColor.play_blackDurationLabelBackgroundColor;
    
    self.audioDescriptionImageView.tintColor = UIColor.play_whiteBadgeColor;
    
    self.audioDescriptionImageView.accessibilityLabel = PlaySRGAccessibilityLocalizedString(@"Audio described", @"Accessibility label for the audio description badge");
    
    self.youthProtectionColorImageView.hidden = YES;
    self.webFirstLabel.hidden = YES;
    self.subtitlesLabel.hidden = YES;
    self.audioDescriptionImageView.hidden = YES;

    self.progressView.progressTintColor = UIColor.play_progressRedColor;
    
    self.downloadStatusImageView.tintColor = UIColor.play_lightGrayColor;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    self.youthProtectionColorImageView.hidden = YES;
    self.webFirstLabel.hidden = YES;
    self.subtitlesLabel.hidden = YES;
    self.audioDescriptionImageView.hidden = YES;

    self.blockingOverlayView.hidden = YES;
    self.progressView.hidden = YES;
    
    [self.thumbnailImageView play_resetImage];
}

- (void)willMoveToWindow:(UIWindow *)newWindow
{
    [super willMoveToWindow:newWindow];
    
    if (newWindow) {
        [self updateActiveConstraints];
        
        // Ensure proper state when the view is reinserted
        [self updateDownloadStatus];
        
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(downloadStateDidChange:)
                                                   name:DownloadStateDidChangeNotification
                                                 object:nil];
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(historyEntriesDidChange:)
                                                   name:SRGHistoryEntriesDidChangeNotification
                                                 object:SRGUserData.currentUserData.history];
    }
    else {
        [NSNotificationCenter.defaultCenter removeObserver:self name:DownloadStateDidChangeNotification object:nil];
        [NSNotificationCenter.defaultCenter removeObserver:self name:SRGHistoryEntriesDidChangeNotification object:SRGUserData.currentUserData.history];
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
    
    [self updateActiveConstraints];
    
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
        NSMutableString *accessibilityLabel = [NSMutableString stringWithFormat:PlaySRGAccessibilityLocalizedString(@"%@ live", @"Live content label, with a media title"), self.media.title];
        if (self.media.channel) {
            [accessibilityLabel appendFormat:@", %@", self.media.channel.title];
        }
        return accessibilityLabel.copy;
    }
    else {
        NSMutableString *accessibilityLabel = self.media.title.mutableCopy;
        
        if (self.media.show.title && ! [self.media.title containsString:self.media.show.title]) {
            [accessibilityLabel appendFormat:@", %@", self.media.show.title];
        }
        
        NSString *youthProtectionAccessibilityLabel = SRGAccessibilityLabelForYouthProtectionColor(self.media.youthProtectionColor);
        if (self.youthProtectionColorImageView.image && youthProtectionAccessibilityLabel) {
            [accessibilityLabel appendFormat:@". %@", youthProtectionAccessibilityLabel];
        }
        
        BOOL downloaded = [Download downloadForMedia:self.media].state == DownloadStateDownloaded;
        if (self.media.play_audioDescriptionAvailable && ! downloaded) {
            [accessibilityLabel appendFormat:@". %@", PlaySRGAccessibilityLocalizedString(@"Audio described", @"Accessibility label for a media cell with audio description")];
        }
        
        return accessibilityLabel.copy;
    }
}

- (NSString *)accessibilityHint
{
    return PlaySRGAccessibilityLocalizedString(@"Plays the content.", @"Media cell hint");
}

#pragma mark Getters and setters

- (void)setMedia:(SRGMedia *)media
{
    [self setMedia:media withDateFormatter:nil];
}

- (void)setMedia:(SRGMedia *)media withDateFormatter:(NSDateFormatter *)dateFormatter
{
    _media = media;
    
    self.titleLabel.font = [SRGFont fontWithStyle:SRGFontStyleBody];
    self.titleLabel.text = media.title;
    
    if (media.contentType != SRGContentTypeLivestream) {
        NSString *showTitle = media.show.title;
        if (showTitle && ! [media.title containsString:showTitle]) {
            NSMutableAttributedString *subtitle = [[NSMutableAttributedString alloc] initWithString:[NSString stringWithFormat:@"%@ - ", showTitle]
                                                                                         attributes:@{ NSFontAttributeName : [SRGFont fontWithStyle:SRGFontStyleSubtitle] }];
            
            NSDateFormatter *shortDateFormatter = dateFormatter ?: NSDateFormatter.play_relativeDateFormatter;
            [subtitle appendAttributedString:[[NSAttributedString alloc] initWithString:[shortDateFormatter stringFromDate:media.date].play_localizedUppercaseFirstLetterString
                                                                             attributes:@{ NSFontAttributeName : [SRGFont fontWithStyle:SRGFontStyleSubtitle] }]];
            
            self.subtitleLabel.attributedText = subtitle.copy;
        }
        else {
            self.subtitleLabel.font = [SRGFont fontWithStyle:SRGFontStyleSubtitle];
            
            NSDateFormatter *longDateFormatter = dateFormatter ?: NSDateFormatter.play_relativeDateAndTimeFormatter;
            self.subtitleLabel.text = [longDateFormatter stringFromDate:media.date].play_localizedUppercaseFirstLetterString;
        }
    }
    else {
        self.subtitleLabel.text = nil;
    }
    
    [self.durationLabel play_displayDurationLabelForMediaMetadata:media];
    
    self.media360ImageView.hidden = (media.presentation != SRGPresentation360);
    
    BOOL downloaded = [Download downloadForMedia:media].state == DownloadStateDownloaded;
    
    BOOL isWebFirst = media.play_webFirst;
    self.webFirstLabel.hidden = ! isWebFirst;
    
    BOOL hasSubtitles = ApplicationSettingSubtitleAvailabilityDisplayed() && media.play_subtitlesAvailable && ! downloaded;
    self.subtitlesLabel.hidden = ! hasSubtitles;
    
    BOOL hasAudioDescription = ApplicationSettingAudioDescriptionAvailabilityDisplayed() && media.play_audioDescriptionAvailable && ! downloaded;
    self.audioDescriptionImageView.hidden = ! hasAudioDescription;
    
    [self.webFirstLabel play_setWebFirstBadge];
    [self.subtitlesLabel play_setSubtitlesAvailableBadge];
    
    // Have content fit in (almost) constant size vertically by reducing the title number of lines when a tag is displayed
    if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact) {
        UIContentSizeCategory contentSizeCategory = UIApplication.sharedApplication.preferredContentSizeCategory;
        if (SRGAppearanceCompareContentSizeCategories(contentSizeCategory, UIContentSizeCategoryExtraLarge) == NSOrderedDescending) {
            self.titleLabel.numberOfLines = (isWebFirst || hasSubtitles || hasAudioDescription) ? 1 : 2;
        }
        else {
            self.titleLabel.numberOfLines = 2;
        }
    }
    else {
        self.titleLabel.numberOfLines = (isWebFirst || hasSubtitles || hasAudioDescription) ? 1 : 2;
    }
    
    self.youthProtectionColorImageView.image = YouthProtectionImageForColor(self.media.youthProtectionColor);
    self.youthProtectionColorImageView.hidden = (self.youthProtectionColorImageView.image == nil);
    
    SRGBlockingReason blockingReason = [media blockingReasonAtDate:NSDate.date];
    if (blockingReason == SRGBlockingReasonNone || blockingReason == SRGBlockingReasonStartDate) {
        self.blockingOverlayView.hidden = YES;
        
        self.titleLabel.textColor = UIColor.whiteColor;
    }
    else {
        self.blockingOverlayView.hidden = NO;
        self.blockingReasonImageView.image = [UIImage play_imageForBlockingReason:blockingReason];
        
        self.titleLabel.textColor = UIColor.play_lightGrayColor;
    }
    
    id<SRGImage> imageObject = (media.contentType == SRGContentTypeLivestream && media.channel) ? media.channel : media;
    [self.thumbnailImageView play_requestImageForObject:imageObject withScale:ImageScaleSmall type:SRGImageTypeDefault placeholder:ImagePlaceholderMedia];
    
    [self updateDownloadStatus];
    [self updateHistoryStatus];
}

#pragma mark UI

- (void)updateActiveConstraints
{
    if (self.traitCollection.horizontalSizeClass == UIUserInterfaceSizeClassCompact) {
        for (NSLayoutConstraint *layoutConstraint in self.allSizeLayoutConstraints) {
            layoutConstraint.priority = 100;
        }
        for (NSLayoutConstraint *layoutConstraint in self.compactRegularLayoutConstraints) {
            layoutConstraint.priority = 999;
        }
    }
    else {
        for (NSLayoutConstraint *layoutConstraint in self.allSizeLayoutConstraints) {
            layoutConstraint.priority = 999;
        }
        for (NSLayoutConstraint *layoutConstraint in self.compactRegularLayoutConstraints) {
            layoutConstraint.priority = 100;
        }
    }
}

- (void)updateDownloadStatus
{
    Download *download = [Download downloadForMedia:self.media];
    if (! download) {
        [self.downloadStatusImageView stopAnimating];
        self.downloadStatusImageView.image = [UIImage imageNamed:@"downloadable-16"];
        
        BOOL downloadsHintsHidden = ApplicationConfiguration.sharedApplicationConfiguration.downloadsHintsHidden;
        self.downloadStatusImageView.hidden = downloadsHintsHidden || ! [Download canDownloadMedia:self.media];
        return;
    }
    
    self.downloadStatusImageView.hidden = NO;
    
    switch (download.state) {
        case DownloadStateAdded:
        case DownloadStateDownloadingSuspended: {
            [self.downloadStatusImageView stopAnimating];
            self.downloadStatusImageView.image = [UIImage imageNamed:@"downloadable_stop-16"];
            break;
        }
            
        case DownloadStateDownloading: {
            [self.downloadStatusImageView play_setDownloadAnimation16WithTintColor:UIColor.play_lightGrayColor];
            [self.downloadStatusImageView startAnimating];
            break;
        }
            
        case DownloadStateDownloaded: {
            [self.downloadStatusImageView stopAnimating];
            self.downloadStatusImageView.image = [UIImage imageNamed:@"downloadable_full-16"];
            break;
        }
            
        case DownloadStateDownloadable:
        case DownloadStateRemoved: {
            [self.downloadStatusImageView stopAnimating];
            self.downloadStatusImageView.image = [UIImage imageNamed:@"downloadable-16"];
            break;
        }
            
        default: {
            [self.downloadStatusImageView stopAnimating];
            self.downloadStatusImageView.image = nil;
            break;
        }
    }
}

- (void)updateHistoryStatus
{
    HistoryPlaybackProgressAsyncCancel(self.progressTaskHandle);
    self.progressTaskHandle = HistoryPlaybackProgressForMediaMetadataAsync(self.media, ^(float progress) {
        self.progressView.hidden = (progress == 0.f);
        self.progressView.progress = progress;
    });
}

#pragma mark Previewing protocol

- (id)previewObject
{
    return self.media;
}

#pragma mark Notifications

- (void)downloadStateDidChange:(NSNotification *)notification
{
    [self updateDownloadStatus];
}

- (void)historyEntriesDidChange:(NSNotification *)notification
{
    NSArray<NSString *> *updatedURNs = notification.userInfo[SRGHistoryEntriesUidsKey];
    if (self.media && [updatedURNs containsObject:self.media.URN]) {
        [self updateHistoryStatus];
    }
}

@end
