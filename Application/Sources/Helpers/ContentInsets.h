//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Protocol allowing view controllers to define their content inset behavior.
 */
@protocol ContentInsets <NSObject>

/**
 *  Contained scroll views whose content offsets might need to be adjusted when the view controller is part of a
 *  view controller hierarchy.
 */
@property (nonatomic, readonly, nullable) NSArray<UIScrollView *> *play_contentScrollViews;

/**
 *  Additional content insets applied to the declared scroll views.
 */
@property (nonatomic, readonly) UIEdgeInsets play_paddingContentInsets;

@optional

/**
 *  Parent view controller for the content. If this method is not implemented the default `parentViewController`
 *  is used. This method is only useful for special containments where the parent-child relationship is not obvious
 *  (e.g. search controller).
 */
@property (nonatomic, readonly, nullable) UIViewController *play_contentParentViewController;

@end

/**
 *  Protocol allowing container view controllers to define the content inset behavior to apply to their children.
 */
@protocol ContainerContentInsets <NSObject>

/**
 *  Additional content insets to be applied to child view controllers.
 */
@property (nonatomic, readonly) UIEdgeInsets play_additionalContentInsets;

@optional

/**
 *  Child controllers for the container. If this method is not implemented the default `childViewControllers` property
 *  is used. This method is only useful for special containments where the parent-child relationship is not obvious
 *  (e.g. search controller).
 */
@property (nonatomic, readonly) NSArray<UIViewController *> *play_contentChildViewControllers;

@end

/**
 *  This file provide a convenient formalism to precisely define content inset contributions in view controller
 *  hierarchies:
 *
 *  - View controllers containing scrollable views must conform to the `ContentInsets` protocol to declare which
 *    views are scrollable so that their insets can be adjusted automatically.
 *  - Containers can implement `ContainerContentInsets` to declare non-trivial parent-child relationships or
 *    to define additional insets related to their layout (e.g. bar covering an area where their children will be
 *    displayed).
 */
@interface UIViewController (ContentInsets)

/**
 *  Content inset adjustments for view controllers conforming to the `ContentInsets` protocol are automatically
 *  applied when their view appears. When implementing containers, however, this mechanism might not suffice, in
 *  which case this method can be used to trigger an update.
 */
- (void)play_setNeedsContentInsetsUpdate;

@end

/**
 *  Recommended content insets to be applied for the specified view controller, taking into account contributions from
 *  its whole view controller hierarchy.
 *
 *  @discussion This value takes layout guides, resp. safe area contributions, into account.
 */
OBJC_EXPORT UIEdgeInsets ContentInsetsForViewController(UIViewController * _Nullable viewController);

/**
 *  Content insets currently applied to the specified scroll view.
 */
OBJC_EXPORT UIEdgeInsets ContentInsetsForScrollView(UIScrollView * _Nullable scrollView);

/**
 *  Recommended vertical offset to be applied to empty data sets attached to the specified scroll view (when implementing
 *  the `DZNEmptyDataSet` `-verticalOffsetForEmptyDataSet:` delegate method).
 */
OBJC_EXPORT CGFloat VerticalOffsetForEmptyDataSet(UIScrollView * _Nullable scrollView);

NS_ASSUME_NONNULL_END
