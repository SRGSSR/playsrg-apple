//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SearchSettingsViewController.h"

#import "AnalyticsConstants.h"
#import "UIColor+PlaySRG.h"
#import "UIViewController+PlaySRG.h"

#import <libextobjc/libextobjc.h>

@interface SearchSettingsViewController ()

@property (nonatomic) SRGMediaSearchSettings *settings;
@property (nonatomic) SRGMediaAggregations *aggregations;

@end

@implementation SearchSettingsViewController

#pragma mark Object lifecycle

- (instancetype)initWithSettings:(SRGMediaSearchSettings *)settings aggregations:(SRGMediaAggregations *)aggregations
{
    if (self = [super init]) {
        self.settings = settings;
        self.aggregations = aggregations;
        self.form = [self formForAggregations:aggregations];
    }
    return self;
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"

- (instancetype)init
{
    [self doesNotRecognizeSelector:_cmd];
    return [self initWithSettings:SRGMediaSearchSettings.new aggregations:nil];
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
    
    self.view.backgroundColor = UIColor.play_blackColor;
    
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Close", @"Close button title")
                                                                              style:UIBarButtonItemStyleDone
                                                                             target:self
                                                                             action:@selector(close:)];
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

#pragma mark Form setup

- (XLFormDescriptor *)formForAggregations:(SRGMediaAggregations *)aggregations
{
    XLFormDescriptor *form = [XLFormDescriptor formDescriptor];
    
    NSSortDescriptor *titleSortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@keypath(SRGShowBucket.new, title) ascending:YES comparator:^NSComparisonResult(NSString * _Nonnull title1, NSString * _Nonnull title2) {
        return [title1 localizedCaseInsensitiveCompare:title2];
    }];
    
    // 1. General settings
    XLFormSectionDescriptor *generalSection = [XLFormSectionDescriptor formSection];
    [form addFormSection:generalSection];
    
    // -- Media type
    XLFormRowDescriptor *mediaTypeRow = [XLFormRowDescriptor formRowDescriptorWithTag:@"mediaType" rowType:XLFormRowDescriptorTypeSelectorSegmentedControl title:NSLocalizedString(@"Type", @"Setting title")];
    mediaTypeRow.selectorOptions = @[ [XLFormOptionsObject formOptionsObjectWithValue:@(SRGMediaTypeNone) displayText:NSLocalizedString(@"All", @"Option name")],
                                      [XLFormOptionsObject formOptionsObjectWithValue:@(SRGMediaTypeVideo) displayText:NSLocalizedString(@"Video", @"Option name")],
                                      [XLFormOptionsObject formOptionsObjectWithValue:@(SRGMediaTypeAudio) displayText:NSLocalizedString(@"Audio", @"Option name")] ];
    mediaTypeRow.value = @(SRGMediaTypeNone);
    [generalSection addFormRow:mediaTypeRow];
    
    // -- Period
    // TODO: Replace @(N) with proper values
    XLFormRowDescriptor *periodRow = [XLFormRowDescriptor formRowDescriptorWithTag:@"startDate" rowType:XLFormRowDescriptorTypeSelectorPush title:NSLocalizedString(@"Period", @"Setting title")];
    periodRow.selectorTitle = NSLocalizedString(@"Period", @"Setting title");
    periodRow.selectorOptions = @[ [XLFormOptionsObject formOptionsObjectWithValue:@(1) displayText:NSLocalizedString(@"Today", @"Option name")],
                                   [XLFormOptionsObject formOptionsObjectWithValue:@(2) displayText:NSLocalizedString(@"Yesterday", @"Option name")],
                                   [XLFormOptionsObject formOptionsObjectWithValue:@(3) displayText:NSLocalizedString(@"Last 7 days", @"Option name")],
                                   [XLFormOptionsObject formOptionsObjectWithValue:@(4) displayText:NSLocalizedString(@"Last 31 days", @"Option name")],
                                   [XLFormOptionsObject formOptionsObjectWithValue:@(5) displayText:NSLocalizedString(@"Last 365 days", @"Option name")] ];
    [generalSection addFormRow:periodRow];
    
    // -- Duration
    // TODO: Replace @(N) with proper values
    XLFormRowDescriptor *durationRow = [XLFormRowDescriptor formRowDescriptorWithTag:@"duration" rowType:XLFormRowDescriptorTypeSelectorSegmentedControl title:NSLocalizedString(@"Duration", @"Setting title")];
    durationRow.selectorOptions = @[ [XLFormOptionsObject formOptionsObjectWithValue:@(0) displayText:NSLocalizedString(@"All", @"Option name")],
                                     [XLFormOptionsObject formOptionsObjectWithValue:@(1) displayText:NSLocalizedString(@"< 5 min.", @"Option name")],
                                     [XLFormOptionsObject formOptionsObjectWithValue:@(2) displayText:NSLocalizedString(@"> 30 min.", @"Option name")] ];
    durationRow.value = @(0);
    [generalSection addFormRow:durationRow];
    
    // 2. Context settings
    XLFormSectionDescriptor *contextSection = [XLFormSectionDescriptor formSection];
    [form addFormSection:contextSection];
    
    // -- Show
    NSMutableArray<XLFormOptionsObject *> *showSelectorOptions = [NSMutableArray array];
    
    NSArray<SRGShowBucket *> *showBuckets = [aggregations.showBuckets sortedArrayUsingDescriptors:@[titleSortDescriptor]];
    for (SRGShowBucket *showBucket in showBuckets) {
        [showSelectorOptions addObject:[XLFormOptionsObject formOptionsObjectWithValue:showBucket.URN displayText:showBucket.title]];
    }
    
    XLFormRowDescriptor *showRow = [XLFormRowDescriptor formRowDescriptorWithTag:@"showURN" rowType:XLFormRowDescriptorTypeMultipleSelector title:NSLocalizedString(@"Show", @"Setting title")];
    showRow.selectorTitle = NSLocalizedString(@"Show", @"Show setting title");
    showRow.selectorOptions = [showSelectorOptions copy];
    [contextSection addFormRow:showRow];
    
    // -- Topic
    NSMutableArray<XLFormOptionsObject *> *topicSelectorOptions = [NSMutableArray array];
    
    NSArray<SRGTopicBucket *> *topicBuckets = [aggregations.topicBuckets sortedArrayUsingDescriptors:@[titleSortDescriptor]];
    for (SRGTopicBucket *topicBucket in topicBuckets) {
        [topicSelectorOptions addObject:[XLFormOptionsObject formOptionsObjectWithValue:topicBucket.URN displayText:topicBucket.title]];
    }
    
    XLFormRowDescriptor *topicRow = [XLFormRowDescriptor formRowDescriptorWithTag:@"topicURN" rowType:XLFormRowDescriptorTypeMultipleSelector title:NSLocalizedString(@"Topic", @"Setting title")];
    topicRow.selectorTitle = NSLocalizedString(@"Topic", @"Topic setting title");
    topicRow.selectorOptions = [topicSelectorOptions copy];
    [contextSection addFormRow:topicRow];
    
    // 3. Simple attributes
    XLFormSectionDescriptor *attributesSection = [XLFormSectionDescriptor formSection];
    [form addFormSection:attributesSection];
    
    XLFormRowDescriptor *subtitlesRow = [XLFormRowDescriptor formRowDescriptorWithTag:@"subtitlesAvailable" rowType:XLFormRowDescriptorTypeBooleanSwitch title:NSLocalizedString(@"With subtitles", @"Setting title")];
    [attributesSection addFormRow:subtitlesRow];
    
    XLFormRowDescriptor *downloadRow = [XLFormRowDescriptor formRowDescriptorWithTag:@"downloadAvailable" rowType:XLFormRowDescriptorTypeBooleanSwitch title:NSLocalizedString(@"Available for download", @"Setting title")];
    [attributesSection addFormRow:downloadRow];
    
    XLFormRowDescriptor *playableAbroadRow = [XLFormRowDescriptor formRowDescriptorWithTag:@"playableAbroad" rowType:XLFormRowDescriptorTypeBooleanSwitch title:NSLocalizedString(@"Playable abroad", @"Setting title")];
    [attributesSection addFormRow:playableAbroadRow];
    
    return form;
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

#pragma mark Actions

- (IBAction)close:(id)sender
{
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
