//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ProfileTableViewCell.h"

#import "DownloadSession.h"
#import "PushService.h"
#import "UIColor+PlaySRG.h"
#import "UIImageView+PlaySRG.h"

@import SRGAppearance;

@interface ProfileTableViewCell ()

@property (nonatomic, weak) IBOutlet UIImageView *iconImageView;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;

@end

@implementation ProfileTableViewCell

#pragma mark Class methods

+ (CGFloat)height
{
    UIFontMetrics *fontMetrics = [SRGFont metricsForFontWithStyle:SRGFontStyleH4];
    return [fontMetrics scaledValueForValue:50.f];
}

#pragma mark Getters and setters

- (void)setApplicationSectionInfo:(ApplicationSectionInfo *)applicationSectionInfo
{
    _applicationSectionInfo = applicationSectionInfo;
    
    self.titleLabel.font = [SRGFont fontWithStyle:SRGFontStyleH4];
    self.titleLabel.text = applicationSectionInfo.title;
    
    [self updateIconImageView];
}

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.backgroundColor = UIColor.clearColor;
    
    UIView *selectedBackgroundView = [[UIView alloc] init];
    selectedBackgroundView.backgroundColor = [UIColor colorWithWhite:0.15f alpha:1.f];
    self.selectedBackgroundView = selectedBackgroundView;
}

- (void)willMoveToWindow:(UIWindow *)window
{
    [super willMoveToWindow:window];
    
    if (window) {
        [self updateIconImageView];
        [NSNotificationCenter.defaultCenter addObserver:self
                                               selector:@selector(downloadSessionStateDidChange:)
                                                   name:DownloadSessionStateDidChangeNotification
                                                 object:nil];
    }
    else {
        [NSNotificationCenter.defaultCenter removeObserver:self name:DownloadSessionStateDidChangeNotification object:nil];
    }
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    [super setHighlighted:highlighted animated:animated];
    
    UIColor *color = (highlighted && self.selectionStyle == UITableViewCellAccessoryNone) ? UIColor.srg_gray96Color : UIColor.whiteColor;
    self.titleLabel.textColor = color;
    self.iconImageView.tintColor = color;
    
    [self updateIconImageView];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    [self updateIconImageView];
}

#pragma mark User interface

- (void)updateIconImageView
{
    if (self.applicationSectionInfo.applicationSection == ApplicationSectionDownloads
            && DownloadSession.sharedDownloadSession.state == DownloadSessionStateDownloading) {
        [self.iconImageView play_setDownloadAnimationWithTintColor:self.iconImageView.tintColor];
        [self.iconImageView startAnimating];
    }
    else {
        [self.iconImageView stopAnimating];
        self.iconImageView.image = self.applicationSectionInfo.image;
    }
}

#pragma mark Notifications

- (void)downloadSessionStateDidChange:(NSNotification *)notification
{
    [self updateIconImageView];
}

@end
