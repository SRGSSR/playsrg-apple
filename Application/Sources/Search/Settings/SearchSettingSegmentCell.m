//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SearchSettingSegmentCell.h"

#import "UIColor+PlaySRG.h"

@import SRGAppearance;

@interface SearchSettingSegmentCell ()

@property (nonatomic) NSArray<NSString *> *items;

@property (nonatomic, copy) NSInteger (^reader)(void);
@property (nonatomic, copy) void (^writer)(NSInteger index);

@property (nonatomic, weak) IBOutlet UISegmentedControl *segmentedControl;

@end

@implementation SearchSettingSegmentCell

#pragma mark Getters and setters

- (void)setItems:(NSArray<NSString *> *)items reader:(NSInteger (^)(void))reader writer:(void (^)(NSInteger))writer
{
    self.items = items;
    
    self.reader = reader;
    self.writer = writer;
    
    [self reloadData];
}

#pragma mark Overrides

- (void)awakeFromNib
{
    [super awakeFromNib];
    
    [self.segmentedControl setTitleTextAttributes:@{ NSFontAttributeName : [UIFont srg_regularFontWithSize:16.f] }
                                         forState:UIControlStateNormal];
    
    self.backgroundColor = UIColor.play_popoverGrayBackgroundColor;
    self.selectionStyle = UITableViewCellSelectionStyleNone;
}

#pragma mark UI

- (void)reloadData
{
    [self.segmentedControl removeAllSegments];
    [self.items enumerateObjectsUsingBlock:^(NSString * _Nonnull item, NSUInteger idx, BOOL * _Nonnull stop) {
        [self.segmentedControl insertSegmentWithTitle:item atIndex:idx animated:NO];
    }];
    self.segmentedControl.selectedSegmentIndex = self.reader ? self.reader() : UISegmentedControlNoSegment;
}

#pragma mark Actions

- (IBAction)valueChanged:(id)sender
{
    if (self.writer) {
        self.writer(self.segmentedControl.selectedSegmentIndex);
    }
}

@end
