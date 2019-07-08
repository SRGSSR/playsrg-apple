//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SearchSettingsHeaderView.h"

#import "UIColor+PlaySRG.h"

#import <SRGAppearance/SRGAppearance.h>

@interface SearchSettingsHeaderView ()

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;

@end

@implementation SearchSettingsHeaderView

#pragma mark Getters and setters

- (void)setTitle:(NSString *)title
{
    _title = title;
    
    self.titleLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleTitle];
    self.titleLabel.text = title;
}

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    UIColor *backgroundColor = UIColor.play_popoverGrayColor;
    self.backgroundColor = backgroundColor;
    
    self.titleLabel.backgroundColor = backgroundColor;
    self.titleLabel.textColor = UIColor.whiteColor;
}

#pragma mark Accessibility

- (BOOL)isAccessibilityElement
{
    return YES;
}

@end
