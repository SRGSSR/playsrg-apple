//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SearchSettingsViewController.h"

#import "AnalyticsConstants.h"
#import "ApplicationConfiguration.h"
#import "SearchSettingsHeaderView.h"
#import "SearchSettingSelectorCell.h"
#import "SearchSettingSegmentCell.h"
#import "SearchSettingSwitchCell.h"
#import "SearchSettingMultiSelectionViewController.h"
#import "UIColor+PlaySRG.h"
#import "UIViewController+PlaySRG.h"

#import <libextobjc/libextobjc.h>

static NSInteger const kLastDay = 1;
static NSInteger const kLastThreeDays = 3;
static NSInteger const kLastWeek = 7;
static NSInteger const kLastMonth = 30;

typedef NS_ENUM(NSInteger, SearchSettingPeriod) {
    SearchSettingPeriodNone = 0,
    SearchSettingPeriodLastDay,
    SearchSettingPeriodLastThreeDays,
    SearchSettingPeriodLastWeek,
    SearchSettingPeriodLastMonth
};

static SearchSettingPeriod SearchSettingPeriodForSettings(SRGMediaSearchSettings *settings)
{
    NSDate *afterDate = settings.afterDate;
    if (! afterDate) {
        return SearchSettingPeriodNone;
    }
    
    NSDateComponents *components = [NSCalendar.currentCalendar components:NSCalendarUnitDay fromDate:settings.afterDate toDate:NSDate.date options:0];
    if (components.day >= kLastMonth) {
        return SearchSettingPeriodLastMonth;
    }
    else if (components.day >= kLastWeek) {
        return SearchSettingPeriodLastWeek;
    }
    else if (components.day >= kLastThreeDays) {
        return SearchSettingPeriodLastThreeDays;
    }
    else if (components.day >= kLastDay) {
        return SearchSettingPeriodLastDay;
    }
    else {
        return SearchSettingPeriodNone;
    }
}

@interface SearchSettingsViewController () <SearchSettingsMultiSelectionViewControllerDelegate>

@property (nonatomic, copy) NSString *query;
@property (nonatomic) SRGMediaSearchSettings *settings;

@property (nonatomic) SRGMediaAggregations *aggregations;

@property (nonatomic, weak) IBOutlet UITableView *tableView;

@end

@implementation SearchSettingsViewController

#pragma mark Object lifecycle

- (instancetype)initWithQuery:(NSString *)query settings:(SRGMediaSearchSettings *)settings
{
    if (self = [super init]) {
        self.query = query;
        self.settings = [settings copy] ?: [[SRGMediaSearchSettings alloc] init];
        self.settings.aggregationsEnabled = YES;
    }
    return self;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    return [self initWithQuery:nil settings:SRGMediaSearchSettings.new];
}

#pragma clang diagnostic pop

#pragma mark Getters and setters

- (NSString *)title
{
    return NSLocalizedString(@"Search filters", @"Search filters page title");
}

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
    
    NSString *headerIdentifier = NSStringFromClass(SearchSettingsHeaderView.class);
    UINib *headerViewNib = [UINib nibWithNibName:headerIdentifier bundle:nil];
    [self.tableView registerNib:headerViewNib forHeaderFooterViewReuseIdentifier:headerIdentifier];
    
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Reset", @"Title of the reset search settings button")
                                                                             style:UIBarButtonItemStylePlain
                                                                            target:self
                                                                            action:@selector(resetSettings:)];
    
    if (! self.popoverPresentationController) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Apply", @"Title of the search settings button to apply settings")
                                                                                  style:UIBarButtonItemStylePlain
                                                                                 target:self
                                                                                 action:@selector(close:)];
    }
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];
    
    [self.tableView flashScrollIndicators];
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

#pragma mark Overrides

- (void)prepareRefreshWithRequestQueue:(SRGRequestQueue *)requestQueue
{
    ApplicationConfiguration *applicationConfiguration = ApplicationConfiguration.sharedApplicationConfiguration;
    SRGBaseRequest *request = [SRGDataProvider.currentDataProvider mediasForVendor:applicationConfiguration.vendor matchingQuery:self.query withSettings:self.settings completionBlock:^(NSArray<NSString *> * _Nullable mediaURNs, NSNumber * _Nonnull total, SRGMediaAggregations * _Nullable aggregations, NSArray<SRGSearchSuggestion *> * _Nullable suggestions, SRGPage * _Nonnull page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error) {
        self.aggregations = aggregations;
        [self.tableView reloadData];
    }];
    [requestQueue addRequest:request resume:YES];
}

- (void)refreshDidStart
{}

- (void)refreshDidFinishWithError:(NSError *)error
{}

#pragma mark UI

- (NSString *)titleForSection:(NSInteger)section
{
    static dispatch_once_t s_onceToken;
    static NSDictionary<NSNumber *, NSString *> *s_titles;
    dispatch_once(&s_onceToken, ^{
        s_titles = @{ @1 : NSLocalizedString(@"Period", @"Settings section header"),
                      @2 : NSLocalizedString(@"Duration", @"Settings section header"),
                      @3 : NSLocalizedString(@"Properties", @"Settings section header") };
    });
    return s_titles[@(section)];
}

#pragma mark Updates

- (void)updateResults
{
    SRGMediaSearchSettings *settings = [self.settings copy];
    settings.aggregationsEnabled = NO;
    [self.delegate searchSettingsViewController:self didUpdateSettings:settings];
    
    [self refresh];
}

#pragma mark SRGAnalyticsViewTracking protocol

- (NSString *)srg_pageViewTitle
{
    return self.title;
}

- (NSArray<NSString *> *)srg_pageViewLevels
{
    return @[ AnalyticsNameForPageType(AnalyticsPageTypeSearch) ];
}

#pragma mark UITableViewDataSource protocol

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 4;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    static dispatch_once_t s_onceToken;
    static NSDictionary<NSNumber *, NSNumber *> *s_rows;
    dispatch_once(&s_onceToken, ^{
        if (@available(iOS 11, *)) {
            s_rows = @{ @0 : @2,
                        @1 : @4,
                        @2 : @1,
                        @3 : @2 };
        }
        else {
            s_rows = @{ @0 : @3,
                        @1 : @4,
                        @2 : @1,
                        @3 : @2 };
        }
    });
    
    return s_rows[@(section)].integerValue;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static dispatch_once_t s_onceToken;
    static NSDictionary<NSNumber *, NSDictionary<NSNumber *, Class> *> *s_cellClasses;
    dispatch_once(&s_onceToken, ^{
        if (@available(iOS 11, *)) {
            s_cellClasses = @{ @0 : @{ @0 : SearchSettingSelectorCell.class,
                                       @1 : SearchSettingSelectorCell.class },
                               @1 : @{ @0 : SearchSettingSelectorCell.class,
                                       @1 : SearchSettingSelectorCell.class,
                                       @2 : SearchSettingSelectorCell.class,
                                       @3 : SearchSettingSelectorCell.class },
                               @2 : @{ @0 : SearchSettingSegmentCell.class },
                               @3 : @{ @0 : SearchSettingSwitchCell.class,
                                       @1 : SearchSettingSwitchCell.class } };
        }
        else {
            s_cellClasses = @{ @0 : @{ @0 : SearchSettingSegmentCell.class,
                                       @1 : SearchSettingSelectorCell.class,
                                       @2 : SearchSettingSelectorCell.class },
                               @1 : @{ @0 : SearchSettingSelectorCell.class,
                                       @1 : SearchSettingSelectorCell.class,
                                       @2 : SearchSettingSelectorCell.class,
                                       @3 : SearchSettingSelectorCell.class },
                               @2 : @{ @0 : SearchSettingSegmentCell.class },
                               @3 : @{ @0 : SearchSettingSwitchCell.class,
                                       @1 : SearchSettingSwitchCell.class } };
        }
    });
    Class cellClass = s_cellClasses[@(indexPath.section)][@(indexPath.row)];
    return [tableView dequeueReusableCellWithIdentifier:NSStringFromClass(cellClass) forIndexPath:indexPath];
}

#pragma mark UITableViewDelegate protocol

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    SRGMediaSearchSettings *settings = self.settings;
    
    switch (indexPath.section) {
        case 0: {
            SearchSettingSelectorCell *selectorCell = (SearchSettingSelectorCell *)cell;
            
            if (@available(iOS 11, *)) {
                switch (indexPath.row) {
                    case 0: {
                        NSString *name = NSLocalizedString(@"Categories", @"Categories search setting option");
                        if (self.settings.topicURNs.count > 0) {
                            name = [NSString stringWithFormat:@"%@ (%lu selected)", name, (unsigned long)self.settings.topicURNs.count];
                        }
                        selectorCell.name = name;
                        BOOL enabled = (self.aggregations.topicBuckets.count > 0);
                        selectorCell.userInteractionEnabled = enabled;
                        selectorCell.accessoryType = enabled ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
                        break;
                    }
                        
                    case 1: {
                        NSString *name = NSLocalizedString(@"Shows", @"Shows search setting option");
                        if (self.settings.showURNs.count > 0) {
                            name = [NSString stringWithFormat:@"%@ (%lu selected)", name, self.settings.showURNs.count];
                        }
                        selectorCell.name = name;
                        BOOL enabled = (self.aggregations.showBuckets.count > 0);
                        selectorCell.userInteractionEnabled = enabled;
                        selectorCell.accessoryType = enabled ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
                        break;
                    }
                        
                    default: {
                        break;
                    }
                }
            }
            else {
                switch (indexPath.row) {
                    case 0: {
                        SearchSettingSegmentCell *segmentCell = (SearchSettingSegmentCell *)cell;
                        
                        static dispatch_once_t s_onceToken;
                        static NSDictionary<NSNumber *, NSNumber *> *s_mediaTypes;
                        dispatch_once(&s_onceToken, ^{
                            s_mediaTypes = @{ @0 : @(SRGMediaTypeNone),
                                              @1 : @(SRGMediaTypeVideo),
                                              @2 : @(SRGMediaTypeAudio) };
                        });
                        
                        @weakify(self)
                        [segmentCell setItems:@[ NSLocalizedString(@"All", @"All option"), NSLocalizedString(@"Videos", @"Videos option"), NSLocalizedString(@"Audios", @"Audios option") ] reader:^NSInteger{
                            return [s_mediaTypes allKeysForObject:@(settings.mediaType)].firstObject.integerValue;
                        } writer:^(NSInteger index) {
                            @strongify(self)
                            
                            settings.mediaType = [s_mediaTypes[@(index)] integerValue];
                            [self updateResults];
                        }];
                        break;
                    }
                        
                    case 1: {
                        selectorCell.name = NSLocalizedString(@"Categories", @"Categories search setting option");
                        BOOL enabled = (self.aggregations.topicBuckets.count > 0);
                        selectorCell.userInteractionEnabled = enabled;
                        selectorCell.accessoryType = enabled ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
                        break;
                    }
                        
                    case 2: {
                        selectorCell.name = NSLocalizedString(@"Shows", @"Shows search setting option");
                        BOOL enabled = (self.aggregations.showBuckets.count > 0);
                        selectorCell.userInteractionEnabled = enabled;
                        selectorCell.accessoryType = enabled ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
                        break;
                    }
                        
                    default: {
                        break;
                    }
                }
            }
            break;
        }
            
        case 1: {
            SearchSettingSelectorCell *selectorCell = (SearchSettingSelectorCell *)cell;
            SearchSettingPeriod searchPeriod = SearchSettingPeriodForSettings(self.settings);
            
            switch (indexPath.row) {
                case 0: {
                    selectorCell.name = NSLocalizedString(@"The last 24 hours", @"Period setting option");
                    selectorCell.accessoryType = (searchPeriod == SearchSettingPeriodLastDay) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    break;
                }
                    
                case 1: {
                    selectorCell.name = NSLocalizedString(@"The last 3 days", @"Period setting option");
                    selectorCell.accessoryType = (searchPeriod == SearchSettingPeriodLastThreeDays) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    break;
                }
                    
                case 2: {
                    selectorCell.name = NSLocalizedString(@"The last week", @"Period setting option");
                    selectorCell.accessoryType = (searchPeriod == SearchSettingPeriodLastWeek) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    break;
                }
                    
                case 3: {
                    selectorCell.name = NSLocalizedString(@"The last month", @"Period setting option");
                    selectorCell.accessoryType = (searchPeriod == SearchSettingPeriodLastMonth) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
                    break;
                }
                    
                default: {
                    break;
                }
            }
            break;
        }
            
        case 2: {
            switch (indexPath.row) {
                case 0: {
                    SearchSettingSegmentCell *segmentCell = (SearchSettingSegmentCell *)cell;
                    
                    @weakify(self)
                    [segmentCell setItems:@[ NSLocalizedString(@"All", @"All option"), NSLocalizedString(@"< 5 min", @"Less than 5 min option"), NSLocalizedString(@"> 30 min", @"More than 3 min option") ] reader:^NSInteger{
                        if (! settings.minimumDurationInMinutes && ! settings.maximumDurationInMinutes) {
                            return 0;
                        }
                        else if (settings.maximumDurationInMinutes) {
                            return 1;
                        }
                        else {
                            return 2;
                        }
                    } writer:^(NSInteger index) {
                        @strongify(self)
                        
                        switch (index) {
                            case 0: {
                                settings.minimumDurationInMinutes = nil;
                                settings.maximumDurationInMinutes = nil;
                                break;
                            }
                                
                            case 1: {
                                settings.minimumDurationInMinutes = nil;
                                settings.maximumDurationInMinutes = @5;
                                break;
                            }
                                
                            case 2: {
                                settings.minimumDurationInMinutes = @30;
                                settings.maximumDurationInMinutes = nil;
                                break;
                            }
                                
                            default: {
                                break;
                            }
                        }
                        [self updateResults];
                    }];
                    break;
                }
                    
                default: {
                    break;
                }
            }
            break;
        }
            
        case 3: {
            switch (indexPath.row) {
                case 0: {
                    SearchSettingSwitchCell *switchCell = (SearchSettingSwitchCell *)cell;
                    
                    @weakify(self)
                    [switchCell setName:NSLocalizedString(@"Available for download", @"Download availability toggle name in search settings") reader:^BOOL{
                        return settings.downloadAvailable.boolValue;
                    } writer:^(BOOL value) {
                        @strongify(self)
                        
                        settings.downloadAvailable = @(value);
                        [self updateResults];
                    }];
                    break;
                }
                    
                case 1: {
                    SearchSettingSwitchCell *switchCell = (SearchSettingSwitchCell *)cell;
                    
                    @weakify(self)
                    [switchCell setName:NSLocalizedString(@"Playable abroad", @"Abroad playability toggle name in search settings") reader:^BOOL{
                        return settings.playableAbroad.boolValue;
                    } writer:^(BOOL value) {
                        @strongify(self)
                        
                        settings.playableAbroad = @(value);
                        [self updateResults];
                    }];
                    break;
                }
                    
                default: {
                    break;
                }
            }
            break;
        }
            
        default: {
            break;
        }
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    switch (indexPath.section) {
        case 0: {
            SearchSettingMultiSelectionViewController *multiSelectionViewController = nil;
            
            if (@available(iOS 11, *)) {
                switch (indexPath.row) {
                    case 0: {
                        multiSelectionViewController = [[SearchSettingMultiSelectionViewController alloc] initWithTitle:NSLocalizedString(@"Categories", @"Categories search setting option list view title")
                                                                                                                  items:self.aggregations.topicBuckets
                                                                                                         selectedValues:self.settings.topicURNs];
                        multiSelectionViewController.delegate = self;
                        [self.navigationController pushViewController:multiSelectionViewController animated:YES];
                        break;
                    }
                        
                    case 1: {
                        multiSelectionViewController = [[SearchSettingMultiSelectionViewController alloc] initWithTitle:NSLocalizedString(@"Shows", @"Shows search setting option list view title")
                                                                                                                  items:self.aggregations.showBuckets
                                                                                                         selectedValues:self.settings.showURNs];
                        multiSelectionViewController.delegate = self;
                        [self.navigationController pushViewController:multiSelectionViewController animated:YES];
                        break;
                    }
                        
                    default: {
                        break;
                    }
                }
            }
            else {
                switch (indexPath.row) {
                    case 1: {
                        multiSelectionViewController = [[SearchSettingMultiSelectionViewController alloc] initWithTitle:NSLocalizedString(@"Categories", @"Categories search setting option list view title")
                                                                                                                  items:self.aggregations.topicBuckets
                                                                                                         selectedValues:self.settings.topicURNs];
                        multiSelectionViewController.delegate = self;
                        [self.navigationController pushViewController:multiSelectionViewController animated:YES];
                        break;
                    }
                        
                    case 2: {
                        multiSelectionViewController = [[SearchSettingMultiSelectionViewController alloc] initWithTitle:NSLocalizedString(@"Shows", @"Shows search setting option list view title")
                                                                                                                  items:self.aggregations.showBuckets
                                                                                                         selectedValues:self.settings.showURNs];
                        multiSelectionViewController.delegate = self;
                        [self.navigationController pushViewController:multiSelectionViewController animated:YES];
                        break;
                    }
                        
                    default: {
                        break;
                    }
                }
            }
            break;
        }
            
        case 1: {
            SearchSettingPeriod period = SearchSettingPeriodForSettings(self.settings);
            
            switch (indexPath.row) {
                case 0: {
                    NSDateComponents *components = [[NSDateComponents alloc] init];
                    components.day = -kLastDay;
                    self.settings.afterDate = (period != SearchSettingPeriodLastDay) ? [NSCalendar.currentCalendar dateByAddingComponents:components toDate:NSDate.date options:0] : nil;
                    break;
                }
                    
                case 1: {
                    NSDateComponents *components = [[NSDateComponents alloc] init];
                    components.day = -kLastThreeDays;
                    self.settings.afterDate = (period != SearchSettingPeriodLastThreeDays) ? [NSCalendar.currentCalendar dateByAddingComponents:components toDate:NSDate.date options:0] : nil;
                    break;
                }
                    
                case 2: {
                    NSDateComponents *components = [[NSDateComponents alloc] init];
                    components.day = -kLastWeek;
                    self.settings.afterDate = (period != SearchSettingPeriodLastWeek) ? [NSCalendar.currentCalendar dateByAddingComponents:components toDate:NSDate.date options:0] : nil;
                    break;
                }
                    
                case 3: {
                    NSDateComponents *components = [[NSDateComponents alloc] init];
                    components.day = -kLastMonth;
                    self.settings.afterDate = (period != SearchSettingPeriodLastMonth) ? [NSCalendar.currentCalendar dateByAddingComponents:components toDate:NSDate.date options:0] : nil;
                    break;
                }
                    
                default: {
                    break;
                }
            }
            [self.tableView reloadData];
            [self updateResults];
            break;
        }
            
        default: {
            break;
        }
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    NSString *title = [self titleForSection:section];
    return title.length != 0 ? 60.f : 0.f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    SearchSettingsHeaderView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:NSStringFromClass(SearchSettingsHeaderView.class)];
    headerView.title = [self titleForSection:section];
    return headerView;
}

#pragma mark SearchSettingsMultiSelectionViewControllerDelegate protocol

- (void)searchSettingsViewController:(SearchSettingMultiSelectionViewController *)searchSettingsViewController didUpdateSelectedItems:(nullable NSArray<NSString *> *)selectedItems forItemClass:(Class)itemClass
{
    if (itemClass == SRGTopicBucket.class) {
        self.settings.topicURNs = selectedItems;
        [self updateResults];
    }
    else if (itemClass == SRGShowBucket.class) {
        self.settings.showURNs = selectedItems;
        [self updateResults];
    }
    
    [self.tableView reloadSections:[NSIndexSet indexSetWithIndex:0] withRowAnimation:UITableViewRowAnimationNone];
}

#pragma mark Actions

- (IBAction)close:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)resetSettings:(id)sender
{
    SRGMediaType previousMediaType = self.settings.mediaType;
    
    self.settings = [[SRGMediaSearchSettings alloc] init];
    
    if (@available(iOS 11, *)) {
        self.settings.mediaType = previousMediaType;
    }
    
    [self updateResults];
    
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPad) {
        [self.tableView reloadData];
    }
    else {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
}

@end
