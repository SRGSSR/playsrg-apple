//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "CollectionRequestViewController.h"
#import "ContentInsets.h"
#import "RadioChannel.h"

#import <FSCalendar/FSCalendar.h>
#import <SRGAnalytics/SRGAnalytics.h>

NS_ASSUME_NONNULL_BEGIN

@interface CalendarViewController : HLSPlaceholderViewController <ContainerContentInsets, FSCalendarDataSource, FSCalendarDelegate, FSCalendarDelegateAppearance, SRGAnalyticsViewTracking, UIPageViewControllerDataSource, UIPageViewControllerDelegate, UIGestureRecognizerDelegate>

/**
 *  Instantiate for medias belonging to the specified radio channel. If no channel is provided, TV medias will be
 *  displayed instead.
 */
- (instancetype)initWithRadioChannel:(nullable RadioChannel *)radioChannel;

@end

NS_ASSUME_NONNULL_END
