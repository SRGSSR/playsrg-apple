//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SearchSettingsViewController.h"

#import "AnalyticsConstants.h"
#import "ApplicationConfiguration.h"
#import "NSArray+PlaySRG.h"
#import "NSBundle+PlaySRG.h"
#import "SearchSettingsHeaderView.h"
#import "SearchSettingMultiSelectionCell.h"
#import "SearchSettingSelectorCell.h"
#import "SearchSettingSegmentCell.h"
#import "SearchSettingSwitchCell.h"
#import "SearchSettingMultiSelectionViewController.h"
#import "SRGDay+PlaySRG.h"
#import "TableView.h"
#import "UIColor+PlaySRG.h"
#import "UIViewController+PlaySRG.h"

@import libextobjc;
@import SRGAppearance;

typedef NSString * SearchSettingSectionType NS_STRING_ENUM;

static SearchSettingSectionType const SearchSettingSectionTypeSortCriterium = @"sort_criterium";
static SearchSettingSectionType const SearchSettingSectionTypeMediaType = @"media_type";
static SearchSettingSectionType const SearchSettingSectionTypeTopics = @"topics";
static SearchSettingSectionType const SearchSettingSectionTypeShows = @"shows";
static SearchSettingSectionType const SearchSettingSectionTypePeriod = @"period";
static SearchSettingSectionType const SearchSettingSectionTypeDuration = @"duration";
static SearchSettingSectionType const SearchSettingSectionTypeProperties = @"properties";

typedef NSString * SearchSettingRowType NS_STRING_ENUM;

static SearchSettingRowType const SearchSettingRowTypeSortCriterium = @"sort_criterium";
static SearchSettingRowType const SearchSettingRowTypeMediaType = @"media_type";
static SearchSettingRowType const SearchSettingRowTypeTopics = @"topics";
static SearchSettingRowType const SearchSettingRowTypeShows = @"shows";
static SearchSettingRowType const SearchSettingRowTypeToday = @"today";
static SearchSettingRowType const SearchSettingRowTypeYesterday = @"yesterday";
static SearchSettingRowType const SearchSettingRowTypeThisWeek = @"this_week";
static SearchSettingRowType const SearchSettingRowTypeLastWeek = @"last_week";
static SearchSettingRowType const SearchSettingRowTypeDuration = @"duration";
static SearchSettingRowType const SearchSettingRowTypeSubtitled = @"subtitled";
static SearchSettingRowType const SearchSettingRowTypeDownloadAvailable = @"download_available";
static SearchSettingRowType const SearchSettingRowTypePlayableAbroad = @"playable_abroad";

typedef NS_ENUM(NSInteger, SearchSettingPeriod) {
    SearchSettingPeriodNone = 0,
    SearchSettingPeriodToday,
    SearchSettingPeriodYesterday,
    SearchSettingPeriodThisWeek,
    SearchSettingPeriodLastWeek
};

static SearchSettingPeriod SearchSettingPeriodForSettings(SRGMediaSearchSettings *settings)
{
    SRGDay *fromDay = settings.fromDay;
    SRGDay *toDay = settings.toDay;

    if (! fromDay || ! toDay) {
        return SearchSettingPeriodNone;
    }
    
    SRGDay *today = SRGDay.today;
    
    NSDateComponents *settingsRangeComponents = [SRGDay components:NSCalendarUnitDay fromDay:fromDay toDay:toDay];
    if (settingsRangeComponents.day == 6) {
        if ([today play_isBetweenDay:fromDay andDay:toDay]) {
            return SearchSettingPeriodThisWeek;
        }
        else if ([[SRGDay dayByAddingDays:-7 months:0 years:0 toDay:today] play_isBetweenDay:fromDay andDay:toDay]) {
            return SearchSettingPeriodLastWeek;
        }
    }
    else if (settingsRangeComponents.day == 0) {
        if ([today isEqual:fromDay]) {
            return SearchSettingPeriodToday;
        }
        else if ([[SRGDay dayByAddingDays:-1 months:0 years:0 toDay:today] isEqual:fromDay]) {
            return SearchSettingPeriodYesterday;
        }
    }
    
    return SearchSettingPeriodNone;
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

+ (SRGMediaSearchSettings *)defaultSettings
{
    return [[SRGMediaSearchSettings alloc] init];
}

+ (BOOL)containsAdvancedSettings:(SRGMediaSearchSettings *)settings
{
    NSParameterAssert(settings);
    return ! [self.defaultSettings isEqual:settings];
}

#pragma mark Object lifecycle

- (instancetype)initWithQuery:(NSString *)query settings:(SRGMediaSearchSettings *)settings
{
    if (self = [self initFromStoryboard]) {
        self.query = query;
        self.settings = settings.copy ?: SearchSettingsViewController.defaultSettings;
        self.settings.aggregationsEnabled = YES;
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
    
    self.view.backgroundColor = UIColor.play_popoverGrayBackgroundColor;
    self.navigationItem.largeTitleDisplayMode = UINavigationItemLargeTitleDisplayModeAlways;
    
    self.tableView.backgroundView = nil;
    self.tableView.backgroundColor = UIColor.clearColor;
    TableViewConfigure(self.tableView);
    
    // Remove the spaces at the top and bottom of the grouped table view
    // See https://stackoverflow.com/a/18938763/760435
    self.tableView.tableHeaderView = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, self.tableView.bounds.size.width, 0.01f)];
    self.tableView.tableFooterView = [[UIView alloc] initWithFrame:CGRectMake(0.f, 0.f, self.tableView.bounds.size.width, 0.01f)];
    
    self.tableView.dataSource = self;
    self.tableView.delegate = self;
    
    NSString *headerIdentifier = NSStringFromClass(SearchSettingsHeaderView.class);
    UINib *headerViewNib = [UINib nibWithNibName:headerIdentifier bundle:nil];
    [self.tableView registerNib:headerViewNib forHeaderFooterViewReuseIdentifier:headerIdentifier];
    
    self.preferredContentSize = CGSizeMake(375.f, 600.f);
    
    [self updateLeftBarButtonItems];
    [self updateRightBarButtonItems];
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

- (void)refreshDidStart
{
    [self updateRightBarButtonItems];
}

- (void)refreshDidFinishWithError:(NSError *)error
{
    [self updateRightBarButtonItems];
}

#pragma mark Updates

- (void)updateResults
{
    [self.delegate searchSettingsViewController:self didUpdateSettings:self.settings];
    [self updateLeftBarButtonItems];
    [self refresh];
}

#pragma mark UI

- (void)updateLeftBarButtonItems
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

- (void)updateRightBarButtonItems
{
    UIBarButtonItem *closeBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"OK", @"Title of the search settings button to apply settings")
                                                                           style:UIBarButtonItemStylePlain
                                                                          target:self
                                                                          action:@selector(close:)];
    
    if (self.loading) {
        UIActivityIndicatorView *activityIndicatorView = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleMedium];
        [activityIndicatorView startAnimating];
        UIBarButtonItem *activityBarButtonItem = [[UIBarButtonItem alloc] initWithCustomView:activityIndicatorView];
        self.navigationItem.rightBarButtonItems = @[ closeBarButtonItem, activityBarButtonItem ];
    }
    else {
        self.navigationItem.rightBarButtonItems = @[ closeBarButtonItem ];
    }
}

#pragma mark Type-based table view methods

- (NSArray<SearchSettingSectionType> *)sectionTypesForTableView:(UITableView *)tableView
{
    NSMutableArray *sectionTypes = [NSMutableArray array];

    return @[ SearchSettingSectionTypeSortCriterium,
              SearchSettingSectionTypeMediaType,
              SearchSettingSectionTypeTopics,
              SearchSettingSectionTypeShows,
              SearchSettingSectionTypePeriod,
              SearchSettingSectionTypeDuration,
              SearchSettingSectionTypeProperties ]];
}

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSectionWithType:(SearchSettingSectionType)type
{
    NSDictionary<SearchSettingSectionType, NSString *> *titles = @{ SearchSettingSectionTypeSortCriterium : NSLocalizedString(@"Sort by", @"Search settings section header"),
                                                                    SearchSettingSectionTypeMediaType : NSLocalizedString(@"Content", @"Search settings section header"),
                                                                    SearchSettingSectionTypePeriod : NSLocalizedString(@"Period", @"Search settings section header"),
                                                                    SearchSettingSectionTypeDuration : NSLocalizedString(@"Duration", @"Search settings section header"),
                                                                    SearchSettingSectionTypeProperties : NSLocalizedString(@"Properties", @"Search settings section header") };
    return titles[type];
}

- (NSArray<SearchSettingRowType> *)tableView:(UITableView *)tableView rowTypesInSectionWithType:(SearchSettingSectionType)type
{
    ApplicationConfiguration *applicationConfiguration = ApplicationConfiguration.sharedApplicationConfiguration;
    
    NSArray<SearchSettingRowType> *propertiesRowTypes = nil;
    if (! applicationConfiguration.searchSettingSubtitledHidden) {
        propertiesRowTypes = @[ SearchSettingRowTypeDownloadAvailable, SearchSettingRowTypePlayableAbroad, SearchSettingRowTypeSubtitled ];
    }
    else {
        propertiesRowTypes = @[ SearchSettingRowTypeDownloadAvailable, SearchSettingRowTypePlayableAbroad ];
    }
    
    NSDictionary<SearchSettingSectionType, NSArray<SearchSettingRowType> *> *types = @{ SearchSettingSectionTypeSortCriterium : @[ SearchSettingRowTypeSortCriterium ],
                                                                                        SearchSettingSectionTypeMediaType : @[ SearchSettingRowTypeMediaType ],
                                                                                        SearchSettingSectionTypeTopics : @[ SearchSettingRowTypeTopics ],
                                                                                        SearchSettingSectionTypeShows : @[ SearchSettingRowTypeShows ],
                                                                                        SearchSettingSectionTypePeriod : @[ SearchSettingRowTypeToday, SearchSettingRowTypeYesterday, SearchSettingRowTypeThisWeek, SearchSettingRowTypeLastWeek ],
                                                                                        SearchSettingSectionTypeDuration : @[ SearchSettingRowTypeDuration ],
                                                                                        SearchSettingSectionTypeProperties : propertiesRowTypes };
    return types[type];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowWithType:(SearchSettingRowType)type atIndexPath:(NSIndexPath *)indexPath
{
    NSDictionary<SearchSettingRowType, Class> *cellClasses = @{ SearchSettingRowTypeSortCriterium : SearchSettingSegmentCell.class,
                                                                SearchSettingRowTypeMediaType : SearchSettingSegmentCell.class,
                                                                SearchSettingRowTypeTopics : SearchSettingMultiSelectionCell.class,
                                                                SearchSettingRowTypeShows : SearchSettingMultiSelectionCell.class,
                                                                SearchSettingRowTypeToday : SearchSettingSelectorCell.class,
                                                                SearchSettingRowTypeYesterday : SearchSettingSelectorCell.class,
                                                                SearchSettingRowTypeThisWeek : SearchSettingSelectorCell.class,
                                                                SearchSettingRowTypeLastWeek : SearchSettingSelectorCell.class,
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
        SearchSettingMultiSelectionCell *multiSelectionCell = (SearchSettingMultiSelectionCell *)cell;
        
        NSArray<NSString *> *topicBucketURNs = [self.aggregations.topicBuckets valueForKeyPath:@keypath(SRGTopicBucket.new, URN)];
        NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(SRGTopicBucket * _Nullable bucket, NSDictionary<NSString *,id> * _Nullable bindings) {
            return [self.settings.topicURNs containsObject:bucket.URN];
        }];
        NSArray<NSString *> *topicNames = [[[self.aggregations.topicBuckets filteredArrayUsingPredicate:predicate] valueForKeyPath:@keypath(SRGTopicBucket.new, title)] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
        [multiSelectionCell setName:NSLocalizedString(@"Topics", @"Categories search setting option") values:topicNames];
        
        BOOL enabled = (topicBucketURNs.count > 0);
        multiSelectionCell.userInteractionEnabled = enabled;
        multiSelectionCell.accessoryType = enabled ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
    }
    else if ([type isEqualToString:SearchSettingRowTypeShows]) {
        SearchSettingMultiSelectionCell *multiSelectionCell = (SearchSettingMultiSelectionCell *)cell;
        
        NSArray<NSString *> *showBucketURNs = [self.aggregations.showBuckets valueForKeyPath:@keypath(SRGShowBucket.new, URN)];
        NSPredicate *predicate = [NSPredicate predicateWithBlock:^BOOL(SRGShowBucket * _Nullable bucket, NSDictionary<NSString *,id> * _Nullable bindings) {
            return [self.settings.showURNs containsObject:bucket.URN];
        }];
        NSArray<NSString *> *showNames = [[[self.aggregations.showBuckets filteredArrayUsingPredicate:predicate] valueForKeyPath:@keypath(SRGTopicBucket.new, title)] sortedArrayUsingSelector:@selector(localizedCaseInsensitiveCompare:)];
        [multiSelectionCell setName:NSLocalizedString(@"Shows", @"Shows search setting option") values:showNames];
        
        BOOL enabled = (showBucketURNs.count > 0);
        multiSelectionCell.userInteractionEnabled = enabled;
        multiSelectionCell.accessoryType = enabled ? UITableViewCellAccessoryDisclosureIndicator : UITableViewCellAccessoryNone;
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
    else if ([type isEqualToString:SearchSettingRowTypeSortCriterium]) {
        SearchSettingSegmentCell *segmentCell = (SearchSettingSegmentCell *)cell;
        
        static dispatch_once_t s_onceToken;
        static NSDictionary<NSNumber *, NSNumber *> *s_sortCriteria;
        dispatch_once(&s_onceToken, ^{
            s_sortCriteria = @{ @0 : @(SRGSortCriteriumDefault),
                                @1 : @(SRGSortCriteriumDate) };
        });
        
        @weakify(self)
        [segmentCell setItems:@[ NSLocalizedString(@"Relevance", @"Sort by relevance option"), NSLocalizedString(@"Date", @"Sort by date option") ] reader:^NSInteger{
            return [s_sortCriteria allKeysForObject:@(settings.sortCriterium)].firstObject.integerValue;
        } writer:^(NSInteger index) {
            @strongify(self)
            
            settings.sortCriterium = [s_sortCriteria[@(index)] integerValue];
            [self updateResults];
        }];
    }
    else if ([type isEqualToString:SearchSettingRowTypeToday]) {
        SearchSettingSelectorCell *selectorCell = (SearchSettingSelectorCell *)cell;
        selectorCell.name = NSLocalizedString(@"Today", @"Period setting option");
        selectorCell.accessoryType = (SearchSettingPeriodForSettings(self.settings) == SearchSettingPeriodToday) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }
    else if ([type isEqualToString:SearchSettingRowTypeYesterday]) {
        SearchSettingSelectorCell *selectorCell = (SearchSettingSelectorCell *)cell;
        selectorCell.name = NSLocalizedString(@"Yesterday", @"Period setting option");
        selectorCell.accessoryType = (SearchSettingPeriodForSettings(self.settings) == SearchSettingPeriodYesterday) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }
    else if ([type isEqualToString:SearchSettingRowTypeThisWeek]) {
        SearchSettingSelectorCell *selectorCell = (SearchSettingSelectorCell *)cell;
        selectorCell.name = NSLocalizedString(@"This week", @"Period setting option");
        selectorCell.accessoryType = (SearchSettingPeriodForSettings(self.settings) == SearchSettingPeriodThisWeek) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
    }
    else if ([type isEqualToString:SearchSettingRowTypeLastWeek]) {
        SearchSettingSelectorCell *selectorCell = (SearchSettingSelectorCell *)cell;
        selectorCell.name = NSLocalizedString(@"Last week", @"Period setting option");
        selectorCell.accessoryType = (SearchSettingPeriodForSettings(self.settings) == SearchSettingPeriodLastWeek) ? UITableViewCellAccessoryCheckmark : UITableViewCellAccessoryNone;
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
    else if ([type isEqualToString:SearchSettingRowTypeToday]) {
        if (SearchSettingPeriodForSettings(self.settings) != SearchSettingPeriodToday) {
            SRGDay *today = SRGDay.today;
            self.settings.fromDay = today;
            self.settings.toDay = today;
        }
        else {
            self.settings.fromDay = nil;
            self.settings.toDay = nil;
        }
        [self.tableView reloadData];
        [self updateResults];
    }
    else if ([type isEqualToString:SearchSettingRowTypeYesterday]) {
        if (SearchSettingPeriodForSettings(self.settings) != SearchSettingPeriodYesterday) {
            SRGDay *yesterday = [SRGDay dayByAddingDays:-1 months:0 years:0 toDay:SRGDay.today];
            self.settings.fromDay = yesterday;
            self.settings.toDay = yesterday;
        }
        else {
            self.settings.fromDay = nil;
            self.settings.toDay = nil;
        }
        [self.tableView reloadData];
        [self updateResults];
    }
    else if ([type isEqualToString:SearchSettingRowTypeThisWeek]) {
        if (SearchSettingPeriodForSettings(self.settings) != SearchSettingPeriodThisWeek) {
            SRGDay *firstDayOfThisWeek = [SRGDay startDayForUnit:NSCalendarUnitWeekOfYear containingDay:SRGDay.today];
            self.settings.fromDay = firstDayOfThisWeek;
            self.settings.toDay = [SRGDay dayByAddingDays:6 months:0 years:0 toDay:firstDayOfThisWeek];
        }
        else {
            self.settings.fromDay = nil;
            self.settings.toDay = nil;
        }
        [self.tableView reloadData];
        [self updateResults];
    }
    else if ([type isEqualToString:SearchSettingRowTypeLastWeek]) {
        if (SearchSettingPeriodForSettings(self.settings) != SearchSettingPeriodLastWeek) {
            SRGDay *firstDayOfLastWeek = [SRGDay dayByAddingDays:-7 months:0 years:0 toDay:[SRGDay startDayForUnit:NSCalendarUnitWeekOfYear containingDay:SRGDay.today]];
            self.settings.fromDay = firstDayOfLastWeek;
            self.settings.toDay = [SRGDay dayByAddingDays:6 months:0 years:0 toDay:firstDayOfLastWeek];
        }
        else {
            self.settings.fromDay = nil;
            self.settings.toDay = nil;
        }
        [self.tableView reloadData];
        [self updateResults];
    }
}

#pragma mark SRGAnalyticsViewTracking protocol

- (NSString *)srg_pageViewTitle
{
    return AnalyticsPageTitleSettings;
}

- (NSArray<NSString *> *)srg_pageViewLevels
{
    return @[ AnalyticsPageLevelPlay, AnalyticsPageLevelSearch ];
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
    SearchSettingSectionType sectionType = [self sectionTypesForTableView:tableView][indexPath.section];
    if (sectionType == SearchSettingSectionTypePeriod) {
        UIContentSizeCategory contentSizeCategory = UIApplication.sharedApplication.preferredContentSizeCategory;
        if (SRGAppearanceCompareContentSizeCategories(contentSizeCategory, UIContentSizeCategoryExtraLarge) == NSOrderedDescending) {
            return 45.f;
        }
        else if (SRGAppearanceCompareContentSizeCategories(contentSizeCategory, UIContentSizeCategorySmall) == NSOrderedDescending) {
            return 40.f;
        }
        else {
            return 35.f;
        }
    }
    else {
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
        return 4.f;
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
    headerView.separatorHidden = (section == 0);
    
    return headerView;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section
{
    return 4.f;
}

#pragma mark SearchSettingsMultiSelectionViewControllerDelegate protocol

- (void)searchSettingMultiSelectionViewController:(SearchSettingMultiSelectionViewController *)searchSettingMultiSelectionViewController didUpdateSelectedValues:(NSSet<NSString *> *)selectedValues
{
    if ([searchSettingMultiSelectionViewController.identifier isEqualToString:NSStringFromClass(SRGTopicBucket.class)]) {
        self.settings.topicURNs = selectedValues;
        [self updateResults];
    }
    else if ([searchSettingMultiSelectionViewController.identifier isEqualToString:NSStringFromClass(SRGShowBucket.class)]) {
        self.settings.showURNs = selectedValues;
        [self updateResults];
    }
    [self.tableView reloadData];
}

#pragma mark Actions

- (IBAction)close:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)resetSettings:(id)sender
{
    self.settings = SearchSettingsViewController.defaultSettings;
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
