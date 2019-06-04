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
    
    // 2. Context settings
    XLFormSectionDescriptor *contextSection = [XLFormSectionDescriptor formSection];
    [form addFormSection:contextSection];
    
    // - Show
    NSMutableArray<XLFormOptionsObject *> *showSelectorOptions = [NSMutableArray array];
    
    NSArray<SRGShowBucket *> *showBuckets = [aggregations.showBuckets sortedArrayUsingDescriptors:@[titleSortDescriptor]];
    for (SRGShowBucket *showBucket in showBuckets) {
        [showSelectorOptions addObject:[XLFormOptionsObject formOptionsObjectWithValue:showBucket.URN displayText:showBucket.title]];
    }
    
    XLFormRowDescriptor *showRow = [XLFormRowDescriptor formRowDescriptorWithTag:@"showURN" rowType:XLFormRowDescriptorTypeMultipleSelector title:NSLocalizedString(@"Show", @"Show setting title")];
    showRow.selectorTitle = NSLocalizedString(@"Show", @"Show setting title");
    showRow.selectorOptions = [showSelectorOptions copy];
    [contextSection addFormRow:showRow];
    
    // - Topic
    NSMutableArray<XLFormOptionsObject *> *topicSelectorOptions = [NSMutableArray array];
    
    NSArray<SRGTopicBucket *> *topicBuckets = [aggregations.topicBuckets sortedArrayUsingDescriptors:@[titleSortDescriptor]];
    for (SRGTopicBucket *topicBucket in topicBuckets) {
        [topicSelectorOptions addObject:[XLFormOptionsObject formOptionsObjectWithValue:topicBucket.URN displayText:topicBucket.title]];
    }
    
    XLFormRowDescriptor *topicRow = [XLFormRowDescriptor formRowDescriptorWithTag:@"topicURN" rowType:XLFormRowDescriptorTypeMultipleSelector title:NSLocalizedString(@"Topic", @"Topic setting title")];
    topicRow.selectorTitle = NSLocalizedString(@"Topic", @"Topic setting title");
    topicRow.selectorOptions = [topicSelectorOptions copy];
    [contextSection addFormRow:topicRow];
    
    // 3. Simple attributes
    XLFormSectionDescriptor *attributesSection = [XLFormSectionDescriptor formSection];
    [form addFormSection:attributesSection];
    
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
