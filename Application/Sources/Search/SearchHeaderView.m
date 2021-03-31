//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SearchHeaderView.h"

#import "Layout.h"

@import SRGAppearance;

@interface SearchHeaderView ()

@property (nonatomic, weak) IBOutlet UILabel *titleLabel;

@property (nonatomic, weak) IBOutlet NSLayoutConstraint *leadingTitleLabelLayoutConstraint;
@property (nonatomic, weak) IBOutlet NSLayoutConstraint *trailingTitleLabelLayoutConstraint;

@end

@implementation SearchHeaderView

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.titleLabel.textColor = UIColor.whiteColor;
    
    self.leadingTitleLabelLayoutConstraint.constant = LayoutStandardMargin;
    self.trailingTitleLabelLayoutConstraint.constant = LayoutStandardMargin;
}

#pragma mark Getters and setters

- (void)setTitle:(NSString *)title
{
    _title = title;
    
    self.titleLabel.text = title;
    self.titleLabel.font = [SRGFont fontWithStyle:SRGFontStyleH1];
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
