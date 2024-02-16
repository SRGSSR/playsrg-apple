//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "CalendarViewController.h"

#import "AnalyticsConstants.h"
#import "ApplicationConfiguration.h"
#import "ApplicationSection.h"
#import "Calendar.h"
#import "NSBundle+PlaySRG.h"
#import "PlaySRG-Swift.h"
#import "UIDevice+PlaySRG.h"
#import "UIViewController+PlaySRG.h"

@import libextobjc;
@import MAKVONotificationCenter;
@import SRGAppearance;
@import SRGDataProviderModel;

@interface CalendarViewController ()

@property (nonatomic) RadioChannel *radioChannel;
@property (nonatomic) NSDate *initialDate;

@property (nonatomic) UIPageViewController *pageViewController;

@property (nonatomic, weak) Calendar *calendar;
@property (nonatomic, weak) UIVisualEffectView *blurView;

@property (nonatomic, weak) NSLayoutConstraint *calendarHeightConstraint;
@property (nonatomic, weak) NSLayoutConstraint *calendarTopConstraint;

@property (nonatomic) UISelectionFeedbackGenerator *selectionFeedbackGenerator;

@property (nonatomic, weak) UIPanGestureRecognizer *scopeGestureRecognizer;

@end

@implementation CalendarViewController

#pragma mark Object lifecycle

- (instancetype)initWithRadioChannel:(RadioChannel *)radioChannel date:(NSDate *)date
{
    if (self = [self init]) {
        self.radioChannel = radioChannel;
        self.initialDate = date;
        self.selectionFeedbackGenerator = [[UISelectionFeedbackGenerator alloc] init];
        
        UIPageViewController *pageViewController = [[UIPageViewController alloc] initWithTransitionStyle:UIPageViewControllerTransitionStyleScroll
                                                                                   navigationOrientation:UIPageViewControllerNavigationOrientationHorizontal
                                                                                                 options:@{ UIPageViewControllerOptionInterPageSpacingKey : @100.f }];
        pageViewController.delegate = self;
        self.pageViewController = pageViewController;
        
        [self addChildViewController:pageViewController];
    }
    return self;
}

#pragma mark Getters and setters

- (NSString *)title
{
    return TitleForApplicationSection(ApplicationSectionShowByDate);
}

#pragma mark View lifecycle

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.view.backgroundColor = UIColor.srg_gray16Color;
    
    UIView *pageView = self.pageViewController.view;
    [self.view addSubview:pageView];
    
    pageView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [pageView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [pageView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [pageView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [pageView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor]
    ]];
    
    [self.pageViewController didMoveToParentViewController:self];
    
    Calendar *calendar = [[Calendar alloc] init];
    calendar.backgroundColor = UIColor.clearColor;
    calendar.firstWeekday = NSCalendar.srg_defaultCalendar.firstWeekday;
    calendar.dataSource = self;
    calendar.delegate = self;
    // Display full calendar for easier access when voice over is running (only a month of content)
    calendar.scope = UIAccessibilityIsVoiceOverRunning() ? FSCalendarScopeMonth : FSCalendarScopeWeek;
    // Hide months on the left and right
    calendar.appearance.headerMinimumDissolvedAlpha = 0.0;
    [self.view addSubview:calendar];
    self.calendar = calendar;
    
    calendar.translatesAutoresizingMaskIntoConstraints = false;
    [NSLayoutConstraint activateConstraints:@[
        self.calendarTopConstraint = [calendar.topAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.topAnchor],
        [calendar.leadingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.leadingAnchor],
        [calendar.trailingAnchor constraintEqualToAnchor:self.view.safeAreaLayoutGuide.trailingAnchor],
        self.calendarHeightConstraint = [calendar.heightAnchor constraintEqualToConstant:300.f]
    ]];
    
    UIVisualEffectView *blurView = UIVisualEffectView.play_blurView;
    blurView.alpha = 0.f;
    [self.view insertSubview:blurView belowSubview:calendar];
    self.blurView = blurView;
    
    blurView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [blurView.topAnchor constraintEqualToAnchor:calendar.topAnchor],
        [blurView.bottomAnchor constraintEqualToAnchor:calendar.bottomAnchor],
        [blurView.leadingAnchor constraintEqualToAnchor:calendar.leadingAnchor],
        [blurView.trailingAnchor constraintEqualToAnchor:calendar.trailingAnchor]
    ]];
    
    self.pageViewController.dataSource = self;
    
    // Add pan gesture to the whole view. This pan gesture will trigger the calendar handleScope: method in such
    // a way that the calendar is expanded or collapsed also when the collection is scrolled (see gesture recognizer
    // delegate implementation)
    UIPanGestureRecognizer *scopeGestureRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:calendar action:@selector(handleScopeGesture:)];
    scopeGestureRecognizer.delegate = self;
    [self.view addGestureRecognizer:scopeGestureRecognizer];
    self.scopeGestureRecognizer = scopeGestureRecognizer;
    
    FSCalendarAppearance *calendarAppearance = calendar.appearance;
    
    // Month / year
    calendarAppearance.headerTitleColor = UIColor.whiteColor;
    
    // Week days
    calendarAppearance.weekdayTextColor = UIColor.whiteColor;
    
    // Days (the default color is controlled by the appearance delegate)
    calendarAppearance.titleSelectionColor = [UIColor.whiteColor colorWithAlphaComponent:0.8f];
    
    // Dot colors
    calendarAppearance.selectionColor = UIColor.srg_redColor;
    calendarAppearance.todayColor = [UIColor.srg_redColor colorWithAlphaComponent:0.4f];
    
    [self updateFonts];
    
    if (self.initialDate) {
        // Minimum / maximum dates read from the calendar directly have an incorrect value
        NSDate *minimumDate = [self minimumDateForCalendar:calendar];
        NSDate *maximumDate = [self maximumDateForCalendar:calendar];
        
        NSDateInterval *dateInterval = [[NSDateInterval alloc] initWithStartDate:minimumDate endDate:maximumDate];
        NSDate *date = [dateInterval containsDate:self.initialDate] ? self.initialDate : calendar.today;
        [self showMediasForDate:date animated:NO];
    }
    else {
        [self showMediasForDate:calendar.today animated:NO];
    }
    
    [NSNotificationCenter.defaultCenter addObserver:self
                                           selector:@selector(accessibilityVoiceOverStatusChanged:)
                                               name:UIAccessibilityVoiceOverStatusDidChangeNotification
                                             object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(contentSizeCategoryDidChange:)
                                                 name:UIContentSizeCategoryDidChangeNotification
                                               object:nil];
    
    // Cannot use `-calendar:boundingRectWillChange:animated: since not called with end values.
    @weakify(self)
    [calendar addObserver:self keyPath:@keypath(FSCalendar.new, bounds) options:0 block:^(MAKVONotification *notification) {
        @strongify(self)
        
        [self.pageViewController.viewControllers enumerateObjectsUsingBlock:^(__kindof UIViewController * _Nonnull viewController, NSUInteger idx, BOOL * _Nonnull stop) {
            [viewController play_setNeedsContentInsetsUpdate];
        }];
    }];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    
    // Fix calendar rotation issues (if revealed after a modal was displayed and rotation occurred)
    dispatch_async(dispatch_get_main_queue(), ^{
        [self.calendar reloadData];
    });
}

#pragma mark Rotation

- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator
{
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    
    [coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext> _Nonnull context) {
        if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone && size.width > size.height) {
            [self.calendar setScope:FSCalendarScopeWeek animated:NO];
        }
        
        // This makes the calendar animation look nicer
        [self.calendar reloadData];
    } completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
        [self.calendar reloadData];
    }];
}

#pragma mark Accessibility

- (void)updateFonts
{
    FSCalendarAppearance *calendarAppearance = self.calendar.appearance;
    
    // Month / year
    calendarAppearance.headerTitleFont = [SRGFont fontWithStyle:SRGFontStyleBody];
    
    // Week days
    calendarAppearance.weekdayFont = [SRGFont fontWithStyle:SRGFontStyleBody];
    
    // Days
    calendarAppearance.titleFont = [SRGFont fontWithStyle:SRGFontStyleBody];
}

#pragma mark Status bar

- (UIStatusBarStyle)preferredStatusBarStyle
{
    return UIStatusBarStyleLightContent;
}

#pragma mark Content

- (void)showMediasForDate:(NSDate *)date animated:(BOOL)animated
{
    // Always scroll to the date, but does not switch the view controller if it hasn't changed
    [self.calendar selectDate:date];
    
    UIViewController<DailyMediasViewController> *currentDailyMediasViewController = self.pageViewController.viewControllers.firstObject;
    
    UIPageViewControllerNavigationDirection navigationDirection = UIPageViewControllerNavigationDirectionForward;
    if (currentDailyMediasViewController) {
        NSComparisonResult dateComparisonResult = [NSCalendar.srg_defaultCalendar compareDate:date toDate:currentDailyMediasViewController.date toUnitGranularity:NSCalendarUnitDay];
        if (dateComparisonResult == NSOrderedSame) {
            return;
        }
        else if (dateComparisonResult == NSOrderedAscending) {
            navigationDirection = UIPageViewControllerNavigationDirectionReverse;
        }
    }
    
    UIViewController *newDailyMediasViewController = [SectionViewController mediasViewControllerForDay:[SRGDay dayFromDate:date] channelUid:self.radioChannel.uid];
    [self.pageViewController setViewControllers:@[newDailyMediasViewController] direction:navigationDirection animated:animated completion:nil];
    [self play_setNeedsScrollableViewUpdate];
    
    [self setNavigationBarItemsHidden:[date isEqualToDate:self.calendar.today]];
}

- (void)setNavigationBarItemsHidden:(BOOL)hidden
{
    if (!hidden) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedString(@"Today", @"Title of the button to go back to the current date")
                                                                                  style:UIBarButtonItemStylePlain
                                                                                 target:self
                                                                                 action:@selector(goToToday:)];
    }
    else {
        self.navigationItem.rightBarButtonItem = nil;
    }
}

#pragma mark FSCalendarDataSource protocol

- (NSDate *)minimumDateForCalendar:(FSCalendar *)calendar
{
    NSDateComponents *dateComponents = [NSCalendar.srg_defaultCalendar components:NSCalendarUnitYear | NSCalendarUnitMonth | NSCalendarUnitDay fromDate:NSDate.date];
    
    if (UIAccessibilityIsVoiceOverRunning()) {
        dateComponents.month -= 1;
    }
    else {
        dateComponents.year -= 5;
    }
    return [NSCalendar.srg_defaultCalendar dateFromComponents:dateComponents];
}

- (NSDate *)maximumDateForCalendar:(FSCalendar *)calendar
{
    return NSDate.date;
}

#pragma mark FSCalendarDelegate protocol

- (void)calendar:(FSCalendar *)calendar boundingRectWillChange:(CGRect)bounds animated:(BOOL)animated
{
    self.calendarHeightConstraint.constant = CGRectGetHeight(bounds);
    [self.view layoutIfNeeded];
}

- (void)calendar:(FSCalendar *)calendar didSelectDate:(NSDate *)date atMonthPosition:(FSCalendarMonthPosition)monthPosition
{
    [self.selectionFeedbackGenerator selectionChanged];
    [self showMediasForDate:date animated:YES];
}

- (void)calendarCurrentPageDidChange:(FSCalendar *)calendar
{
    UIViewController<DailyMediasViewController> *dailyMediasViewController = self.pageViewController.viewControllers.firstObject;
    NSCalendarUnit unitGranularity = (calendar.scope == FSCalendarScopeMonth) ? NSCalendarUnitMonth : NSCalendarUnitWeekOfYear;
    
    // Hidden if in the same page as today and current date is not today
    BOOL hidden = [NSCalendar.srg_defaultCalendar compareDate:calendar.currentPage toDate:calendar.today toUnitGranularity:unitGranularity] == NSOrderedSame
        && [calendar.today isEqualToDate:dailyMediasViewController.date];
    [self setNavigationBarItemsHidden:hidden];
}

#pragma mark FSCalendarDelegateAppearance protocol

- (UIColor *)calendar:(FSCalendar *)calendar appearance:(FSCalendarAppearance *)appearance titleDefaultColorForDate:(NSDate *)date
{
    NSDate *startDate = [self minimumDateForCalendar:calendar];
    NSDate *endDate = [self maximumDateForCalendar:calendar];
    NSDateInterval *dateInterval = [[NSDateInterval alloc] initWithStartDate:startDate endDate:endDate];
    return [dateInterval containsDate:date] ? UIColor.srg_grayC7Color : [UIColor.srg_grayC7Color colorWithAlphaComponent:0.4f];
}

#pragma mark ContainerContentInsets protocol

- (UIEdgeInsets)play_additionalContentInsets
{
    return UIEdgeInsetsMake(CGRectGetHeight(self.calendar.frame), 0.f, 0.f, 0.f);
}

- (void)play_contentOffsetDidChangeInScrollableView:(UIScrollView *)scrollView
{
    CGFloat adjustedOffset = scrollView.contentOffset.y + scrollView.adjustedContentInset.top;
    self.calendarTopConstraint.constant = fmaxf(-adjustedOffset, 0.f);
    self.blurView.alpha = fmax(0.f, fminf(1.f, adjustedOffset / LayoutBlurActivationDistance));
}

#pragma mark ScrollableContentContainer protocol

- (UIViewController *)play_scrollableChildViewController
{
    return self.pageViewController.viewControllers.firstObject;
}

#pragma mark SRGAnalyticsViewTracking protocol

- (NSString *)srg_pageViewTitle
{
    return AnalyticsPageTitleShowsCalendar;
}

- (NSString *)srg_pageViewType
{
    return AnalyticsPageTypeOverview;
}

- (NSArray<NSString *> *)srg_pageViewLevels
{
    if (self.radioChannel) {
        return @[ AnalyticsPageLevelPlay, AnalyticsPageLevelAudio, self.radioChannel.name ];
    }
    else {
        return @[ AnalyticsPageLevelPlay, AnalyticsPageLevelVideo ];
    }
}

#pragma mark UIGestureRecognizerDelegate protocol

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)gestureRecognizer
{
    // Disable the gesture altogether when VoiceOver is running
    if (UIAccessibilityIsVoiceOverRunning()) {
        return NO;
    }
    
    CGSize size = self.view.frame.size;
    if (UIDevice.currentDevice.userInterfaceIdiom == UIUserInterfaceIdiomPhone && size.width > size.height) {
        return NO;
    }
    
    // Always trigger the scope gesture if started within the calendar frame
    CGPoint locationInCalendar = [gestureRecognizer locationInView:self.calendar];
    if (CGRectContainsPoint(self.calendar.bounds, locationInCalendar)) {
        return YES;
    }
    
    // Elsewhere only take into account sufficiently vertical gestures to trigger it
    CGPoint velocity = [self.scopeGestureRecognizer velocityInView:self.view];
    if (fabs(velocity.y) < fabs(velocity.x)) {
        return NO;
    }
    
    // When displaying the month, any upward gesture collapses the calendar
    if (self.calendar.scope == FSCalendarScopeMonth) {
        return velocity.y < 0;
    }
    // When displaying the day, only downward gestures at the top expand the calendar. This way, pull-to-refresh
    // can also be triggered for the collection view, even when the calendar is in week view (this can occur while the
    // collection is bouncing at its top). If implemented with less care, pull-to-refresh would have been possible
    // only when the calendar is in monthly view, which is impractical on small screens
    else {
        UIViewController<DailyMediasViewController> *currentDailyMediasViewController = self.pageViewController.viewControllers.firstObject;
        UIScrollView *scrollView = currentDailyMediasViewController.scrollView;
        UIEdgeInsets contentInsets = ContentInsetsForScrollView(scrollView);
        return velocity.y > 0 && fabs(scrollView.contentOffset.y - scrollView.contentInset.top + contentInsets.top) < 1;
    }
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldBeRequiredToFailByGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    UIViewController<DailyMediasViewController> *currentDailyMediasViewController = self.pageViewController.viewControllers.firstObject;
    UIScrollView *scrollView = currentDailyMediasViewController.scrollView;
    return otherGestureRecognizer.view == scrollView && [otherGestureRecognizer isKindOfClass:UIPanGestureRecognizer.class];
}

#pragma mark UIPageViewControllerDataSource protocol

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerBeforeViewController:(UIViewController *)viewController
{
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    dateComponents.day = -1;
    
    UIViewController<DailyMediasViewController> *currentDailyMediasViewController = (UIViewController<DailyMediasViewController> *)viewController;
    NSDate *date = [NSCalendar.srg_defaultCalendar dateByAddingComponents:dateComponents toDate:currentDailyMediasViewController.date options:0];
    return [SectionViewController mediasViewControllerForDay:[SRGDay dayFromDate:date] channelUid:self.radioChannel.uid];
}

- (UIViewController *)pageViewController:(UIPageViewController *)pageViewController viewControllerAfterViewController:(UIViewController *)viewController
{
    UIViewController<DailyMediasViewController> *currentDailyMediasViewController = (UIViewController<DailyMediasViewController> *)viewController;
    if ([currentDailyMediasViewController.date isEqualToDate:self.calendar.today]) {
        return nil;
    }
    
    NSDateComponents *dateComponents = [[NSDateComponents alloc] init];
    dateComponents.day = 1;
    
    NSDate *date = [NSCalendar.srg_defaultCalendar dateByAddingComponents:dateComponents toDate:currentDailyMediasViewController.date options:0];
    return [SectionViewController mediasViewControllerForDay:[SRGDay dayFromDate:date] channelUid:self.radioChannel.uid];
}

#pragma mark UIPageViewControllerDelegate protocol

- (void)pageViewController:(UIPageViewController *)pageViewController willTransitionToViewControllers:(NSArray<UIViewController *> *)pendingViewControllers
{
    UIViewController<DailyMediasViewController> *newDailyMediasViewController = (UIViewController<DailyMediasViewController> *)pendingViewControllers.firstObject;
    [self.calendar selectDate:newDailyMediasViewController.date];
}

- (void)pageViewController:(UIPageViewController *)pageViewController didFinishAnimating:(BOOL)finished previousViewControllers:(NSArray<UIViewController *> *)previousViewControllers transitionCompleted:(BOOL)completed
{
    NSDate *date = nil;
    
    if (! completed) {
        UIViewController<DailyMediasViewController> *previousDailyMediasViewController = (UIViewController<DailyMediasViewController> *)previousViewControllers.firstObject;
        date = previousDailyMediasViewController.date;
        [self.calendar selectDate:date];
    }
    else {
        UIViewController<DailyMediasViewController> *currentDailyMediasViewController = (UIViewController<DailyMediasViewController> *)pageViewController.viewControllers.firstObject;
        date = currentDailyMediasViewController.date;
        [self play_setNeedsScrollableViewUpdate];
    }
    
    [self setNavigationBarItemsHidden:[date isEqualToDate:self.calendar.today]];
}

#pragma mark Actions

- (void)goToToday:(id)sender
{
    [self showMediasForDate:self.calendar.today animated:YES];
}

#pragma mark Notifications

- (void)accessibilityVoiceOverStatusChanged:(NSNotification *)notification
{
    if (UIAccessibilityIsVoiceOverRunning()) {
        [self.calendar setScope:FSCalendarScopeMonth animated:YES];
    }
    
    // Reload the date range
    [self.calendar reloadData];
}

- (void)contentSizeCategoryDidChange:(NSNotification *)notification
{
    [self updateFonts];
}

@end
