//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "OnboardingTableViewCell.h"

#import "NSBundle+PlaySRG.h"

#import <SRGAppearance/SRGAppearance.h>

@interface OnboardingTableViewCell ()

@property (nonatomic, weak) IBOutlet UIImageView *iconImageView;
@property (nonatomic, weak) IBOutlet UILabel *titleLabel;

@end

@implementation OnboardingTableViewCell

#pragma mark Getters and setters

- (void)setOnboarding:(Onboarding *)onboarding
{
    _onboarding = onboarding;
    
    self.iconImageView.image = [UIImage imageNamed:[NSString stringWithFormat:@"%@_icon-22", onboarding.uid]];
    
    self.titleLabel.font = [UIFont srg_regularFontWithTextStyle:SRGAppearanceFontTextStyleHeadline];
    self.titleLabel.text = PlaySRGOnboardingLocalizedString(onboarding.title, nil);
}

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    self.backgroundColor = UIColor.clearColor;
}

@end
