//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "OnboardingTableViewCell.h"

#import "NSBundle+PlaySRG.h"
#import "UIColor+PlaySRG.h"

@import SRGAppearance;

@interface OnboardingTableViewCell ()

@property (nonatomic, weak) IBOutlet UIImageView *iconImageView;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;

@end

@implementation OnboardingTableViewCell

#pragma mark Getters and setters

- (void)setOnboarding:(Onboarding *)onboarding
{
    _onboarding = onboarding;
    
    self.iconImageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"%@_icon", onboarding.uid]];
    
    self.titleLabel.font = [SRGFont fontWithStyle:SRGFontStyleH4];
    self.titleLabel.text = PlaySRGOnboardingLocalizedString(onboarding.title, nil);
}

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.backgroundColor = UIColor.clearColor;
    
    // Cell highlighting is custom
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

- (void)setHighlighted:(BOOL)highlighted animated:(BOOL)animated
{
    [super setHighlighted:highlighted animated:animated];
    
    UIColor *color = highlighted ? UIColor.srg_gray96Color : UIColor.whiteColor;
    self.titleLabel.textColor = color;
    self.iconImageView.tintColor = color;
}

@end
