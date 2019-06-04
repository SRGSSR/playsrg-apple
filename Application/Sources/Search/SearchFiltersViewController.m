//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SearchFiltersViewController.h"

#import "AnalyticsConstants.h"
#import "UIColor+PlaySRG.h"
#import "UIViewController+PlaySRG.h"

@implementation SearchFiltersViewController

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
