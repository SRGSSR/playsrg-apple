//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "RadioChannelsViewController.h"
#import "PlaySRG-Swift.h"

@import libextobjc;

@interface RadioChannelsViewController ()

@property (nonatomic, copy) NSString *radioChannelName;

@end

@implementation RadioChannelsViewController

#pragma mark Object lifecycle

- (instancetype)initWithRadioChannels:(NSArray<RadioChannel *> *)radioChannels
{
    NSAssert(radioChannels.count > 0, @"1 radio channel at least expected");
    
    NSMutableArray<UIViewController *> *viewControllers = [NSMutableArray array];
    for (RadioChannel *radioChannel in radioChannels) {
        PageViewController *pageViewController = [PageViewController audiosViewControllerForRadioChannel:radioChannel];
        pageViewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:radioChannel.name image:RadioChannelLogoImage(radioChannel) tag:0];
        [viewControllers addObject:pageViewController];
    }
    
    NSUInteger initialPage = [radioChannels indexOfObject:ApplicationSettingLastOpenedRadioChannel()];
    if (self = [super initWithViewControllers:viewControllers.copy initialPage:initialPage]) {
        [self updateTitle];
    }
    return self;
}

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self updateTitle];
    
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    if (navigationBar) {
        self.navigationItem.rightBarButtonItem = [[GoogleCastBarButtonItem alloc] initForNavigationBar:navigationBar];
    }
}

#pragma mark Overrides

- (void)didDisplayViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [super didDisplayViewController:viewController animated:animated];
    
    PageViewController *pageViewController = (PageViewController *)viewController;
    RadioChannel *radioChannel = pageViewController.radioChannel;
    self.radioChannelName = radioChannel.name;
    
    ApplicationSettingSetLastOpenedRadioChannel(radioChannel);
    
    if ([self.navigationController isKindOfClass:NavigationController.class]) {
        NavigationController *navigationController = (NavigationController *)self.navigationController;
        [navigationController updateWithRadioChannel:radioChannel animated:animated];
    }
    
    [self updateTitle];
}

#pragma mark Navigation bar

- (void)updateTitle
{
    self.navigationItem.title = self.radioChannelName ?: NSLocalizedString(@"Audios", @"Title displayed at the top of the audio view");
}

#pragma mark PlayApplicationNavigation protocol

- (BOOL)openApplicationSectionInfo:(ApplicationSectionInfo *)applicationSectionInfo
{
    if (! applicationSectionInfo.radioChannel) {
        return NO;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @keypath(PageViewController.new, radioChannel), applicationSectionInfo.radioChannel];
    UIViewController *radioChannelViewController = [self.viewControllers filteredArrayUsingPredicate:predicate].firstObject;
    
    if (! radioChannelViewController || ! [radioChannelViewController conformsToProtocol:@protocol(PlayApplicationNavigation)]) {
        return NO;
    }
    
    // Add the selected view controller to the controller stack.
    // Next `openApplicationSectionInfo:` will be able to push other view controllers in the navigation controller.
    NSInteger pageIndex = [self.viewControllers indexOfObject:radioChannelViewController];
    [self switchToIndex:pageIndex animated:NO];
    
    UIViewController<PlayApplicationNavigation> *navigableViewController = (UIViewController<PlayApplicationNavigation> *)radioChannelViewController;
    return [navigableViewController openApplicationSectionInfo:applicationSectionInfo];
}

@end
