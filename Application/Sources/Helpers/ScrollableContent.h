//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Protocol allowing view controllers to declare which scrollable view must control collapsable navigation bars and
 *  navigation / tab bar edge appearances.
 */
@protocol ScrollableContent <NSObject>

/**
 *  The scrollable view.
 */
@property (nonatomic, readonly, nullable) UIScrollView *play_scrollableView;

@end

/**
 *  Protocol allowing container view controllers to define how they behave with scrollable children.
 */
@protocol ScrollableContentContainer <NSObject>

/**
 *  The currently active child view controller in the container, if any. Required so that the scrollable view in
 *  a view controller hierarchy can be properly determined.
 */
@property (nonatomic, readonly, nullable) UIViewController *play_scrollableChildViewController;

@optional

/**
 *  Called when the resolved scrollable view located in the container hierarchy is scrolled.
 */
- (void)play_contentOffsetDidChangeInScrollableView:(UIScrollView *)scrollView;

@end

/**
 *  This file provides a convenient formalism to precisely define scrollable behavior in view controller hierarchies:
 *
 *  - View controllers containing scrollable views must conform to the `ScrollableContent` protocol.
 *  - Containers must implement `ScrollableContentContainer` to define which of their children is relevant for
 *    scrolling behavior and to possibly respond to scrolling (e.g. by moving views around).
 *
 *  These protocols are used together when resolving the current scrollable view in a view controller hierarchy.
 */
@interface UIViewController (ScrollableContent)

/**
 *  Scrollable views are automatically resolved when view controllers are displayed. When implementing containers,
 *  however, this mechanism might not suffice, in which case this method can be used to trigger an update.
 */
- (void)play_setNeedsScrollableViewUpdate;

@end

NS_ASSUME_NONNULL_END
