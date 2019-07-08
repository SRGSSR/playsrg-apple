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

@implementation SRGBucket (SearchSettingsBucket)

- (NSString *)title {
    return [self respondsToSelector:@selector(title)] ? [self performSelector:@selector(title)] : nil;
}

@end

@interface SearchSettingMultiSelectionViewController ()

@property (nonatomic) NSArray<id <SearchSettingsMultiSelectionItem>> *items;
@property (nonatomic) NSArray<NSString *> *selectedvalues;

@property (nonatomic, weak) IBOutlet UITableView *tableView;

@end

@implementation SearchSettingMultiSelectionViewController

#pragma mark Object lifecycle

- (instancetype)initWithTitle:(NSString *)title items:(NSArray<id <SearchSettingsMultiSelectionItem>> *)items selectedValues:(NSArray<NSString *> *)selectedvalues
{
    if (self = [super init]) {
        self.title = title;
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
    return [self initWithTitle:@"" items:@[] selectedValues:nil];
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
    self.tableView.estimatedRowHeight = 44.f;
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

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    SearchSettingSelectorCell *selectorCell = (SearchSettingSelectorCell *)cell;
    selectorCell.name = [NSString stringWithFormat:@"%@ (%@)", self.items[indexPath.row].name, [NSNumberFormatter localizedStringFromNumber:@(self.items[indexPath.row].count) numberStyle:NSNumberFormatterDecimalStyle]];
    selectorCell.accessoryType = ([self.selectedvalues containsObject:self.items[indexPath.row].value]) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    id <SearchSettingsMultiSelectionItem> item = self.items[indexPath.row];
    if ([self.selectedvalues containsObject:item.value]) {
        NSMutableArray *selectedvalues = self.selectedvalues.mutableCopy;
        [selectedvalues removeObject:item.value];
        self.selectedvalues = (selectedvalues.count > 0) ? selectedvalues.copy : nil;
    }
    else {
        NSMutableArray *selectedvalues = self.selectedvalues ? self.selectedvalues.mutableCopy : @[].mutableCopy;
        [selectedvalues addObject:item.value];
        
        // keep values order
        // TODO: Safer valueForKey
        NSArray<NSString *> *itemValues = [self.items valueForKey:@"value"];
        [selectedvalues sortUsingComparator:^NSComparisonResult(NSString *value1, NSString *value2) {
            return [@([itemValues indexOfObject:value1]) compare:@([itemValues indexOfObject:value2])];
        }];
        self.selectedvalues = selectedvalues.copy;
    }
    
    if (self.delegate) {
        [self.delegate searchSettingsViewController:self didUpdateSelectedItems:self.selectedvalues.copy forItemClass:self.items[0].class];
    }
    
    [self.tableView reloadData];
}

@end

@implementation SRGTopicBucket (SearchSettingsMultiSelection)

- (NSString *)name
{
    return self.title;
}

- (NSString *)value
{
    return self.URN;
}

@end

@implementation SRGShowBucket (SearchSettingsMultiSelection)

- (NSString *)name
{
    return self.title;
}

- (NSString *)value
{
    return self.URN;
}

@end
