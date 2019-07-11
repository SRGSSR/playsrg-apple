//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SearchSettingsViewController.h"

#import "AnalyticsConstants.h"
#import "ApplicationConfiguration.h"
#import "NSArray+PlaySRG.h"
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

@interface SRGTopicBucket (SearchSettings)

@property (nonatomic, readonly) SearchSettingsMultiSelectionItem *multiSelectionItem;

@end

@interface SRGShowBucket (SearchSettings)

@property (nonatomic, readonly) SearchSettingsMultiSelectionItem *multiSelectionItem;

@end

@interface SearchSettingsViewController () <SearchSettingsMultiSelectionViewControllerDelegate>

@property (nonatomic, copy) NSString *query;
@property (nonatomic) SRGMediaSearchSettings *settings;

@property (nonatomic) SRGMediaAggregations *aggregations;

@property (nonatomic, weak) IBOutlet UITableView *tableView;

@end

@implementation SearchSettingsViewController

#pragma mark Class methods

+ (BOOL)displaysMediaTypeSelection
{
    // Media type selection is displayed as scope buttons on the main search view for iOS 11 and above. Built-in
    // support for search bar with scope buttons is namely available since iOS 11 only.
    if (@available(iOS 11, *)) {
        return NO;
    }
    // For simplicity, we display media type selection on the settings page for iOS versions prior to iOS 10.
    else {
        return YES;
    }
}

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
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Apply", @"Title of the search settings button to apply settings")
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(close:)];
    
    self.preferredContentSize = CGSizeMake(375.f, 600.f);
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
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.tableView flashScrollIndicators];
        });
    }];
    [requestQueue addRequest:request resume:YES];
}

#pragma mark Updates

- (void)updateResults
{
    SRGMediaSearchSettings *settings = [self.settings copy];
    settings.aggregationsEnabled = NO;
    [self.delegate searchSettingsViewController:self didUpdateSettings:settings];
    
    [self refresh];
}

#pragma mark Type-based table view methods

- (NSArray<NSString *> *)sectionTypesForTableView:(UITableView *)tableView
{
    static dispatch_once_t s_onceToken;
    static NSArray<NSString *> *s_types;
    dispatch_once(&s_onceToken, ^{
        if (SearchSettingsViewController.displaysMediaTypeSelection) {
            s_types = @[ @"general", @"type", @"period", @"duration", @"properties" ];
        }
        else {
            s_types = @[ @"general", @"period", @"duration", @"properties" ];
        }
    });
    return s_types;
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSectionWithType:(NSString *)type
{
    static dispatch_once_t s_onceToken;
    static NSDictionary<NSString *, NSString *> *s_titles;
    dispatch_once(&s_onceToken, ^{
        s_titles = @{ @"type" : NSLocalizedString(@"Type", @"Settings section header"),
                      @"period" : NSLocalizedString(@"Period", @"Settings section header"),
                      @"duration" : NSLocalizedString(@"Duration", @"Settings section header"),
                      @"properties" : NSLocalizedString(@"Properties", @"Settings section header") };
    });
    return s_titles[type];
}

- (NSArray<NSString *> *)tableView:(UITableView *)tableView rowTypesInSectionWithType:(NSString *)type
{
    static dispatch_once_t s_onceToken;
    static NSDictionary<NSString *, NSArray<NSString *> *> *s_types;
    dispatch_once(&s_onceToken, ^{
        s_types = @{ @"general" : @[ @"topics", @"shows" ],
                     @"type" : @[ @"media_type" ],
                     @"period" : @[ @"last_24_hours", @"last_3_days", @"last_week", @"last_month" ],
                     @"duration" : @[ @"duration" ],
                     @"properties" : @[ @"download_available", @"playable_abroad" ] };
    });
    return s_types[type];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowWithType:(NSString *)type atIndexPath:(NSIndexPath *)indexPath
{
    static dispatch_once_t s_onceToken;
    static NSDictionary<NSString *, Class> *s_cellClasses;
    dispatch_once(&s_onceToken, ^{
        s_cellClasses = @{ @"topics" : SearchSettingSelectorCell.class,
                           @"shows" : SearchSettingSelectorCell.class,
                           @"media_type" : SearchSettingSegmentCell.class,
                           @"last_24_hours" : SearchSettingSelectorCell.class,
                           @"last_3_days" : SearchSettingSelectorCell.class,
                           @"last_week" : SearchSettingSelectorCell.class,
                           @"last_month" : SearchSettingSelectorCell.class,
                           @"duration" : SearchSettingSegmentCell.class,
                           @"download_available" : SearchSettingSwitchCell.class,
                           @"playable_abroad" : SearchSettingSwitchCell.class };
    });
    Class cellClass = s_cellClasses[type];
    NSAssert(cellClass, @"Type must be valid");
    return [tableView dequeueReusableCellWithIdentifier:NSStringFromClass(cellClass) forIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell withType:(NSString *)type
{
    SRGMediaSearchSettings *settings = self.settings;
    
    if ([type isEqualToString:@"topics"]) {
        SearchSettingSelectorCell *selectorCell = (SearchSettingSelectorCell *)cell;
        
        NSArray<NSString *> *topicBucketURNs = [self.aggregations.topicBuckets valueForKeyPath:@keypath(SRGTopicBucket.new, URN)];
        NSArray<NSString *> *topicURNs = [self.settings.topicURNs play_arrayByIntersectingWithArray:topicBucketURNs];
        
        NSString *name = NSLocalizedString(@"Categories", @"Categories search setting option");
        if (topicURNs.count > 0) {
            name = [NSString stringWithFormat:@"%@ (%@ selected)", name, @(topicURNs.count)];
        }
        selectorCell.name = name;
        
        BOOL enabled = (topicBucketURNs.count > 0);
        selectorCell.userInteractionEnabled = enabled;
        selectorCell.accessoryType = enabled ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
    }
    else if ([type isEqualToString:@"shows"]) {
        SearchSettingSelectorCell *selectorCell = (SearchSettingSelectorCell *)cell;
        
        NSArray<NSString *> *showBucketURNs = [self.aggregations.showBuckets valueForKeyPath:@keypath(SRGShowBucket.new, URN)];
        NSArray<NSString *> *showURNs = [self.settings.showURNs play_arrayByIntersectingWithArray:showBucketURNs];
        
        NSString *name = NSLocalizedString(@"Shows", @"Shows search setting option");
        if (showURNs.count > 0) {
            name = [NSString stringWithFormat:@"%@ (%@ selected)", name, @(showURNs.count)];
        }
        selectorCell.name = name;
        
        BOOL enabled = (showBucketURNs.count > 0);
        selectorCell.userInteractionEnabled = enabled;
        selectorCell.accessoryType = enabled ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
    }
    else if ([type isEqualToString:@"media_type"]) {
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
    }
    else if ([type isEqualToString:@"last_24_hours"]) {
        SearchSettingSelectorCell *selectorCell = (SearchSettingSelectorCell *)cell;
        selectorCell.name = NSLocalizedString(@"The last 24 hours", @"Period setting option");
        selectorCell.accessoryType = (SearchSettingPeriodForSettings(self.settings) == SearchSettingPeriodLastDay) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }
    else if ([type isEqualToString:@"last_3_days"]) {
        SearchSettingSelectorCell *selectorCell = (SearchSettingSelectorCell *)cell;
        selectorCell.name = NSLocalizedString(@"The last 3 days", @"Period setting option");
        selectorCell.accessoryType = (SearchSettingPeriodForSettings(self.settings) == SearchSettingPeriodLastThreeDays) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }
    else if ([type isEqualToString:@"last_week"]) {
        SearchSettingSelectorCell *selectorCell = (SearchSettingSelectorCell *)cell;
        selectorCell.name = NSLocalizedString(@"The last week", @"Period setting option");
        selectorCell.accessoryType = (SearchSettingPeriodForSettings(self.settings) == SearchSettingPeriodLastWeek) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }
    else if ([type isEqualToString:@"last_month"]) {
        SearchSettingSelectorCell *selectorCell = (SearchSettingSelectorCell *)cell;
        selectorCell.name = NSLocalizedString(@"The last month", @"Period setting option");
        selectorCell.accessoryType = (SearchSettingPeriodForSettings(self.settings) == SearchSettingPeriodLastMonth) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }
    else if ([type isEqualToString:@"duration"]) {
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
    }
    else if ([type isEqualToString:@"download_available"]) {
        SearchSettingSwitchCell *switchCell = (SearchSettingSwitchCell *)cell;
        
        @weakify(self)
        [switchCell setName:NSLocalizedString(@"Available for download", @"Download availability toggle name in search settings") reader:^BOOL{
            return settings.downloadAvailable.boolValue;
        } writer:^(BOOL value) {
            @strongify(self)
            
            settings.downloadAvailable = @(value);
            [self updateResults];
        }];
    }
    else if ([type isEqualToString:@"playable_abroad"]) {
        SearchSettingSwitchCell *switchCell = (SearchSettingSwitchCell *)cell;
        
        @weakify(self)
        [switchCell setName:NSLocalizedString(@"Playable abroad", @"Abroad playability toggle name in search settings") reader:^BOOL{
            return settings.playableAbroad.boolValue;
        } writer:^(BOOL value) {
            @strongify(self)
            
            settings.playableAbroad = @(value);
            [self updateResults];
        }];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowWithType:(NSString *)type
{
    if ([type isEqualToString:@"topics"]) {
        SearchSettingMultiSelectionViewController *multiSelectionViewController = [[SearchSettingMultiSelectionViewController alloc] initWithTitle:NSLocalizedString(@"Categories", @"Categories search setting option list view title")
                                                                                                                                        identifier:NSStringFromClass(SRGTopicBucket.class)
                                                                                                                                             items:[self.aggregations.topicBuckets valueForKey:@keypath(SRGTopicBucket.new, multiSelectionItem)]
                                                                                                                                    selectedValues:self.settings.topicURNs];
        multiSelectionViewController.delegate = self;
        [self.navigationController pushViewController:multiSelectionViewController animated:YES];;
    }
    else if ([type isEqualToString:@"shows"]) {
        SearchSettingMultiSelectionViewController *multiSelectionViewController = [[SearchSettingMultiSelectionViewController alloc] initWithTitle:NSLocalizedString(@"Shows", @"Shows search setting option list view title")
                                                                                                                                        identifier:NSStringFromClass(SRGShowBucket.class)
                                                                                                                                             items:[self.aggregations.showBuckets valueForKey:@keypath(SRGShowBucket.new, multiSelectionItem)]
                                                                                                                                    selectedValues:self.settings.showURNs];
        multiSelectionViewController.delegate = self;
        [self.navigationController pushViewController:multiSelectionViewController animated:YES];
    }
    else if ([type isEqualToString:@"last_24_hours"]) {
        NSDateComponents *components = [[NSDateComponents alloc] init];
        components.day = -kLastDay;
        self.settings.afterDate = (SearchSettingPeriodForSettings(self.settings) != SearchSettingPeriodLastDay) ? [NSCalendar.currentCalendar dateByAddingComponents:components toDate:NSDate.date options:0] : nil;
        [self.tableView reloadData];
        [self updateResults];
    }
    else if ([type isEqualToString:@"last_3_days"]) {
        NSDateComponents *components = [[NSDateComponents alloc] init];
        components.day = -kLastThreeDays;
        self.settings.afterDate = (SearchSettingPeriodForSettings(self.settings) != SearchSettingPeriodLastThreeDays) ? [NSCalendar.currentCalendar dateByAddingComponents:components toDate:NSDate.date options:0] : nil;
        [self.tableView reloadData];
        [self updateResults];
    }
    else if ([type isEqualToString:@"last_week"]) {
        NSDateComponents *components = [[NSDateComponents alloc] init];
        components.day = -kLastWeek;
        self.settings.afterDate = (SearchSettingPeriodForSettings(self.settings) != SearchSettingPeriodLastWeek) ? [NSCalendar.currentCalendar dateByAddingComponents:components toDate:NSDate.date options:0] : nil;
        [self.tableView reloadData];
        [self updateResults];
    }
    else if ([type isEqualToString:@"last_month"]) {
        NSDateComponents *components = [[NSDateComponents alloc] init];
        components.day = -kLastMonth;
        self.settings.afterDate = (SearchSettingPeriodForSettings(self.settings) != SearchSettingPeriodLastMonth) ? [NSCalendar.currentCalendar dateByAddingComponents:components toDate:NSDate.date options:0] : nil;
        [self.tableView reloadData];
        [self updateResults];
    }
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
    return [self sectionTypesForTableView:tableView].count;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    NSString *sectionType = [self sectionTypesForTableView:tableView][section];
    return [self tableView:tableView rowTypesInSectionWithType:sectionType].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *sectionType = [self sectionTypesForTableView:tableView][indexPath.section];
    NSString *rowType = [self tableView:tableView rowTypesInSectionWithType:sectionType][indexPath.row];
    return [self tableView:tableView cellForRowWithType:rowType atIndexPath:indexPath];
}

#pragma mark UITableViewDelegate protocol

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *sectionType = [self sectionTypesForTableView:tableView][indexPath.section];
    NSString *rowType = [self tableView:tableView rowTypesInSectionWithType:sectionType][indexPath.row];
    return [self tableView:tableView willDisplayCell:cell withType:rowType];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    NSString *sectionType = [self sectionTypesForTableView:tableView][indexPath.section];
    NSString *rowType = [self tableView:tableView rowTypesInSectionWithType:sectionType][indexPath.row];
    return [self tableView:tableView didSelectRowWithType:rowType];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    NSString *sectionType = [self sectionTypesForTableView:tableView][section];
    NSString *title = [self tableView:tableView titleForHeaderInSectionWithType:sectionType];
    return title.length != 0 ? 60.f : 0.f;
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    SearchSettingsHeaderView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:NSStringFromClass(SearchSettingsHeaderView.class)];
    
    NSString *sectionType = [self sectionTypesForTableView:tableView][section];
    headerView.title = [self tableView:tableView titleForHeaderInSectionWithType:sectionType];
    
    return headerView;
}

#pragma mark SearchSettingsMultiSelectionViewControllerDelegate protocol

- (void)searchSettingMultiSelectionViewController:(SearchSettingMultiSelectionViewController *)searchSettingMultiSelectionViewController didUpdateSelectedValues:(NSArray<NSString *> *)selectedValues
{
    if ([searchSettingMultiSelectionViewController.identifier isEqualToString:NSStringFromClass(SRGTopicBucket.class)]) {
        self.settings.topicURNs = selectedValues;
        [self updateResults];
    }
    else if ([searchSettingMultiSelectionViewController.identifier isEqualToString:NSStringFromClass(SRGShowBucket.class)]) {
        self.settings.showURNs = selectedValues;
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

@implementation SRGTopicBucket (SearchSettings)

- (SearchSettingsMultiSelectionItem *)multiSelectionItem
{
    return [[SearchSettingsMultiSelectionItem alloc] initWithName:self.title value:self.URN count:self.count];
}

@end

@implementation SRGShowBucket (SearchSettings)

- (SearchSettingsMultiSelectionItem *)multiSelectionItem
{
    return [[SearchSettingsMultiSelectionItem alloc] initWithName:self.title value:self.URN count:self.count];
}

@end
