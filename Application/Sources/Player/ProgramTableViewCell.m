//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ProgramTableViewCell.h"

#import "Layout.h"
#import "NSBundle+PlaySRG.h"
#import "NSDateFormatter+PlaySRG.h"
#import "UIColor+PlaySRG.h"
#import "UIImageView+PlaySRG.h"

#import <SRGAppearance/SRGAppearance.h>

@interface ProgramTableViewCell ()

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;
@property (nonatomic, weak) IBOutlet UILabel *subtitleLabel;
@property (nonatomic, weak) IBOutlet UIImageView *thumbnailImageView;
@property (nonatomic, weak) IBOutlet UIImageView *waveformImageView;

@end

@implementation ProgramTableViewCell

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.backgroundColor = UIColor.clearColor;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
    
    self.thumbnailImageView.backgroundColor = UIColor.play_grayThumbnailImageViewBackgroundColor;
    self.thumbnailImageView.layer.cornerRadius = LayoutStandardViewCornerRadius;
    self.thumbnailImageView.layer.masksToBounds = YES;
    
    self.titleLabel.textColor = UIColor.whiteColor;
    self.subtitleLabel.textColor = UIColor.whiteColor;
    
    self.waveformImageView.hidden = YES;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    [self.thumbnailImageView play_resetImage];
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated
{
    [super setSelected:selected animated:animated];
    
    self.waveformImageView.hidden = ! selected;
    
    if (self.playing) {
        [self.waveformImageView play_startAnimatingDownloading48WithTintColor:UIColor.whiteColor];
    }
    else {
        [self.waveformImageView play_stopAnimating];
    }
}

#pragma mark Accessibility

- (BOOL)isAccessibilityElement
{
    return YES;
}

- (NSString *)accessibilityLabel
{
    return self.program.title;
}

- (NSString *)accessibilityHint
{
    return PlaySRGAccessibilityLocalizedString(@"Plays from the beginning.", @"Program cell hint");
}

#pragma mark Getters and setters

- (void)setProgram:(SRGProgram *)program
{
    _program = program;
    
    self.titleLabel.text = program.title;
    self.titleLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleSubtitle];
    
    self.subtitleLabel.text = [NSString stringWithFormat:@"%@ - %@", [NSDateFormatter.play_timeFormatter stringFromDate:program.startDate], [NSDateFormatter.play_timeFormatter stringFromDate:program.endDate]];
    self.subtitleLabel.font = [UIFont srg_lightFontWithTextStyle:SRGAppearanceFontTextStyleSubtitle];
    
    [self.thumbnailImageView play_requestImageForObject:program withScale:ImageScaleSmall type:SRGImageTypeDefault placeholder:ImagePlaceholderMedia];
}

@end
