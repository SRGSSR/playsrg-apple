//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NavigationController.h"

#import "UIViewController+PlaySRG.h"

#import <CoconutKit/CoconutKit.h>
#import <SRGAppearance/SRGAppearance.h>

@interface NavigationController ()

@property (nonatomic) RadioChannel *radioChannel;

@end

@implementation NavigationController

#pragma mark Object lifecycle

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController radioChannel:(RadioChannel *)radioChannel
{
    if (self = [super initWithRootViewController:rootViewController]) {
        self.radioChannel = radioChannel;
        
        self.autorotationMode = HLSAutorotationModeContainerAndTopChildren;
        
        UINavigationBar *navigationBar = self.navigationBar;
        navigationBar.barStyle = UIBarStyleBlack;
        
        // Apply radio channel colors with a small shadow for better readability
        UIColor *radioChannelColor = radioChannel.color;
        if (radioChannel.color) {
            navigationBar.layer.shadowOpacity = 1.f;
            
            navigationBar.barTintColor = radioChannelColor;
            navigationBar.translucent = NO;
        }
        // Use standard blur with no shadow (which would break the blur).
        else {
            navigationBar.layer.shadowOpacity = 0.f;
            
            navigationBar.barTintColor = nil;
            navigationBar.translucent = YES;
        }
        
        UIColor *tintColor = radioChannel.titleColor ?: UIColor.whiteColor;
        navigationBar.tintColor = tintColor;
        navigationBar.titleTextAttributes = @{ NSFontAttributeName : [UIFont srg_mediumFontWithSize:18.f],
                                               NSForegroundColorAttributeName : tintColor };
        
        for (NSNumber *controlState in @[ @(UIControlStateNormal), @(UIControlStateHighlighted), @(UIControlStateDisabled), @(UIControlStateSelected), @(UIControlStateSelected | UIControlStateHighlighted) ]) {
            [[UIBarButtonItem appearanceWhenContainedInInstancesOfClasses:@[self.class]] setTitleTextAttributes:@{ NSFontAttributeName : [UIFont srg_regularFontWithSize:16.f],
                                                                                                                   NSForegroundColorAttributeName : tintColor }
                                                                                                       forState:controlState.integerValue];
        }
    }
    return self;
}

- (instancetype)initWithRootViewController:(UIViewController *)rootViewController
{
    return [self initWithRootViewController:rootViewController radioChannel:nil];
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
    if (self.radioChannel) {
        return self.radioChannel.darkStatusBar ? UIStatusBarStyleDefault : UIStatusBarStyleLightContent;
    }
    else {
        return [self.topViewController preferredStatusBarStyle];
    }
}

- (UIStatusBarAnimation)preferredStatusBarUpdateAnimation
{
    return [self.topViewController preferredStatusBarUpdateAnimation];
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

@end
