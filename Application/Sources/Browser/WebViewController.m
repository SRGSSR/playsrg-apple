//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "WebViewController.h"

#import "Reachability.h"
#import "UIColor+PlaySRG.h"
#import "UIImageView+PlaySRG.h"
#import "UIViewController+PlaySRG.h"

@import libextobjc;
@import SRGAppearance;
@import SRGNetwork;

static void *s_kvoContext = &s_kvoContext;

@interface WebViewController ()

@property (nonatomic) NSURLRequest *request;

@property (nonatomic, weak) UIProgressView *progressView;
@property (nonatomic, weak) WKWebView *webView;
@property (nonatomic, weak) UIImageView *loadingImageView;
@property (nonatomic, weak) UILabel *errorLabel;
@property (nonatomic, weak) NSLayoutConstraint *progressTopConstraint;

@property (nonatomic, copy) WebViewControllerCustomizationBlock customizationBlock;
@property (nonatomic, copy) WKNavigationActionPolicy (^decisionHandler)(NSURL *URL);

@end

@implementation WebViewController

#pragma mark Object lifecycle

- (instancetype)initWithRequest:(NSURLRequest *)request
             customizationBlock:(WebViewControllerCustomizationBlock)customizationBlock
                decisionHandler:(WKNavigationActionPolicy (^)(NSURL *))decisionHandler
{
    if (self = [self init]) {
        self.request = request;
        self.customizationBlock = customizationBlock;
        self.decisionHandler = decisionHandler;
    }
    return self;
}

- (void)dealloc
{
    self.webView = nil;             // Unregister KVO
}

#pragma mark Getters and setters

- (void)setWebView:(WKWebView *)webView
{
    [_webView removeObserver:self forKeyPath:@keypath(WKWebView.new, estimatedProgress) context:s_kvoContext];
    _webView = webView;
    [_webView addObserver:self forKeyPath:@keypath(WKWebView.new, estimatedProgress) options:NSKeyValueObservingOptionNew context:s_kvoContext];
}

#pragma mark View lifecycle

- (void)loadView
{
    UIView *view = [[UIView alloc] initWithFrame:UIScreen.mainScreen.bounds];
    view.backgroundColor = UIColor.srg_gray16Color;
    
    // WKWebView cannot be instantiated in storyboards, do it programmatically
    WKWebView *webView = [[WKWebView alloc] init];
    webView.opaque = NO;
    webView.backgroundColor = UIColor.clearColor;
    webView.alpha = 0.0f;
    webView.navigationDelegate = self;
    webView.scrollView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    webView.scrollView.delegate = self;
    [view insertSubview:webView atIndex:0];
    
    webView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [webView.topAnchor constraintEqualToAnchor:view.safeAreaLayoutGuide.topAnchor],
        [webView.bottomAnchor constraintEqualToAnchor:view.bottomAnchor],
        [webView.leadingAnchor constraintEqualToAnchor:view.safeAreaLayoutGuide.leadingAnchor],
        [webView.trailingAnchor constraintEqualToAnchor:view.safeAreaLayoutGuide.trailingAnchor]
    ]];
    self.webView = webView;
    
    if (self.customizationBlock) {
        self.customizationBlock(webView);
    }
    
    UIImageView *loadingImageView = [UIImageView play_largeLoadingImageViewWithTintColor:UIColor.srg_grayC7Color];
    loadingImageView.hidden = YES;
    [view insertSubview:loadingImageView atIndex:0];
    self.loadingImageView = loadingImageView;
    
    loadingImageView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [loadingImageView.centerXAnchor constraintEqualToAnchor:view.safeAreaLayoutGuide.centerXAnchor],
        [loadingImageView.centerYAnchor constraintEqualToAnchor:view.safeAreaLayoutGuide.centerYAnchor]
    ]];
    
    UILabel *errorLabel = [[UILabel alloc] init];
    errorLabel.textColor = UIColor.whiteColor;
    errorLabel.font = [SRGFont fontWithStyle:SRGFontStyleBody];
    [view addSubview:errorLabel];
    self.errorLabel = errorLabel;
    
    errorLabel.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [errorLabel.leadingAnchor constraintEqualToAnchor:view.safeAreaLayoutGuide.leadingAnchor constant:40.f],
        [errorLabel.trailingAnchor constraintEqualToAnchor:view.safeAreaLayoutGuide.trailingAnchor constant:-40.f],
        [errorLabel.centerYAnchor constraintEqualToAnchor:view.centerYAnchor]
    ]];
    
    UIProgressView *progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
    progressView.progressTintColor = UIColor.srg_redColor;
    [view addSubview:progressView];
    self.progressView = progressView;
    
    progressView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [progressView.leadingAnchor constraintEqualToAnchor:view.leadingAnchor],
        [progressView.trailingAnchor constraintEqualToAnchor:view.trailingAnchor],
        self.progressTopConstraint = [progressView.topAnchor constraintEqualToAnchor:view.safeAreaLayoutGuide.topAnchor]
    ]];
    
    self.view = view;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.webView loadRequest:self.request];
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(webViewController_reachabilityDidChange:)
                                               name:FXReachabilityStatusDidChangeNotification
                                             object:nil];
}

#pragma mark Status bar

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#pragma mark ContentInsets protocol

- (NSArray<UIScrollView *> *)play_contentScrollViews
{
    UIScrollView *scrollView = self.webView.scrollView;
    return scrollView ? @[scrollView] : nil;
}

- (UIEdgeInsets)play_paddingContentInsets
{
    // Must adjust depending on the web page viewport-fit setting, see https://modelessdesign.com/backdrop/283
    UIScrollView *scrollView = self.webView.scrollView;
    if (scrollView.contentInsetAdjustmentBehavior == UIScrollViewContentInsetAdjustmentNever) {
        return scrollView.safeAreaInsets;
    }
    else {
        return UIEdgeInsetsZero;
    }
}

#pragma mark ScrollableContent protocol

- (UIScrollView *)play_scrollableView
{
    return self.webView.scrollView;
}

#pragma mark SRGAnalyticsViewTracking protocol

- (NSString *)srg_pageViewTitle
{
    return self.analyticsPageTitle ?: @"";
}

- (NSArray<NSString *> *)srg_pageViewLevels
{
    return self.analyticsPageLevels;
}

#pragma mark UIScrollViewDelegate protocol

- (void)scrollViewDidChangeAdjustedContentInset:(UIScrollView *)scrollView
{
    [self play_setNeedsContentInsetsUpdate];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    CGFloat adjustedOffset = scrollView.contentOffset.y + scrollView.adjustedContentInset.top;
    self.progressTopConstraint.constant = fmaxf(-adjustedOffset, 0.f);
}

#pragma mark WKNavigationDelegate protocol

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation
{
    self.loadingImageView.hidden = NO;
    self.errorLabel.text = nil;
    
    [UIView animateWithDuration:0.3 animations:^{
        self.progressView.alpha = 1.f;
    }];
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    self.loadingImageView.hidden = YES;
    self.errorLabel.text = nil;
    
    [UIView animateWithDuration:0.3 animations:^{
        self.webView.alpha = 1.f;
        self.progressView.alpha = 0.f;
    }];
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error
{
    self.loadingImageView.hidden = YES;
    NSError *updatedError = error;
    
    NSURL *failingURL = ([error.domain isEqualToString:NSURLErrorDomain]) ? error.userInfo[NSURLErrorFailingURLErrorKey] : nil;
    if (failingURL && ! [failingURL.scheme isEqualToString:@"http"] && ! [failingURL.scheme isEqualToString:@"https"] && ! [failingURL.scheme isEqualToString:@"file"]) {
        updatedError = nil;
    }

    if ([updatedError.domain isEqualToString:NSURLErrorDomain]) {
        self.errorLabel.text = [NSHTTPURLResponse srg_localizedStringForURLErrorCode:updatedError.code];
        
        [UIView animateWithDuration:0.3 animations:^{
            self.progressView.alpha = 0.f;
            self.webView.alpha = 0.f;
        }];
    }
    else {
        self.errorLabel.text = nil;
        
        [webView goBack];
        
        [UIView animateWithDuration:0.3 animations:^{
            self.progressView.alpha = 0.f;
        }];
    }
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    if (self.decisionHandler) {
        decisionHandler(self.decisionHandler(navigationAction.request.URL));
    }
    else {
        NSURLComponents *URLComponents = [NSURLComponents componentsWithURL:navigationAction.request.URL resolvingAgainstBaseURL:NO];
        if (! [URLComponents.scheme isEqualToString:@"http"] && ! [URLComponents.scheme isEqualToString:@"https"] && ! [URLComponents.scheme isEqualToString:@"file"]) {
            [UIApplication.sharedApplication openURL:URLComponents.URL options:@{} completionHandler:nil];
            decisionHandler(WKNavigationActionPolicyCancel);
        }
        else {
            decisionHandler(WKNavigationActionPolicyAllow);
        }
    }
}

#pragma mark Notifications

- (void)webViewController_reachabilityDidChange:(NSNotification *)notification
{
    if (ReachabilityBecameReachable(notification)) {
        if (self.play_viewVisible) {
            [self.webView loadRequest:self.request];
        }
    }
}

#pragma mark KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if (context == s_kvoContext) {
        if ([keyPath isEqualToString:@keypath(WKWebView.new, estimatedProgress)]) {
            self.progressView.progress = self.webView.estimatedProgress;
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

@end
