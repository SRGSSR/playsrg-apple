//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SearchSettingMultiSelectionViewController.h"

#import "SearchSettingSelectorCell.h"
#import "UIColor+PlaySRG.h"
#import "UIViewController+PlaySRG.h"

#import <libextobjc/libextobjc.h>
#import <SRGAppearance/SRGAppearance.h>

@implementation SRGBucket (SearchSettingsBucket)

- (NSString *)title
{
    return [self respondsToSelector:@selector(title)] ? [self performSelector:@selector(title)] : nil;
}

@end

@interface SearchSettingMultiSelectionViewController ()

@property (nonatomic, copy) NSString *identifier;
@property (nonatomic) NSArray<SearchSettingsMultiSelectionItem *> *items;
@property (nonatomic) NSArray<NSString *> *selectedvalues;

@property (nonatomic, weak) IBOutlet UITableView *tableView;

@end

@implementation SearchSettingMultiSelectionViewController

#pragma mark Object lifecycle

- (instancetype)initWithTitle:(NSString *)title identifier:(NSString *)identifier items:(NSArray<SearchSettingsMultiSelectionItem *> *)items selectedValues:(nullable NSArray<NSString *> *)selectedvalues
{
    if (self = [super init]) {
        self.title = title;
        self.identifier = identifier;
        self.items = items;
        self.selectedvalues = selectedvalues;
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

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}

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

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    SearchSettingSelectorCell *selectorCell = (SearchSettingSelectorCell *)cell;
    selectorCell.name = [NSString stringWithFormat:@"%@ (%@)", self.items[indexPath.row].name, [NSNumberFormatter localizedStringFromNumber:@(self.items[indexPath.row].count) numberStyle:NSNumberFormatterDecimalStyle]];
    selectorCell.accessoryType = ([self.selectedvalues containsObject:self.items[indexPath.row].value]) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    SearchSettingsMultiSelectionItem *item = self.items[indexPath.row];
    if ([self.selectedvalues containsObject:item.value]) {
        NSMutableArray *selectedvalues = self.selectedvalues.mutableCopy;
        [selectedvalues removeObject:item.value];
        self.selectedvalues = (selectedvalues.count > 0) ? selectedvalues.copy : nil;
    }
    else {
        NSMutableArray *selectedvalues = self.selectedvalues ? self.selectedvalues.mutableCopy : @[].mutableCopy;
        [selectedvalues addObject:item.value];
        
        NSArray<NSString *> *itemValues = [self.items valueForKey:@keypath(SearchSettingsMultiSelectionItem.new, value)];
        [selectedvalues sortUsingComparator:^NSComparisonResult(NSString *value1, NSString *value2) {
            return [@([itemValues indexOfObject:value1]) compare:@([itemValues indexOfObject:value2])];
        }];
        self.selectedvalues = selectedvalues.copy;
    }
    
    [self.delegate searchSettingMultiSelectionViewController:self didUpdateSelectedValues:self.selectedvalues.copy];
    
    [self.tableView reloadData];
}

@end
