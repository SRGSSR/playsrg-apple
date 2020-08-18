//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "DataViewController.h"

#import "Banner.h"
#import "UIViewController+PlaySRG.h"

#import <FXReachability/FXReachability.h>
#import <SRGDataProvider/SRGDataProvider.h>

@implementation DataViewController

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(dataViewController_applicationDidBecomeActive:)
                                               name:UIApplicationDidBecomeActiveNotification
                                             object:nil];
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(dataViewController_reachabilityDidChange:)
                                               name:FXReachabilityStatusDidChangeNotification
                                             object:nil];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    [self refresh];
}

#pragma mark Stubs

- (void)refresh
{}

#pragma mark Notifications

- (void)dataViewController_applicationDidBecomeActive:(NSNotification *)notification
{
    if (self.play_viewVisible) {
        [self refresh];
    }
}

- (void)dataViewController_reachabilityDidChange:(NSNotification *)notification
{
    if ([FXReachability sharedInstance].reachable) {
        if (self.play_viewVisible) {
            [self refresh];
        }
    }
}

@end
