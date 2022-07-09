//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ContentInsets.h"

#import "UIView+PlaySRG.h"

@import DZNEmptyDataSet;

#import <objc/runtime.h>

static void UpdateContentInsetsForViewController(UIViewController *viewController);

@implementation UIViewController (ContentInsets)

#pragma mark Class methods

+ (void)load
{
    method_exchangeImplementations(class_getInstanceMethod(self, @selector(viewDidLoad)),
                                   class_getInstanceMethod(self, @selector(UIViewController_ContentInsets_swizzled_viewDidLoad)));
    method_exchangeImplementations(class_getInstanceMethod(self, @selector(viewWillAppear:)),
                                   class_getInstanceMethod(self, @selector(UIViewController_ContentInsets_swizzled_viewWillAppear:)));
    method_exchangeImplementations(class_getInstanceMethod(self, @selector(viewWillLayoutSubviews)),
                                   class_getInstanceMethod(self, @selector(UIViewController_ContentInsets_swizzled_viewWillLayoutSubviews)));
}

#pragma mark Swizzled methods

- (void)UIViewController_ContentInsets_swizzled_viewDidLoad
{
    [self UIViewController_ContentInsets_swizzled_viewDidLoad];
    
    // Apply content insets calculations in -viewDidLoad as well for correct initial content offset
    UpdateContentInsetsForViewController(self);
}

- (void)UIViewController_ContentInsets_swizzled_viewWillAppear:(BOOL)animated
{
    [self UIViewController_ContentInsets_swizzled_viewWillAppear:animated];
    
    // DZNEmpty data set calculations must account for content insets. Perform with the next run loop iteration to force
    // a data set reload with accurate context for calculations.
    dispatch_async(dispatch_get_main_queue(), ^{
        UpdateContentInsetsForViewController(self);
        
        if ([self conformsToProtocol:@protocol(ContentInsets)]) {
            UIViewController<ContentInsets> *contentViewController = (UIViewController<ContentInsets> *)self;
            NSArray<UIScrollView *> *scrollViews = contentViewController.play_contentScrollViews;
            [scrollViews enumerateObjectsUsingBlock:^(UIScrollView * _Nonnull scrollView, NSUInteger idx, BOOL * _Nonnull stop) {
                [scrollView reloadEmptyDataSet];
            }];
        }
    });
}

- (void)UIViewController_ContentInsets_swizzled_viewWillLayoutSubviews
{
    [self UIViewController_ContentInsets_swizzled_viewWillLayoutSubviews];
    
    UpdateContentInsetsForViewController(self);
}

#pragma mark Helpers

- (UIViewController *)play_effectiveContentParentViewController
{
    if (! [self conformsToProtocol:@protocol(ContentInsets)]) {
        return self.parentViewController;
    }
    
    UIViewController<ContentInsets> *contentViewController = (UIViewController<ContentInsets> *)self;
    if ([contentViewController respondsToSelector:@selector(play_contentParentViewController)]) {
        return contentViewController.play_contentParentViewController;
    }
    else {
        return contentViewController.parentViewController;
    }
}

- (NSArray<UIViewController *> *)play_effectiveChildViewControllers
{
    if (! [self conformsToProtocol:@protocol(ContainerContentInsets)]) {
        return self.childViewControllers;
    }
    
    UIViewController<ContainerContentInsets> *containerViewController = (UIViewController<ContainerContentInsets> *)self;
    if ([containerViewController respondsToSelector:@selector(play_contentChildViewControllers)]) {
        return containerViewController.play_contentChildViewControllers;
    }
    else {
        return containerViewController.childViewControllers;
    }
}

#pragma mark Updates

- (void)play_setNeedsContentInsetsUpdate
{
    UpdateContentInsetsForViewController(self);
    
    [self.play_effectiveChildViewControllers enumerateObjectsUsingBlock:^(UIViewController * _Nonnull viewController, NSUInteger idx, BOOL * _Nonnull stop) {
        [viewController play_setNeedsContentInsetsUpdate];
    }];
}

@end

/**
 *  Recommended additional content insets to be applied for child controllers of the specified view controller, taking
 *  into account contributions from its whole view controller hierarchy.
 */
static UIEdgeInsets ChildContentInsetsForViewController(UIViewController *viewController)
{
    UIEdgeInsets insets = UIEdgeInsetsZero;
    
    UIViewController *currentViewController = viewController;
    while (currentViewController) {
        if ([currentViewController conformsToProtocol:@protocol(ContainerContentInsets)]) {
            UIEdgeInsets currentInsets = ((id<ContainerContentInsets>)currentViewController).play_additionalContentInsets;
            insets = UIEdgeInsetsMake(insets.top + currentInsets.top,
                                      insets.left + currentInsets.left,
                                      insets.bottom + currentInsets.bottom,
                                      insets.right + currentInsets.right);
        }
        currentViewController = currentViewController.play_effectiveContentParentViewController;
    }
    
    return insets;
}

static void UpdateContentInsetsForViewController(UIViewController *viewController)
{
    if (! [viewController conformsToProtocol:@protocol(ContentInsets)]) {
        return;
    }
    
    UIViewController<ContentInsets> *contentViewController = (UIViewController<ContentInsets> *)viewController;
    NSArray<UIScrollView *> *scrollViews = contentViewController.play_contentScrollViews;
    UIEdgeInsets paddingInsets = contentViewController.play_paddingContentInsets;
    
    contentViewController.additionalSafeAreaInsets = ChildContentInsetsForViewController(viewController.play_effectiveContentParentViewController);
    [scrollViews enumerateObjectsUsingBlock:^(UIScrollView * _Nonnull scrollView, NSUInteger idx, BOOL * _Nonnull stop) {
        scrollView.contentInset = paddingInsets;
    }];
}

UIEdgeInsets ContentInsetsForViewController(UIViewController *viewController)
{
    UIEdgeInsets insets = ChildContentInsetsForViewController(viewController.play_effectiveContentParentViewController);
    UIEdgeInsets safeAreaInsets = viewController.additionalSafeAreaInsets;
    return UIEdgeInsetsMake(insets.top + safeAreaInsets.top,
                            insets.left + safeAreaInsets.left,
                            insets.bottom + safeAreaInsets.bottom,
                            insets.right + safeAreaInsets.right);
}

UIEdgeInsets ContentInsetsForScrollView(UIScrollView *scrollView)
{
    // Extract the padding applied to the scroll view, if any
    UIEdgeInsets paddingInsets = UIEdgeInsetsZero;
    UIViewController *nearestViewController = scrollView.play_nearestViewController;
    if ([nearestViewController conformsToProtocol:@protocol(ContentInsets)]) {
        UIViewController<ContentInsets> *contentViewController = (UIViewController<ContentInsets> *)nearestViewController;
        if ([contentViewController.play_contentScrollViews containsObject:scrollView]) {
            paddingInsets = contentViewController.play_paddingContentInsets;
        }
    }
    
    return UIEdgeInsetsMake(scrollView.adjustedContentInset.top + paddingInsets.top,
                            scrollView.adjustedContentInset.left + paddingInsets.left,
                            scrollView.adjustedContentInset.bottom + paddingInsets.bottom,
                            scrollView.adjustedContentInset.right + paddingInsets.right);
}

CGFloat VerticalOffsetForEmptyDataSet(UIScrollView *scrollView)
{
    // Returns the offset to apply to the empty data set center so that its center lies within the visible
    // scroll area. This is required since the empty view is not resized to take into account content insets.
    UIEdgeInsets contentInsets = ContentInsetsForScrollView(scrollView);
    return -(contentInsets.top + contentInsets.bottom) / 2.f;
}
