//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SearchSettingSwitchCell.h"

#import "UIColor+PlaySRG.h"

#import <SRGAppearance/SRGAppearance.h>

@interface SearchSettingSwitchCell ()

@property (nonatomic, copy) NSString *name;

@property (nonatomic, copy) BOOL (^reader)(void);
@property (nonatomic, copy) void (^writer)(BOOL value);

@property (nonatomic, weak) IBOutlet UILabel *nameLabel;

@property (nonatomic, readonly) UISwitch *valueSwitch;

@end

@implementation SearchSettingSwitchCell

#pragma mark Getters and setters

- (void)setName:(NSString *)name reader:(BOOL (^)(void))reader writer:(void (^)(BOOL))writer
{
    self.name = name;
    
    self.reader = reader;
    self.writer = writer;
    
    [self reloadData];
}

- (UISwitch *)valueSwitch
{
    return (UISwitch *)self.accessoryView;
}

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    UIColor *backgroundColor = UIColor.play_popoverGrayColor;
    self.backgroundColor = backgroundColor;
    
    self.nameLabel.backgroundColor = backgroundColor;
    self.nameLabel.textColor = UIColor.whiteColor;
    
    // Setting a `UISwitch` as accessory view of a cell works just as expected with VoiceOver
    // See https://stackoverflow.com/a/24517965/760435
    UISwitch *valueSwitch = [[UISwitch alloc] init];
    [valueSwitch addTarget:self action:@selector(valueChanged:) forControlEvents:UIControlEventValueChanged];
    self.accessoryView = valueSwitch;
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

#pragma mark UI

- (void)reloadData
{
    self.nameLabel.text = self.name;
    self.nameLabel.font = [UIFont srg_regularFontWithTextStyle:SRGAppearanceFontTextStyleBody];
    
    self.valueSwitch.on = self.reader ? self.reader() : NO;
}

#pragma mark Actions

- (void)valueChanged:(id)sender
{
    if (self.writer) {
        self.writer(self.valueSwitch.on);
    }
}

@end
