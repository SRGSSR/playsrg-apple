//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SearchSettingMultiSelectionCell.h"

#import "UIColor+PlaySRG.h"

#import <SRGAppearance/SRGAppearance.h>

@interface SearchSettingMultiSelectionCell ()

@property (nonatomic, weak) IBOutlet UILabel *nameLabel;

@end

@implementation SearchSettingMultiSelectionCell

#pragma mark Getters and setters

- (void)setName:(NSString *)name
{
    _name = name;
    
    self.nameLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleTitle];
    self.nameLabel.text = name;
}

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    UIColor *backgroundColor = UIColor.play_popoverGrayColor;
    self.backgroundColor = backgroundColor;
    
    self.tintColor = UIColor.whiteColor;
    
    self.nameLabel.backgroundColor = backgroundColor;
    self.nameLabel.textColor = UIColor.whiteColor;
}

- (void)prepareForReuse
{
    [super prepareForReuse];
    
    self.userInteractionEnabled = YES;
}

- (void)setUserInteractionEnabled:(BOOL)userInteractionEnabled
{
    [super setUserInteractionEnabled:userInteractionEnabled];
    
    self.nameLabel.enabled = userInteractionEnabled;
}

@end
