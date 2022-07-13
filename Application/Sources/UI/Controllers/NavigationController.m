//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NavigationController.h"

#import "UIColor+PlaySRG.h"
#import "UIViewController+PlaySRG.h"

@import SRGAppearance;

@interface NavigationController ()

@property (nonatomic) UIStatusBarStyle statusBarStyle;

@end

@implementation NavigationController

#pragma mark Object lifecycle

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController
                                 tintColor:(UIColor *)tintColor
                           backgroundColor:(UIColor *)backgroundColor
                            statusBarStyle:(UIStatusBarStyle)statusBarStyle
{
    if (self = [super initWithRootViewController:rootViewController]) {
        self.delegate = self;
        [self updateWithTintColor:tintColor backgroundColor:backgroundColor statusBarStyle:statusBarStyle];
    }
    return self;
}

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController
{
    return [self initWithRootViewController:rootViewController tintColor:nil backgroundColor:nil statusBarStyle:UIStatusBarStyleLightContent];
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(voiceOverStatusDidChange:)
                                               name:UIAccessibilityVoiceOverStatusDidChangeNotification
                                             object:nil];
    [self updateLargeTitleAppearance];
}

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wdeprecated-implementations"

- (instancetype)initWithNavigationBarClass:(Class)navigationBarClass toolbarClass:(Class)toolbarClass
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder
{
    [self doesNotRecognizeSelector:_cmd];
    return nil;
}

#pragma clang diagnostic pop

#pragma mark Status bar

- (BOOL)prefersStatusBarHidden
{
    return [self.topViewController prefersStatusBarHidden];
}

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return self.statusBarStyle;
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation
{
    return [self.topViewController preferredStatusBarUpdateAnimation];
}

#pragma mark UI updates

- (void)updateWithTintColor:(UIColor *)tintColor backgroundColor:(UIColor *)backgroundColor statusBarStyle:(UIStatusBarStyle)statusBarStyle
{
    self.statusBarStyle = statusBarStyle;
    [self setNeedsStatusBarAppearanceUpdate];
    
    UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
    if (backgroundColor) {
        [appearance configureWithOpaqueBackground];
        appearance.backgroundColor = backgroundColor;
    }
    else {
        [appearance configureWithDefaultBackground];
    }
    
    // Remove the separator (looks nicer)
    appearance.shadowColor = UIColor.clearColor;
    
    UIColor *foregroundColor = tintColor ?: UIColor.srg_grayC7Color;
    appearance.titleTextAttributes = @{
        NSFontAttributeName : [SRGFont fontWithFamily:SRGFontFamilyText weight:UIFontWeightSemibold fixedSize:17.f],
        NSForegroundColorAttributeName : foregroundColor
    };
    appearance.largeTitleTextAttributes = @{
        NSFontAttributeName : [SRGFont fontWithFamily:SRGFontFamilyDisplay weight:UIFontWeightBold fixedSize:30.f],
        NSForegroundColorAttributeName : foregroundColor
    };
    
    NSDictionary<NSAttributedStringKey, id> *buttonAttributes = @{
        NSFontAttributeName : [SRGFont fontWithFamily:SRGFontFamilyText weight:SRGFontWeightRegular fixedSize:16.f],
        NSForegroundColorAttributeName : foregroundColor
    };
    
    UIBarButtonItemAppearance *plainButtonAppearance = [[UIBarButtonItemAppearance alloc] initWithStyle:UIBarButtonItemStylePlain];
    plainButtonAppearance.normal.titleTextAttributes = buttonAttributes;
    appearance.buttonAppearance = plainButtonAppearance;
    
    UIBarButtonItemAppearance *doneButtonAppearance = [[UIBarButtonItemAppearance alloc] initWithStyle:UIBarButtonItemStyleDone];
    doneButtonAppearance.normal.titleTextAttributes = buttonAttributes;
    appearance.doneButtonAppearance = doneButtonAppearance;
    
    UINavigationBar *navigationBar = self.navigationBar;
    navigationBar.tintColor = foregroundColor;          // Still use the old customization API to set the icon tint color
    navigationBar.standardAppearance = appearance;
    navigationBar.compactAppearance = appearance;
    if (backgroundColor) {
        navigationBar.scrollEdgeAppearance = appearance;
    }
    
    // Force appearance settings to be applied again, see https://stackoverflow.com/a/37668610/760435
    self.navigationBarHidden = YES;
    self.navigationBarHidden = NO;
}

- (void)updateWithRadioChannel:(RadioChannel *)radioChannel animated:(BOOL)animated
{
    void (^animations)(void) = ^{
        UIStatusBarStyle darkStatusBarStyle = UIStatusBarStyleDefault;
        darkStatusBarStyle = UIStatusBarStyleDarkContent;
        
        UIStatusBarStyle statusBarStyle = radioChannel.hasDarkStatusBar ? darkStatusBarStyle : UIStatusBarStyleLightContent;
        [self updateWithTintColor:radioChannel.titleColor backgroundColor:radioChannel.color statusBarStyle:statusBarStyle];
    };
    
    if (animated) {
        [UIView animateWithDuration:0.2 animations:animations];
    }
    else {
        animations();
    }
}

- (void)updateLargeTitleAppearance
{
    UINavigationBar *navigationBar = self.navigationBar;
    if (@available(iOS 15, *)) {
        // There are some issues with large titles and accessibility (e.g. ordering of headers in a view controller
        // decorated with a search controller). To avoid any issues we just disable large titles when VoiceOver is
        // enabled.
        navigationBar.prefersLargeTitles = ! UIAccessibilityIsVoiceOverRunning();
    }
}

#pragma mark Accessibility

- (BOOL)accessibilityPerformEscape
{
    if (self.navigationController.viewControllers.count > 1) {
        [self.navigationController popViewControllerAnimated:YES];
        return YES;
    }
    else if (self.presentingViewController) {
        [self dismissViewControllerAnimated:YES completion:nil];
        return YES;
    }
    else {
        return NO;
    }
}

#pragma mark PlayApplicationNavigation protocol

- (BOOL)openApplicationSectionInfo:(ApplicationSectionInfo *)applicationSectionInfo
{
    [self popToRootViewControllerAnimated:NO];
    
    UIViewController *rootViewController = self.viewControllers.firstObject;
    if ([rootViewController conformsToProtocol:@protocol(PlayApplicationNavigation)]) {
        UIViewController<PlayApplicationNavigation> *navigableRootViewController = (UIViewController<PlayApplicationNavigation> *)rootViewController;
        return [navigableRootViewController openApplicationSectionInfo:applicationSectionInfo];
    }
    else {
        return NO;
    }
}

#pragma mark ScrollableContentContainer protocol

- (UIViewController *)play_scrollableChildViewController
{
    return self.topViewController;
}

#pragma mark TabBarActionable protocol

- (void)performActiveTabActionAnimated:(BOOL)animated
{
    if (self.viewControllers.count == 1) {
        UIViewController *rootViewController = self.viewControllers.firstObject;
        if ([rootViewController conformsToProtocol:@protocol(TabBarActionable)]) {
            UIViewController<TabBarActionable> *actionableRootViewController = (UIViewController<TabBarActionable> *)rootViewController;
            [actionableRootViewController performActiveTabActionAnimated:animated];
        }
    }
    else {
        // Natively performed when a navigation controller is directly embedded in a tab bar controller, but here triggered
        // explicitly for all other kinds of embedding as well (e.g. tab bar -> split view -> navigation).
        [self popToRootViewControllerAnimated:animated];
    }
}

#pragma mark UINavigationControlelrDelegate protocol

- (void)navigationController:(UINavigationController *)navigationController didShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    [self play_setNeedsScrollableViewUpdate];
}

#pragma mark Notifications

- (void)voiceOverStatusDidChange:(NSNotification *)notification
{
    [self updateLargeTitleAppearance];
}

@end
