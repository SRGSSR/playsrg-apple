//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NotificationTableViewCell.h"

#import "Layout.h"
#import "NSDateFormatter+PlaySRG.h"
#import "UIColor+PlaySRG.h"
#import "UIImage+PlaySRG.h"
#import "UIImageView+PlaySRG.h"
#import "UILabel+PlaySRG.h"

@import SRGAppearance;

@interface NotificationTableViewCell ()

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *subtitleLabel;
@property (nonatomic, weak) IBOutlet UIImageView *thumbnailImageView;
@property (nonatomic, weak) IBOutlet UILabel *dateLabel;

@property (nonatomic, weak) IBOutlet UILabel *unreadLabel;

@end

@implementation NotificationTableViewCell

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.backgroundColor = UIColor.srg_gray16Color;
    
    UIView *selectedBackgroundView = [[UIView alloc] init];
    selectedBackgroundView.backgroundColor = UIColor.clearColor;
    self.selectedBackgroundView = selectedBackgroundView;
    
    self.thumbnailImageView.backgroundColor = UIColor.play_grayThumbnailImageViewBackgroundColor;
    self.thumbnailImageView.layer.cornerRadius = LayoutStandardViewCornerRadius;
    self.thumbnailImageView.layer.masksToBounds = YES;
    
    self.subtitleLabel.textColor = UIColor.srg_grayC7Color;
    self.dateLabel.textColor = UIColor.srg_grayC7Color;
    self.unreadLabel.textColor = UIColor.play_notificationRedColor;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    [self.thumbnailImageView play_resetImage];
}

#pragma mark Accessibility

- (NSString *)accessibilityLabel
{
    return [self.notification.title stringByAppendingFormat:@", %@", self.notification.body];
}

#pragma mark Getters and setters

- (void)setNotification:(Notification *)notification
{
    _notification = notification;
    
    self.titleLabel.text = notification.title;
    self.titleLabel.font = [SRGFont fontWithStyle:SRGFontStyleBody];
    
    self.unreadLabel.hidden = notification.read;
    
    self.subtitleLabel.text = notification.body;
    self.subtitleLabel.font = [SRGFont fontWithStyle:SRGFontStyleSubtitle1];
    
    self.dateLabel.text = [NSDateFormatter.play_relativeDateFormatter stringFromDate:notification.date];
    self.dateLabel.font = [SRGFont fontWithStyle:SRGFontStyleSubtitle1];
    
    // Have content fit in (almost) constant size vertically by reducing the title number of lines when a tag is displayed
    UIContentSizeCategory contentSizeCategory = UIApplication.sharedApplication.preferredContentSizeCategory;
    if (SRGAppearanceCompareContentSizeCategories(contentSizeCategory, UIContentSizeCategoryExtraLarge) == NSOrderedDescending) {
        self.subtitleLabel.numberOfLines = 1;
    }
    else {
        self.subtitleLabel.numberOfLines = 2;
    }
    
    ImagePlaceholder imagePlaceholder = ImagePlaceholderNotification;
    if (notification.mediaURN) {
        imagePlaceholder = ImagePlaceholderMedia;
    }
    else if (notification.showURN) {
        imagePlaceholder = ImagePlaceholderMediaList;
    }
    
    // FIXME:
    NSAssert(NO, @"Must be fixed");
    // [self.thumbnailImageView play_requestImageForObject:notification withScale:ImageScaleSmall type:SRGImageTypeDefault placeholder:imagePlaceholder];
}

@end
