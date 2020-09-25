//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "TopicSection.h"

NSString *TitleForTopicSection(TopicSection topicSection)
{
    static NSDictionary<NSNumber *, NSString *> *s_names;
    static dispatch_once_t s_onceToken;
    dispatch_once(&s_onceToken, ^{
        s_names = @{ @(TopicSectionLatest) : NSLocalizedString(@"Most recent", @"Short title for the most recent video topic list"),
                     @(TopicSectionMostPopular) : NSLocalizedString(@"Most popular", @"Short title for the most clicked video topic list") };
    });
    return s_names[@(topicSection)];
}
