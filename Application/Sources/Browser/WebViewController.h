//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "AnalyticsConstants.h"
#import "BaseViewController.h"
#import "ContentInsets.h"
#import "Orientation.h"
#import "ScrollableContent.h"

@import SRGAnalytics;
@import WebKit;

NS_ASSUME_NONNULL_BEGIN

// Block signatures.
typedef void (^WebViewControllerCustomizationBlock)(WKWebView *webView);

/**
 *  A basic web view controller class for in-app display.
 */
@interface WebViewController : BaseViewController <ContentInsets, Oriented, ScrollableContent, SRGAnalyticsViewTracking, UIScrollViewDelegate, WKNavigationDelegate>

/**
 *  Create an instance. The associated web view can be customized by implementing an optional customization block, called right after
 *  the web view has been created.
 */
- (instancetype)initWithRequest:(NSURLRequest *)request
             customizationBlock:(nullable WebViewControllerCustomizationBlock)customizationBlock
                decisionHandler:(WKNavigationActionPolicy (^ _Nullable)(NSURL *))decisionHandler;

/**
 *  Page title. Must be set before view display.
 *
 *  @discussion If `nil` no tracking is made.
 */
@property (nonatomic, copy, nullable) NSString *analyticsPageTitle;

/**
 *  Page type. Must be set before view display.
 *
 *  @discussion If `nil` no tracking is made.
 */
@property (nonatomic, copy, nullable) NSString *analyticsPageType;

/**
 *  Page levels. Defaults to `nil`.
 */
@property (nonatomic, nullable) NSArray<AnalyticsPageLevel> *analyticsPageLevels;

@end

NS_ASSUME_NONNULL_END
