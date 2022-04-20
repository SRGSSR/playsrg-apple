//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "DownloadTableViewCell.h"

#import "AnalyticsConstants.h"
#import "History.h"
#import "Layout.h"
#import "NSBundle+PlaySRG.h"
#import "NSDateFormatter+PlaySRG.h"
#import "NSString+PlaySRG.h"
#import "SRGMedia+PlaySRG.h"
#import "UIColor+PlaySRG.h"
#import "UIImage+PlaySRG.h"
#import "UIImageView+PlaySRG.h"
#import "UIColor+PlaySRG.h"
#import "UILabel+PlaySRG.h"

@import SRGAppearance;
@import SRGUserData;

@interface DownloadTableViewCell ()

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *subtitleLabel;
@property (nonatomic, weak) IBOutlet UIView *thumbnailWrapperView;
@property (nonatomic, weak) IBOutlet UIImageView *thumbnailImageView;
@property (nonatomic, weak) IBOutlet UILabel *durationLabel;
@property (nonatomic, weak) IBOutlet UIImageView *youthProtectionColorImageView;
@property (nonatomic, weak) IBOutlet UIImageView *downloadStatusImageView;
@property (nonatomic, weak) IBOutlet UILabel *webFirstLabel;

@property (nonatomic, weak) IBOutlet UIProgressView *progressView;

@property (nonatomic) UIColor *durationLabelBackgroundColor;

@property (nonatomic, copy) NSString *progressTaskHandle;

@end

@implementation DownloadTableViewCell

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.backgroundColor = UIColor.srg_gray16Color;
    
    UIView *selectedBackgroundView = [[UIView alloc] init];
    selectedBackgroundView.backgroundColor = UIColor.clearColor;
    self.selectedBackgroundView = selectedBackgroundView;
    
    self.thumbnailWrapperView.backgroundColor = UIColor.play_grayThumbnailImageViewBackgroundColor;
    self.thumbnailWrapperView.layer.cornerRadius = LayoutStandardViewCornerRadius;
    self.thumbnailWrapperView.layer.masksToBounds = YES;
    
    self.durationLabelBackgroundColor = self.durationLabel.backgroundColor;
    
    self.youthProtectionColorImageView.hidden = YES;
    self.webFirstLabel.hidden = YES;
    
    self.progressView.progressTintColor = UIColor.srg_lightRedColor;
    
    self.downloadStatusImageView.tintColor = UIColor.srg_grayC7Color;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    self.youthProtectionColorImageView.hidden = YES;
    self.webFirstLabel.hidden = YES;
    
    self.progressView.hidden = YES;
    
    [self.thumbnailImageView play_resetImage];
}

- (void)willMoveToWindow:(UIWindow *)window
{
    [super willMoveToWindow:window];
    
    if (window) {
        [self updateDownloadStatus];
        
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(historyEntriesDidChange:)
                                                   name:SRGHistoryEntriesDidChangeNotification
                                                 object:SRGUserData.currentUserData.history];
    }
    else {
        [NSNotificationCenter.defaultCenter removeObserver:self name:SRGHistoryEntriesDidChangeNotification object:SRGUserData.currentUserData.history];
    }
}

- (void)setEditing:(BOOL)editing animated:(BOOL)animated
{
    [super setEditing:editing animated:animated];
    
    self.selectionStyle = editing ? UITableViewCellSelectionStyleDefault : UITableViewCellSelectionStyleNone;
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    if (self.editing) {
        [self updateDownloadStatus];
        self.durationLabel.backgroundColor = self.durationLabelBackgroundColor;
    }
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    [super setHighlighted:highlighted animated:animated];
    
    if (self.editing) {
        [self updateDownloadStatus];
        self.durationLabel.backgroundColor = self.durationLabelBackgroundColor;
    }
}

#pragma mark Accessibility

- (BOOL)isAccessibilityElement
{
    return YES;
}

- (NSString *)accessibilityLabel
{
    NSMutableString *accessibilityLabel = self.download.title.mutableCopy;
    
    SRGShow *show = self.download.media.show;
    if (show.title && ! [show.title isEqualToString:self.download.title]) {
        [accessibilityLabel appendFormat:@", %@", show.title];
    }
    
    NSString *youthProtectionAccessibilityLabel = SRGAccessibilityLabelForYouthProtectionColor(self.download.youthProtectionColor);
    if (self.youthProtectionColorImageView.image && youthProtectionAccessibilityLabel) {
        [accessibilityLabel appendFormat:@". %@", youthProtectionAccessibilityLabel];
    }
    
    return accessibilityLabel.copy;
}

- (NSString *)accessibilityHint
{
    return PlaySRGAccessibilityLocalizedString(@"Plays the content.", @"Media cell hint") ;
}

#pragma mark Getters and setters

- (void)setDownload:(Download *)download
{
    if (_download) {
        [NSNotificationCenter.defaultCenter removeObserver:self name:DownloadStateDidChangeNotification object:_download];
        [NSNotificationCenter.defaultCenter removeObserver:self name:DownloadProgressDidChangeNotification object:_download];
    }
    
    _download = download;
    
    if (download) {
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(downloadStateDidChange:)
                                                   name:DownloadStateDidChangeNotification
                                                 object:download];
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(downloadProgressDidChange:)
                                                   name:DownloadProgressDidChangeNotification
                                                 object:download];
    }
    
    self.titleLabel.text = download.title;
    self.titleLabel.font = [SRGFont fontWithStyle:SRGFontStyleBody];
    
    [self.durationLabel play_displayDurationLabelForMediaMetadata:download];
    
    BOOL isWebFirst = download.media.play_isWebFirst;
    self.webFirstLabel.hidden = ! isWebFirst;
    
    [self.webFirstLabel play_setWebFirstBadge];
    
    // Have content fit in (almost) constant size vertically by reducing the title number of lines when a tag is displayed
    UIContentSizeCategory contentSizeCategory = UIApplication.sharedApplication.preferredContentSizeCategory;
    if (SRGAppearanceCompareContentSizeCategories(contentSizeCategory, UIContentSizeCategoryExtraLarge) == NSOrderedDescending) {
        self.titleLabel.numberOfLines = isWebFirst ? 1 : 2;
    }
    else {
        self.titleLabel.numberOfLines = 2;
    }
    
    self.youthProtectionColorImageView.image = YouthProtectionImageForColor(download.youthProtectionColor);
    self.youthProtectionColorImageView.hidden = (self.youthProtectionColorImageView.image == nil);
    
    self.subtitleLabel.numberOfLines = self.durationLabel.hidden ? 3 : 1;
    
    [self.thumbnailImageView play_requestImage:download.media.image withSize:SRGImageSizeSmall placeholder:ImagePlaceholderMedia unavailabilityHandler:^{
        [self.thumbnailImageView play_requestImage:download.image withSize:SRGImageSizeSmall placeholder:ImagePlaceholderMedia];
    }];
    
    [self updateDownloadStatus];
    [self updateHistoryStatus];
}

#pragma mark UI

- (void)updateDownloadStatus
{
    UIColor *tintColor = (self.editing && (self.selected || self.highlighted)) ? UIColor.redColor : UIColor.srg_grayC7Color;
    
    self.subtitleLabel.text = [NSDateFormatter.play_relativeDateFormatter stringFromDate:self.download.date].play_localizedUppercaseFirstLetterString;
    self.subtitleLabel.font = [SRGFont fontWithStyle:SRGFontStyleSubtitle1];
    
    switch (self.download.state) {
        case DownloadStateAdded:
        case DownloadStateDownloadingSuspended: {
            [self.downloadStatusImageView stopAnimating];
            self.downloadStatusImageView.image = [UIImage imageNamed:@"downloadable_stop"];
            self.downloadStatusImageView.tintColor = tintColor;
            break;
        }
            
        case DownloadStateDownloading: {
            NSProgress *progress = [Download currentlyKnownProgressForDownload:self.download] ?: [NSProgress progressWithTotalUnitCount:10]; // Display 0% if nothing
            self.subtitleLabel.text = [progress localizedDescription];
            
            [self.downloadStatusImageView play_setSmallDownloadAnimationWithTintColor:tintColor];
            [self.downloadStatusImageView startAnimating];
            break;
        }
            
        case DownloadStateDownloaded: {
            self.subtitleLabel.text = [NSByteCountFormatter stringFromByteCount:self.download.size countStyle:NSByteCountFormatterCountStyleFile];
            
            [self.downloadStatusImageView stopAnimating];
            self.downloadStatusImageView.image = [UIImage imageNamed:@"downloadable_full"];
            self.downloadStatusImageView.tintColor = tintColor;
            break;
        }
            
        case DownloadStateDownloadable:
        case DownloadStateRemoved: {
            [self.downloadStatusImageView stopAnimating];
            self.downloadStatusImageView.image = [UIImage imageNamed:@"downloadable"];
            self.downloadStatusImageView.tintColor = tintColor;
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
    HistoryAsyncCancel(self.progressTaskHandle);
    self.progressTaskHandle = HistoryPlaybackProgressForMediaAsync(self.download.media, ^(float progress, BOOL completed) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.progressView.hidden = (progress == 0.f);
            self.progressView.progress = progress;
        });
    });
}

#pragma mark Notifications

- (void)downloadStateDidChange:(NSNotification *)notification
{
    [self updateDownloadStatus];
}

- (void)downloadProgressDidChange:(NSNotification *)notification
{
    NSProgress *progress = notification.userInfo[DownloadProgressKey];
    self.subtitleLabel.text = progress.localizedDescription;
}

- (void)historyEntriesDidChange:(NSNotification *)notification
{
    NSArray<NSString *> *updatedURNs = notification.userInfo[SRGHistoryEntriesUidsKey];
    if (self.download && [updatedURNs containsObject:self.download.URN]) {
        [self updateHistoryStatus];
    }
}

@end
