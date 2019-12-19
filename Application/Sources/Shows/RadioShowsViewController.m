//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "RadioShowsViewController.h"

#import "ShowsViewController.h"

@implementation RadioShowsViewController

#pragma mark Object lifecycle

- (instancetype)initWithRadioChannels:(NSArray<RadioChannel *> *)radioChannels alphabeticalIndex:(NSString *)alphabeticalIndex
{
    NSAssert(radioChannels.count > 1, @"Several radio channels expected");
    
    NSMutableArray<UIViewController *> *viewControllers = [NSMutableArray array];
    for (RadioChannel *radioChannel in radioChannels) {
        ShowsViewController *showsViewController = [[ShowsViewController alloc] initWithRadioChannel:radioChannel alphabeticalIndex:alphabeticalIndex];
        showsViewController.play_pageItem = [[PageItem alloc] initWithTitle:radioChannel.name image:RadioChannelLogo22Image(radioChannel)];
        [viewControllers addObject:showsViewController];
    }
    
    if (self = [super initWithViewControllers:viewControllers.copy]) {
        self.title = NSLocalizedString(@"Radio programmes A-Z", @"Title displayed at the top of the radio show list");
    }
    return self;
}

#pragma mark SRGAnalyticsViewTracking protocol

- (NSString *)srg_pageViewTitle
{
    return NSLocalizedString(@"Programmes A-Z", @"[Technical] Title for programmes A-Z analytics measurements");
}

- (NSArray<NSString *> *)srg_pageViewLevels
{
    return @[ AnalyticsNameForPageType(AnalyticsPageTypeRadio) ];
}

@end
