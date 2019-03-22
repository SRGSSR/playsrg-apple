//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "BaseViewController.h"
#import "ContentInsets.h"

#import <WebKit/WebKit.h>

NS_ASSUME_NONNULL_BEGIN

// Block signatures.
typedef void (^WebViewControllerCustomizationBlock)(WKWebView *webView);

/**
 *  A basic web view controller class for in-app display.
 */
@interface WebViewController : BaseViewController <ContentInsets, WKNavigationDelegate, UIScrollViewDelegate>

/**
 *  Create an instance. The associated web view can be customized by implementing an optional customization block, called right after
 *  the web view has been created.
 */
- (instancetype)initWithRequest:(NSURLRequest *)request customizationBlock:(nullable WebViewControllerCustomizationBlock)customizationBlock decisionHandler:(WKNavigationActionPolicy (^ _Nullable)(NSURL *))decisionHandler analyticsPageType:(AnalyticsPageType)analyticsPageType;

/**
 *  Set to `NO` to disable automatic analytics tracking for page view events (mostly useful if the associated website performs the
 *  tracking itself, so that double measurements can be avoided).
 *
 *  Default value is `YES`.
 */
@property (nonatomic, getter=isTracked) BOOL tracked;

@end

NS_ASSUME_NONNULL_END
