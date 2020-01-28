//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "RadioChannelsViewController.h"

#import "ApplicationSettings.h"
#import "GoogleCastBarButtonItem.h"
#import "HomeViewController.h"
#import "NavigationController.h"
#import "NSBundle+PlaySRG.h"

#import <libextobjc/libextobjc.h>
#import <SRGAppearance/SRGAppearance.h>

@interface RadioChannelsViewController ()

@property (nonatomic, copy) NSString *subtitle;

@property (nonatomic, weak) UILabel *navigationTitleLabel;
@property (nonatomic, weak) UILabel *navigationSubtitleLabel;

@end

@implementation RadioChannelsViewController

#pragma mark Object lifecycle

- (instancetype)initWithRadioChannels:(NSArray<RadioChannel *> *)radioChannels
{
    NSAssert(radioChannels.count > 0, @"1 radio channel at least expected");
    
    NSMutableArray<UIViewController *> *viewControllers = [NSMutableArray array];
    for (RadioChannel *radioChannel in radioChannels) {
        HomeViewController *viewController = [[HomeViewController alloc] initWithRadioChannel:radioChannel];
        viewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:radioChannel.name image:RadioChannelLogo22Image(radioChannel) tag:0];
        [viewControllers addObject:viewController];
    }
    
    NSUInteger initialPage = [radioChannels indexOfObject:ApplicationSettingLastOpenedRadioChannel()];
    if (self = [super initWithViewControllers:viewControllers.copy initialPage:initialPage]) {
        self.title = NSLocalizedString(@"Audios", @"Title displayed at the top of the audio view");
    }
    return self;
}

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    UINavigationBar *navigationBar = self.navigationController.navigationBar;
    if (navigationBar) {
        self.navigationItem.rightBarButtonItem = [[GoogleCastBarButtonItem alloc] initForNavigationBar:navigationBar];
        [self updateNavigationBar:navigationBar];
    }
}

#pragma mark Overrides

- (void)didDisplayViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [super didDisplayViewController:viewController animated:animated];
    
    HomeViewController *homeViewController = (HomeViewController *)viewController;
    RadioChannel *radioChannel = homeViewController.radioChannel;
    self.subtitle = radioChannel.name;
    
    ApplicationSettingSetLastOpenedRadioChannel(radioChannel);
    
    if ([self.navigationController isKindOfClass:NavigationController.class]) {
        NavigationController *navigationController = (NavigationController *)self.navigationController;
        [navigationController updateWithRadioChannel:radioChannel animated:animated];
    }
    
    [self updateNavigationBar:self.navigationController.navigationBar];
}

#pragma mark Navigation bar

- (void)updateNavigationBar:(UINavigationBar *)navigationBar
{
    if (! navigationBar) {
        return;
    }
    
    NSAssert(self.title != nil, @"Expect at title to be defined");
    
    if (self.subtitle) {
        if (! self.navigationItem.titleView) {
            UIStackView *stackView = [[UIStackView alloc] init];
            if (@available(iOS 11, *)) {}
            else {
                stackView.bounds = CGRectMake(0.f, 0.f, 180.f, CGRectGetHeight(navigationBar.frame));
            }
            stackView.axis = UILayoutConstraintAxisVertical;
            self.navigationItem.titleView = stackView;
            
            UILabel *navigationTitleLabel = [[UILabel alloc] init];
            navigationTitleLabel.textAlignment = NSTextAlignmentCenter;
            navigationTitleLabel.alpha = 0.7f;
            [stackView addArrangedSubview:navigationTitleLabel];
            self.navigationTitleLabel = navigationTitleLabel;
            
            UILabel *navigationSubtitleLabel = [[UILabel alloc] init];
            navigationSubtitleLabel.textAlignment = NSTextAlignmentCenter;
            [stackView addArrangedSubview:navigationSubtitleLabel];
            self.navigationSubtitleLabel = navigationSubtitleLabel;
        }
        
        NSDictionary<NSAttributedStringKey, id> *attributes = navigationBar.titleTextAttributes;
        UIFont *font = attributes[NSFontAttributeName] ?: [UIFont systemFontOfSize:18.f];
        
        NSMutableDictionary<NSAttributedStringKey, id> *leadAttributes = attributes.mutableCopy;
        leadAttributes[NSFontAttributeName] = [UIFont fontWithName:font.fontName size:14.f];
        
        self.navigationTitleLabel.attributedText = [[NSAttributedString alloc] initWithString:self.title
                                                                                   attributes:leadAttributes.copy];
        self.navigationSubtitleLabel.attributedText = [[NSAttributedString alloc] initWithString:self.subtitle
                                                                                      attributes:attributes];
        
        self.navigationItem.titleView.accessibilityLabel = [NSString stringWithFormat:@"%@, %@", self.title, self.subtitle];
    }
    else {
        self.navigationItem.titleView = nil;
    }
}

#pragma mark SRGAnalyticsViewTracking protocol

- (NSString *)srg_pageViewTitle
{
    return NSLocalizedString(@"Audios", @"[Technical] Title for audio analytics measurements");
}

- (NSArray<NSString *> *)srg_pageViewLevels
{
    return @[ AnalyticsNameForPageType(AnalyticsPageTypeRadio) ];
}

#pragma mark PlayApplicationNavigation protocol

- (BOOL)openApplicationSectionInfo:(ApplicationSectionInfo *)applicationSectionInfo
{
    if (! applicationSectionInfo.radioChannel) {
        return NO;
    }
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"%K == %@", @keypath(HomeViewController.new, radioChannel), applicationSectionInfo.radioChannel];
    UIViewController *radioChannelViewController = [self.viewControllers filteredArrayUsingPredicate:predicate].firstObject;
    
    if (! radioChannelViewController || ! [radioChannelViewController conformsToProtocol:@protocol(PlayApplicationNavigation)]) {
        return NO;
    }
    
    // Add the selected view controller to the controller stack.
    // Next `openApplicationSectionInfo:` will be able to push other view controllers in the navigation controller.
    NSInteger pageIndex = [self.viewControllers indexOfObject:radioChannelViewController];
    [self switchToIndex:pageIndex animated:NO];
    
    UIViewController<PlayApplicationNavigation> *navigableRootViewController = (UIViewController<PlayApplicationNavigation> *)radioChannelViewController;
    return [navigableRootViewController openApplicationSectionInfo:applicationSectionInfo];
}

@end
