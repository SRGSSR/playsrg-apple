//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "ContentInsets.h"
#import "RadioChannel.h"

#import <FSCalendar/FSCalendar.h>

@import SRGAnalytics;

NS_ASSUME_NONNULL_BEGIN

@interface CalendarViewController : UIViewController <ContainerContentInsets, FSCalendarDataSource, FSCalendarDelegate, FSCalendarDelegateAppearance, SRGAnalyticsViewTracking, UIPageViewControllerDataSource, UIPageViewControllerDelegate, UIGestureRecognizerDelegate>

/**
 *  Instantiate for medias belonging to the specified radio channel. If no channel is provided, TV medias will be
 *  displayed instead. If a date in the future is provided, today's results will be displayed instead.
 */
- (instancetype)initWithRadioChannel:(nullable RadioChannel *)radioChannel date:(nullable NSDate *)date;

@end

NS_ASSUME_NONNULL_END
