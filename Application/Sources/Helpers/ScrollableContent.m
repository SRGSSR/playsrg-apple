//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ScrollableContent.h"

#import <objc/runtime.h>

@import libextobjc;
@import MAKVONotificationCenter;

static void *s_contentOffsetRegistrationKey = &s_contentOffsetRegistrationKey;

static void UpdateContentViewForViewController(UIViewController *viewController);
static UIScrollView *ScrollableViewInViewController(UIViewController *viewController);

@implementation UIViewController (ScrollableContent)

#pragma mark Class methods

+ (void)load
{
    method_exchangeImplementations(class_getInstanceMethod(self, @selector(viewWillAppear:)),
                                   class_getInstanceMethod(self, @selector(UIViewController_ScrollableContent_swizzled_viewWillAppear:)));
}

#pragma mark Swizzled methods

- (void)UIViewController_ScrollableContent_swizzled_viewWillAppear:(BOOL)animated
{
    [self UIViewController_ScrollableContent_swizzled_viewWillAppear:animated];
    
    UpdateContentViewForViewController(self);
}

#pragma mark Updates

- (void)play_setNeedsScrollableViewUpdate
{
    UpdateContentViewForViewController(self);
    
    [self.parentViewController play_setNeedsScrollableViewUpdate];
}

@end

static void UpdateContentViewForViewController(UIViewController *viewController)
{
    id<MAKVOObservation> previousContentOffsetObservation = objc_getAssociatedObject(viewController, s_contentOffsetRegistrationKey);
    [previousContentOffsetObservation remove];
    
    UIScrollView *scrollableView = ScrollableViewInViewController(viewController);
    if (! scrollableView) {
        return;
    }
    
    if (@available(iOS 15, tvOS 15, *)) {
        [viewController setContentScrollView:scrollableView forEdge:NSDirectionalRectEdgeAll];
    }
    
    if ([viewController conformsToProtocol:@protocol(ScrollableContentContainer)]) {
        UIViewController<ScrollableContentContainer> *containerViewController = (UIViewController<ScrollableContentContainer> *)viewController;
        if ([containerViewController respondsToSelector:@selector(play_contentOffsetDidChangeInScrollableView:)]) {
            @weakify(containerViewController) @weakify(scrollableView)
            id<MAKVOObservation> contentOffsetObservation = [scrollableView addObserver:viewController keyPath:@keypath(scrollableView.contentOffset) options:NSKeyValueObservingOptionInitial block:^(MAKVONotification *notification) {
                @strongify(containerViewController) @strongify(scrollableView)
                [containerViewController play_contentOffsetDidChangeInScrollableView:scrollableView];
            }];
            objc_setAssociatedObject(viewController, s_contentOffsetRegistrationKey, contentOffsetObservation, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
        }
    }
}

static UIScrollView *ScrollableViewInViewController(UIViewController *viewController)
{
    if ([viewController conformsToProtocol:@protocol(ScrollableContent)]) {
        UIViewController<ScrollableContent> *scrollableViewController = (UIViewController<ScrollableContent> *)viewController;
        UIScrollView *scrollableView = scrollableViewController.play_scrollableView;
        if (scrollableView) {
            return scrollableView;
        }
    }
    
    if ([viewController conformsToProtocol:@protocol(ScrollableContentContainer)]) {
        UIViewController<ScrollableContentContainer> *containerViewController = (UIViewController<ScrollableContentContainer> *)viewController;
        UIViewController *scrollableChildViewController = containerViewController.play_scrollableChildViewController;
        if (scrollableChildViewController) {
            return ScrollableViewInViewController(scrollableChildViewController);
        }
        else {
            return nil;
        }
    }
    else {
        return nil;
    }
}
