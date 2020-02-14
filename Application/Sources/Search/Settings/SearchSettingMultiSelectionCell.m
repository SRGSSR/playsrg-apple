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
@property (nonatomic, weak) IBOutlet UILabel *valuesLabel;

@end

@implementation SearchSettingMultiSelectionCell

#pragma mark Getters and setters

- (void)setName:(NSString *)name values:(NSArray<NSString *> *)values
{
    self.nameLabel.font = [UIFont srg_mediumFontWithTextStyle:SRGAppearanceFontTextStyleTitle];
    self.nameLabel.text = name;
    
    self.valuesLabel.font = [UIFont srg_regularFontWithTextStyle:SRGAppearanceFontTextStyleBody];
    self.valuesLabel.text = [values componentsJoinedByString:@", "];
}

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.backgroundColor = UIColor.play_popoverGrayBackgroundColor;
    
    self.tintColor = UIColor.whiteColor;
    
    self.nameLabel.textColor = UIColor.whiteColor;
    self.valuesLabel.textColor = UIColor.grayColor;
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
    self.valuesLabel.hidden = ! userInteractionEnabled;
}

@end
