//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SearchSettingMultiSelectionViewController.h"

#import "NSArray+PlaySRG.h"
#import "SearchSettingSelectorCell.h"
#import "UIColor+PlaySRG.h"
#import "UIViewController+PlaySRG.h"

#import <libextobjc/libextobjc.h>
#import <SRGAppearance/SRGAppearance.h>

@interface SearchSettingMultiSelectionViewController ()

@property (nonatomic, copy) NSString *identifier;
@property (nonatomic) NSArray<SearchSettingsMultiSelectionItem *> *items;
@property (nonatomic) NSArray<NSString *> *selectedValues;

@property (nonatomic, weak) IBOutlet UITableView *tableView;

@end

@implementation SearchSettingMultiSelectionViewController

#pragma mark Object lifecycle

- (instancetype)initWithTitle:(NSString *)title identifier:(NSString *)identifier items:(NSArray<SearchSettingsMultiSelectionItem *> *)items selectedValues:(nullable NSArray<NSString *> *)selectedValues
{
    if (self = [super init]) {
        self.title = title;
        self.identifier = identifier;
        self.items = items;
        self.selectedValues = selectedValues ?: @[];
    }
    return self;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    return [self initWithTitle:@"" identifier:@"" items:@[] selectedValues:nil];
}

#pragma clang diagnostic pop

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = UIColor.play_popoverGrayColor;
    
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = UIColor.clearColor;
    self.tableView.separatorColor = UIColor.clearColor;
    self.tableView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
}

#pragma mark Rotation

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return [super supportedInterfaceOrientations] & UIViewController.play_supportedInterfaceOrientations;
}

#pragma mark Status bar

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#pragma mark Accessibility

- (void)updateForContentSizeCategory
{
    [super updateForContentSizeCategory];
    
    [self.tableView reloadData];
}

#pragma mark UITableViewDataSource protocol

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.items.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [tableView dequeueReusableCellWithIdentifier:NSStringFromClass(SearchSettingSelectorCell.class) forIndexPath:indexPath];
}

#pragma mark UITableViewDelegate protocol

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *contentSizeCategory = UIApplication.sharedApplication.preferredContentSizeCategory;
    if (SRGAppearanceCompareContentSizeCategories(contentSizeCategory, UIContentSizeCategoryExtraLarge) == NSOrderedDescending) {
        return 55.f;
    }
    else if (SRGAppearanceCompareContentSizeCategories(contentSizeCategory, UIContentSizeCategorySmall) == NSOrderedDescending) {
        return 50.f;
    }
    else {
        return 45.f;
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(SearchSettingSelectorCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    SearchSettingsMultiSelectionItem *item = self.items[indexPath.row];
    cell.name = [NSString stringWithFormat:@"%@ (%@)", item.name, [NSNumberFormatter localizedStringFromNumber:@(item.count) numberStyle:NSNumberFormatterDecimalStyle]];
    cell.accessoryType = [self.selectedValues containsObject:item.value] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    SearchSettingsMultiSelectionItem *item = self.items[indexPath.row];
    if ([self.selectedValues containsObject:item.value]) {
        self.selectedValues = [self.selectedValues play_arrayByRemovingObjectsInArray:@[ item.value ]];
    }
    else {
        self.selectedValues = [self.selectedValues arrayByAddingObject:item.value];
    }
    
    [self.delegate searchSettingMultiSelectionViewController:self didUpdateSelectedValues:self.selectedValues];
    
    [self.tableView reloadData];
}

@end
