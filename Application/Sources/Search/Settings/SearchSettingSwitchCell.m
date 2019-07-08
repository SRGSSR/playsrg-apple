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
@property (nonatomic, weak) IBOutlet UISwitch *valueSwitch;

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

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    self.backgroundColor = UIColor.play_popoverGrayColor;
    self.nameLabel.textColor = UIColor.whiteColor;
    
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

#pragma mark UI

- (void)reloadData
{
    self.nameLabel.text = self.name;
    self.nameLabel.font = [UIFont srg_mediumFontWithTextStyle:UIFontTextStyleBody];
    
    self.valueSwitch.on = self.reader ? self.reader() : NO;
}

#pragma mark Actions

- (IBAction)valueChanged:(id)sender
{
    if (self.writer) {
        self.writer(self.valueSwitch.on);
    }
}

@end
