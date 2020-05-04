//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ProgramHeaderView.h"

#import "UIColor+PlaySRG.h"

#import <SRGAppearance/SRGAppearance.h>

@interface ProgramHeaderView ()

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;

@end

@implementation ProgramHeaderView

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.contentView.backgroundColor = UIColor.play_blackColor;
    self.titleLabel.textColor = UIColor.whiteColor;
}

#pragma mark Getters and setters

- (void)setTitle:(NSString *)title
{
    _title = title;
    
    self.titleLabel.text = title;
    self.titleLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleTitle];
}

#pragma mark Accessibility

- (BOOL)isAccessibilityElement
{
    return YES;
}

- (NSString *)accessibilityLabel
{
    return self.titleLabel.text;
}

- (UIAccessibilityTraits)accessibilityTraits
{
    return UIAccessibilityTraitHeader;
}

@end
