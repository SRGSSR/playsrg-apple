//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SearchSettingSwitchCell.h"

#import "UIColor+PlaySRG.h"

#import <SRGAppearance/SRGAppearance.h>

@interface SearchSettingSwitchCell ()

@property (nonatomic) BOOL *pValue;

@property (nonatomic) id object;
@property (nonatomic, copy) NSString *key;
@property (nonatomic, copy) NSString *name;

@property (nonatomic, weak) IBOutlet UILabel *nameLabel;
@property (nonatomic, weak) IBOutlet UISwitch *valueSwitch;

@end

@implementation SearchSettingSwitchCell

#pragma mark Getters and setters

- (void)setObject:(id)object key:(NSString *)key name:(NSString *)name
{
    self.object = object;
    self.key = key;
    self.name = name;
    
    [self reloadData];
}

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.backgroundColor = UIColor.play_popoverGrayColor;
    
    self.nameLabel.font = [UIFont srg_mediumFontWithTextStyle:UIFontTextStyleBody];
    self.nameLabel.textColor = UIColor.whiteColor;
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

#pragma mark UI

- (void)reloadData
{
    self.nameLabel.text = self.name;
    self.valueSwitch.on = [[self.object valueForKey:self.key] boolValue];
}

#pragma mark Actions

- (IBAction)valueChanged:(id)sender
{
    [self.object setValue:@(self.valueSwitch.on) forKey:self.key];
}

@end
