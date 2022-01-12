//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SearchSettingMultiSelectionViewController.h"

#import "NSSet+PlaySRG.h"
#import "SearchSettingSelectorCell.h"
#import "PlaySRG-Swift.h"
#import "TableView.h"
#import "UIColor+PlaySRG.h"
#import "UIViewController+PlaySRG.h"

@import libextobjc;
@import SRGAppearance;

@interface SearchSettingMultiSelectionViewController ()

@property (nonatomic, copy) NSString *identifier;
@property (nonatomic) NSArray<SearchSettingsMultiSelectionItem *> *items;
@property (nonatomic) NSSet<NSString *> *selectedValues;

@property (nonatomic) NSArray<SearchSettingsMultiSelectionItem *> *filteredItems;

@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, weak) IBOutlet SearchBar *searchBar;

@end

@implementation SearchSettingMultiSelectionViewController

#pragma mark Object lifecycle

- (instancetype)initWithTitle:(NSString *)title identifier:(NSString *)identifier items:(NSArray<SearchSettingsMultiSelectionItem *> *)items selectedValues:(NSSet<NSString *> *)selectedValues
{
    if (self = [self initFromStoryboard]) {
        self.title = title;
        self.identifier = identifier;
        self.items = items;
        self.filteredItems = items;
        self.selectedValues = selectedValues;
    }
    return self;
}

- (instancetype)initFromStoryboard
{
    UIStoryboard *storyboard = [UIStoryboard storyboardWithName:NSStringFromClass(self.class) bundle:nil];
    return storyboard.instantiateInitialViewController;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    return [self initWithTitle:@"" identifier:@"" items:@[] selectedValues:NSSet.set];
}

#pragma clang diagnostic pop

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = UIColor.play_popoverGrayBackgroundColor;
    
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = UIColor.clearColor;
    TableViewConfigure(self.tableView);
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    self.tableView.emptyDataSetSource = self;
    
    self.searchBar.placeholder = NSLocalizedString(@"Search", @"Search placeholder text");
    self.searchBar.autocapitalizationType = UITextAutocapitalizationTypeNone;
    self.searchBar.delegate = self;
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

#pragma mark DZNEmptyDataSetSource protocol

- (NSAttributedString *)titleForEmptyDataSet:(UIScrollView *)scrollView
{
    return [[NSAttributedString alloc] initWithString:NSLocalizedString(@"No results", @"Default text displayed when no results are available")
                                           attributes:@{ NSFontAttributeName : [SRGFont fontWithStyle:SRGFontStyleH2],
                                                         NSForegroundColorAttributeName : UIColor.whiteColor }];
}

#pragma mark UIScrollViewDelegate protocol

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView.dragging && ! scrollView.decelerating) {
        [self.searchBar resignFirstResponder];
    }
}

#pragma mark UISearchBarDelegate protocol

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText
{
    NSString *query = searchBar.text;
    if (query.length != 0) {
        NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(SearchSettingsMultiSelectionItem * _Nullable item, NSDictionary<NSString *,id> * _Nullable bindings) {
            return [item.name localizedCaseInsensitiveContainsString:query];
        }];
        self.filteredItems = [self.items filteredArrayUsingPredicate:predicate];
    }
    else {
        self.filteredItems = self.items;
    }
    [self.tableView reloadData];
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar
{
    [searchBar resignFirstResponder];
}

#pragma mark UITableViewDataSource protocol

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return self.filteredItems.count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return [tableView dequeueReusableCellWithIdentifier:NSStringFromClass(SearchSettingSelectorCell.class) forIndexPath:indexPath];
}

#pragma mark UITableViewDelegate protocol

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    UIContentSizeCategory contentSizeCategory = UIApplication.sharedApplication.preferredContentSizeCategory;
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
    SearchSettingsMultiSelectionItem *item = self.filteredItems[indexPath.row];
    cell.name = [NSString stringWithFormat:@"%@ (%@)", item.name, [NSNumberFormatter localizedStringFromNumber:@(item.count) numberStyle:NSNumberFormatterDecimalStyle]];
    cell.accessoryType = [self.selectedValues containsObject:item.value] ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    SearchSettingsMultiSelectionItem *item = self.filteredItems[indexPath.row];
    if ([self.selectedValues containsObject:item.value]) {
        self.selectedValues = [self.selectedValues play_setByRemovingObjectsInSet:[NSSet setWithObject:item.value]];
    }
    else {
        self.selectedValues = [self.selectedValues setByAddingObject:item.value];
    }
    
    [self.delegate searchSettingMultiSelectionViewController:self didUpdateSelectedValues:self.selectedValues];
    
    [self.tableView reloadData];
}

@end
