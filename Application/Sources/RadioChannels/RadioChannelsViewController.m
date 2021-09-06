//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "RadioChannelsViewController.h"

#import "ApplicationSettings.h"
#import "GoogleCastBarButtonItem.h"
#import "NavigationController.h"
#import "NSBundle+PlaySRG.h"
#import "PlaySRG-Swift.h"

@import libextobjc;
@import SRGAppearance;

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
        UIViewController *viewController = [PageViewController audiosViewControllerForRadioChannel:radioChannel];
        viewController.tabBarItem = [[UITabBarItem alloc] initWithTitle:radioChannel.name image:RadioChannelLogoImage(radioChannel) tag:0];
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
    
    PageViewController *pageViewController = (PageViewController *)viewController;
    RadioChannel *radioChannel = pageViewController.radioChannel;
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
