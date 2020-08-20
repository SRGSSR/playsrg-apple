//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, TopicSection) {
    TopicSectionUnknown = 0,
    TopicSectionLatest,
    TopicSectionMostPopular
};

OBJC_EXPORT NSString *TitleForTopicSection(TopicSection topicSection);

NS_ASSUME_NONNULL_END
