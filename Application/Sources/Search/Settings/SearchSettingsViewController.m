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
#import "SearchSettingMultiSelectionCell.h"
#import "SearchSettingSelectorCell.h"
#import "SearchSettingSegmentCell.h"
#import "SearchSettingSwitchCell.h"
#import "SearchSettingMultiSelectionViewController.h"
#import "UIColor+PlaySRG.h"
#import "UIViewController+PlaySRG.h"

#import <libextobjc/libextobjc.h>
#import <SRGAppearance/SRGAppearance.h>

static NSInteger const kLastDay = 1;
static NSInteger const kLastThreeDays = 3;
static NSInteger const kLastWeek = 7;
static NSInteger const kLastMonth = 30;

typedef NSString * SearchSettingSectionType NS_STRING_ENUM;

static SearchSettingSectionType const SearchSettingSectionTypeMediaType = @"media_type";
static SearchSettingSectionType const SearchSettingSectionTypeTopics = @"topics";
static SearchSettingSectionType const SearchSettingSectionTypeShows = @"shows";
static SearchSettingSectionType const SearchSettingSectionTypePeriod = @"period";
static SearchSettingSectionType const SearchSettingSectionTypeDuration = @"duration";
static SearchSettingSectionType const SearchSettingSectionTypeProperties = @"properties";

typedef NSString * SearchSettingRowType NS_STRING_ENUM;

static SearchSettingRowType const SearchSettingRowTypeTopics = @"topics";
static SearchSettingRowType const SearchSettingRowTypeShows = @"shows";
static SearchSettingRowType const SearchSettingRowTypeMediaType = @"media_type";
static SearchSettingRowType const SearchSettingRowTypeLastDay = @"last_day";
static SearchSettingRowType const SearchSettingRowTypeLastThreeDays = @"last_three_days";
static SearchSettingRowType const SearchSettingRowTypeLastWeek = @"last_week";
static SearchSettingRowType const SearchSettingRowTypeLastMonth = @"last_month";
static SearchSettingRowType const SearchSettingRowTypeDuration = @"duration";
static SearchSettingRowType const SearchSettingRowTypeSubtitled = @"subtitled";
static SearchSettingRowType const SearchSettingRowTypeDownloadAvailable = @"download_available";
static SearchSettingRowType const SearchSettingRowTypePlayableAbroad = @"playable_abroad";

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

+ (BOOL)containsAdvancedSettings:(SRGMediaSearchSettings *)settings
{
    NSParameterAssert(settings);
    SRGMediaSearchSettings *basicSettings = [[SRGMediaSearchSettings alloc] init];
    return ! [basicSettings isEqual:settings];
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
    return NSLocalizedString(@"Filters", @"Search filters page title");
}

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = UIColor.play_popoverGrayColor;
    
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = UIColor.clearColor;
    self.tableView.separatorColor = UIColor.clearColor;
    self.tableView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    
    // Remove the space at the top of the grouped table view
    // See https://stackoverflow.com/a/18938763/760435
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, self.tableView.bounds.size.width, 0.01f)];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, self.tableView.bounds.size.width, 0.01f)];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    NSString *headerIdentifier = NSStringFromClass(SearchSettingsHeaderView.class);
    UINib *headerViewNib = [UINib nibWithNibName:headerIdentifier bundle:nil];
    [self.tableView registerNib:headerViewNib forHeaderFooterViewReuseIdentifier:headerIdentifier];
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"OK", @"Title of the search settings button to apply settings")
                                                                              style:UIBarButtonItemStylePlain
                                                                             target:self
                                                                             action:@selector(close:)];
    
    self.preferredContentSize = CGSizeMake(375.f, 600.f);
    
    [self updateResetButton];
}

#pragma mark Rotation

- (UIInterfaceOrientationMask)supportedInterfaceOrientations
{
    return [super supportedInterfaceOrientations] & UIViewController.play_supportedInterfaceOrientations;
}

#pragma mark Responsiveness

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        self.popoverPresentationController.sourceRect = self.popoverPresentationController.sourceView.bounds;
    }];
}

- (void)willTransitionToTraitCollection:(UITraitCollection *)newCollection withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super willTransitionToTraitCollection:newCollection withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:nil completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        self.popoverPresentationController.sourceRect = self.popoverPresentationController.sourceView.bounds;
    }];
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
    
    [self updateResetButton];
    [self refresh];
}

#pragma mark UI

- (void)updateResetButton
{
    if ([SearchSettingsViewController containsAdvancedSettings:self.settings]) {
        self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Reset", @"Title of the reset search settings button")
                                                                                 style:UIBarButtonItemStylePlain
                                                                                target:self
                                                                                action:@selector(resetSettings:)];
    }
    else {
        self.navigationItem.leftBarButtonItem = nil;
    }
}

#pragma mark Type-based table view methods

- (NSArray<SearchSettingSectionType> *)sectionTypesForTableView:(UITableView *)tableView
{
    return @[ SearchSettingSectionTypeMediaType,
              SearchSettingSectionTypeShows,
              SearchSettingSectionTypeTopics,
              SearchSettingSectionTypePeriod,
              SearchSettingSectionTypeDuration,
              SearchSettingSectionTypeProperties ];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSectionWithType:(SearchSettingSectionType)type
{
    NSDictionary<SearchSettingSectionType, NSString *> *titles = @{ SearchSettingSectionTypePeriod : NSLocalizedString(@"Period", @"Settings section header"),
                                                                    SearchSettingSectionTypeDuration : NSLocalizedString(@"Duration", @"Settings section header"),
                                                                    SearchSettingSectionTypeProperties : NSLocalizedString(@"Properties", @"Settings section header") };
    return titles[type];
}

- (NSArray<SearchSettingRowType> *)tableView:(UITableView *)tableView rowTypesInSectionWithType:(SearchSettingSectionType)type
{
    ApplicationConfiguration *applicationConfiguration = ApplicationConfiguration.sharedApplicationConfiguration;
    
    NSArray<SearchSettingRowType> *propertiesRowTypes = nil;
    if (applicationConfiguration.searchSettingSubtitledEnabled) {
        propertiesRowTypes = @[ SearchSettingRowTypeSubtitled, SearchSettingRowTypeDownloadAvailable, SearchSettingRowTypePlayableAbroad ];
    }
    else {
        propertiesRowTypes = @[ SearchSettingRowTypeDownloadAvailable, SearchSettingRowTypePlayableAbroad ];
    }
    
    NSDictionary<SearchSettingSectionType, NSArray<SearchSettingRowType> *> *types = @{ SearchSettingSectionTypeMediaType : @[ SearchSettingRowTypeMediaType ],
                                                                                        SearchSettingSectionTypeTopics : @[ SearchSettingRowTypeTopics ],
                                                                                        SearchSettingSectionTypeShows : @[ SearchSettingRowTypeShows ],
                                                                                        SearchSettingSectionTypePeriod : @[ SearchSettingRowTypeLastDay, SearchSettingRowTypeLastThreeDays, SearchSettingRowTypeLastWeek, SearchSettingRowTypeLastMonth ],
                                                                                        SearchSettingSectionTypeDuration : @[ SearchSettingRowTypeDuration ],
                                                                                        SearchSettingSectionTypeProperties : propertiesRowTypes };
    return types[type];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowWithType:(SearchSettingRowType)type atIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary<SearchSettingRowType, Class> *cellClasses = @{ SearchSettingRowTypeTopics : SearchSettingMultiSelectionCell.class,
                                                                SearchSettingRowTypeShows : SearchSettingMultiSelectionCell.class,
                                                                SearchSettingRowTypeMediaType : SearchSettingSegmentCell.class,
                                                                SearchSettingRowTypeLastDay : SearchSettingSelectorCell.class,
                                                                SearchSettingRowTypeLastThreeDays : SearchSettingSelectorCell.class,
                                                                SearchSettingRowTypeLastWeek : SearchSettingSelectorCell.class,
                                                                SearchSettingRowTypeLastMonth : SearchSettingSelectorCell.class,
                                                                SearchSettingRowTypeDuration : SearchSettingSegmentCell.class,
                                                                SearchSettingRowTypeSubtitled : SearchSettingSwitchCell.class,
                                                                SearchSettingRowTypeDownloadAvailable : SearchSettingSwitchCell.class,
                                                                SearchSettingRowTypePlayableAbroad : SearchSettingSwitchCell.class };
    Class cellClass = cellClasses[type];
    NSAssert(cellClass, @"Type must be valid");
    return [tableView dequeueReusableCellWithIdentifier:NSStringFromClass(cellClass) forIndexPath:indexPath];
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell withType:(SearchSettingRowType)type
{
    SRGMediaSearchSettings *settings = self.settings;
    
    if ([type isEqualToString:SearchSettingRowTypeTopics]) {
        SearchSettingSelectorCell *selectorCell = (SearchSettingSelectorCell *)cell;
        
        NSArray<NSString *> *topicBucketURNs = [self.aggregations.topicBuckets valueForKeyPath:@keypath(SRGTopicBucket.new, URN)];
        NSArray<NSString *> *topicURNs = [self.settings.topicURNs play_arrayByIntersectingWithArray:topicBucketURNs];
        
        NSString *name = NSLocalizedString(@"Topics", @"Categories search setting option");
        if (topicURNs.count > 0) {
            name = [NSString stringWithFormat:@"%@ (%@ selected)", name, @(topicURNs.count)];
        }
        selectorCell.name = name;
        
        BOOL enabled = (topicBucketURNs.count > 0);
        selectorCell.userInteractionEnabled = enabled;
        selectorCell.accessoryType = enabled ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
    }
    else if ([type isEqualToString:SearchSettingRowTypeShows]) {
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
    else if ([type isEqualToString:SearchSettingRowTypeMediaType]) {
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
    else if ([type isEqualToString:SearchSettingRowTypeLastDay]) {
        SearchSettingSelectorCell *selectorCell = (SearchSettingSelectorCell *)cell;
        selectorCell.name = NSLocalizedString(@"The last 24 hours", @"Period setting option");
        selectorCell.accessoryType = (SearchSettingPeriodForSettings(self.settings) == SearchSettingPeriodLastDay) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }
    else if ([type isEqualToString:SearchSettingRowTypeLastThreeDays]) {
        SearchSettingSelectorCell *selectorCell = (SearchSettingSelectorCell *)cell;
        selectorCell.name = NSLocalizedString(@"The last 3 days", @"Period setting option");
        selectorCell.accessoryType = (SearchSettingPeriodForSettings(self.settings) == SearchSettingPeriodLastThreeDays) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }
    else if ([type isEqualToString:SearchSettingRowTypeLastWeek]) {
        SearchSettingSelectorCell *selectorCell = (SearchSettingSelectorCell *)cell;
        selectorCell.name = NSLocalizedString(@"The last week", @"Period setting option");
        selectorCell.accessoryType = (SearchSettingPeriodForSettings(self.settings) == SearchSettingPeriodLastWeek) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }
    else if ([type isEqualToString:SearchSettingRowTypeLastMonth]) {
        SearchSettingSelectorCell *selectorCell = (SearchSettingSelectorCell *)cell;
        selectorCell.name = NSLocalizedString(@"The last month", @"Period setting option");
        selectorCell.accessoryType = (SearchSettingPeriodForSettings(self.settings) == SearchSettingPeriodLastMonth) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }
    else if ([type isEqualToString:SearchSettingRowTypeDuration]) {
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
    else if ([type isEqualToString:SearchSettingRowTypeSubtitled]) {
        SearchSettingSwitchCell *switchCell = (SearchSettingSwitchCell *)cell;
        
        @weakify(self)
        [switchCell setName:NSLocalizedString(@"Subtitled", @"Name of the search setting to filter subtitled content") reader:^BOOL{
            return settings.subtitlesAvailable.boolValue;
        } writer:^(BOOL value) {
            @strongify(self)
            
            settings.subtitlesAvailable = value ? @(value) : nil;
            [self updateResults];
        }];
    }
    else if ([type isEqualToString:SearchSettingRowTypeDownloadAvailable]) {
        SearchSettingSwitchCell *switchCell = (SearchSettingSwitchCell *)cell;
        
        @weakify(self)
        [switchCell setName:NSLocalizedString(@"Downloadable", @"Name of the search setting to filter downloadable content") reader:^BOOL{
            return settings.downloadAvailable.boolValue;
        } writer:^(BOOL value) {
            @strongify(self)
            
            settings.downloadAvailable = value ? @(value) : nil;
            [self updateResults];
        }];
    }
    else if ([type isEqualToString:SearchSettingRowTypePlayableAbroad]) {
        SearchSettingSwitchCell *switchCell = (SearchSettingSwitchCell *)cell;
        
        @weakify(self)
        [switchCell setName:NSLocalizedString(@"Playable abroad", @"Name of the search setting to filter content playable abroard") reader:^BOOL{
            return settings.playableAbroad.boolValue;
        } writer:^(BOOL value) {
            @strongify(self)
            
            settings.playableAbroad = value ? @(value) : nil;
            [self updateResults];
        }];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowWithType:(SearchSettingRowType)type
{
    if ([type isEqualToString:SearchSettingRowTypeTopics]) {
        SearchSettingMultiSelectionViewController *multiSelectionViewController = [[SearchSettingMultiSelectionViewController alloc] initWithTitle:NSLocalizedString(@"Topics", @"Topics search setting option list view title")
                                                                                                                                        identifier:NSStringFromClass(SRGTopicBucket.class)
                                                                                                                                             items:[self.aggregations.topicBuckets valueForKey:@keypath(SRGTopicBucket.new, multiSelectionItem)]
                                                                                                                                    selectedValues:self.settings.topicURNs];
        multiSelectionViewController.delegate = self;
        [self.navigationController pushViewController:multiSelectionViewController animated:YES];;
    }
    else if ([type isEqualToString:SearchSettingRowTypeShows]) {
        SearchSettingMultiSelectionViewController *multiSelectionViewController = [[SearchSettingMultiSelectionViewController alloc] initWithTitle:NSLocalizedString(@"Shows", @"Shows search setting option list view title")
                                                                                                                                        identifier:NSStringFromClass(SRGShowBucket.class)
                                                                                                                                             items:[self.aggregations.showBuckets valueForKey:@keypath(SRGShowBucket.new, multiSelectionItem)]
                                                                                                                                    selectedValues:self.settings.showURNs];
        multiSelectionViewController.delegate = self;
        [self.navigationController pushViewController:multiSelectionViewController animated:YES];
    }
    else if ([type isEqualToString:SearchSettingRowTypeLastDay]) {
        NSDateComponents *components = [[NSDateComponents alloc] init];
        components.day = -kLastDay;
        self.settings.afterDate = (SearchSettingPeriodForSettings(self.settings) != SearchSettingPeriodLastDay) ? [NSCalendar.currentCalendar dateByAddingComponents:components toDate:NSDate.date options:0] : nil;
        [self.tableView reloadData];
        [self updateResults];
    }
    else if ([type isEqualToString:SearchSettingRowTypeLastThreeDays]) {
        NSDateComponents *components = [[NSDateComponents alloc] init];
        components.day = -kLastThreeDays;
        self.settings.afterDate = (SearchSettingPeriodForSettings(self.settings) != SearchSettingPeriodLastThreeDays) ? [NSCalendar.currentCalendar dateByAddingComponents:components toDate:NSDate.date options:0] : nil;
        [self.tableView reloadData];
        [self updateResults];
    }
    else if ([type isEqualToString:SearchSettingRowTypeLastWeek]) {
        NSDateComponents *components = [[NSDateComponents alloc] init];
        components.day = -kLastWeek;
        self.settings.afterDate = (SearchSettingPeriodForSettings(self.settings) != SearchSettingPeriodLastWeek) ? [NSCalendar.currentCalendar dateByAddingComponents:components toDate:NSDate.date options:0] : nil;
        [self.tableView reloadData];
        [self updateResults];
    }
    else if ([type isEqualToString:SearchSettingRowTypeLastMonth]) {
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
    SearchSettingSectionType sectionType = [self sectionTypesForTableView:tableView][section];
    return [self tableView:tableView rowTypesInSectionWithType:sectionType].count;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    SearchSettingSectionType sectionType = [self sectionTypesForTableView:tableView][indexPath.section];
    SearchSettingRowType rowType = [self tableView:tableView rowTypesInSectionWithType:sectionType][indexPath.row];
    return [self tableView:tableView cellForRowWithType:rowType atIndexPath:indexPath];
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
    SearchSettingSectionType sectionType = [self sectionTypesForTableView:tableView][indexPath.section];
    SearchSettingRowType rowType = [self tableView:tableView rowTypesInSectionWithType:sectionType][indexPath.row];
    [self tableView:tableView willDisplayCell:cell withType:rowType];
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    SearchSettingSectionType sectionType = [self sectionTypesForTableView:tableView][indexPath.section];
    SearchSettingRowType rowType = [self tableView:tableView rowTypesInSectionWithType:sectionType][indexPath.row];
    [self tableView:tableView didSelectRowWithType:rowType];
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    SearchSettingSectionType sectionType = [self sectionTypesForTableView:tableView][section];
    NSString *title = [self tableView:tableView titleForHeaderInSectionWithType:sectionType];
    if (title.length != 0) {
        return 50.f;
    }
    else if (section != 0) {
        return 0.01f;
    }
    else {
        return 0.f;
    }
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    SearchSettingsHeaderView *headerView = [tableView dequeueReusableHeaderFooterViewWithIdentifier:NSStringFromClass(SearchSettingsHeaderView.class)];
    
    SearchSettingSectionType sectionType = [self sectionTypesForTableView:tableView][section];
    headerView.title = [self tableView:tableView titleForHeaderInSectionWithType:sectionType];
    
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 0.01f;
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
    self.settings = [[SRGMediaSearchSettings alloc] init];
    [self updateResults];
    
    [self.tableView reloadData];
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
