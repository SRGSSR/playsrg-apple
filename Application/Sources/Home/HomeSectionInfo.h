//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "HomeSection.h"
#import "TopicSection.h"

@import Foundation;
@import SRGDataProviderNetwork;

NS_ASSUME_NONNULL_BEGIN

typedef void (^SRGPaginatedItemListCompletionBlock)(NSArray * _Nullable items, SRGPage *page, SRGPage * _Nullable nextPage, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error);
typedef void (^SRGItemListCompletionBlock)(NSArray * _Nullable items, NSHTTPURLResponse * _Nullable HTTPResponse, NSError * _Nullable error);

@interface HomeSectionInfo : NSObject

- (instancetype)initWithHomeSection:(HomeSection)homeSection topicSection:(TopicSection)topicSection object:(nullable id)object NS_DESIGNATED_INITIALIZER;
- (instancetype)initWithHomeSection:(HomeSection)homeSection object:(nullable id)object;
- (instancetype)initWithHomeSection:(HomeSection)homeSection;

@property (nonatomic, readonly) HomeSection homeSection;
@property (nonatomic, readonly) Class cellClass;
@property (nonatomic, readonly) BOOL canOpenList;

@property (nonatomic, readonly, nullable) id object;
@property (nonatomic, readonly, getter=isHidden) BOOL hidden;

@property (nonatomic, readonly, copy, nullable) NSString *identifier;
@property (nonatomic, readonly, nullable) SRGModule *module;
@property (nonatomic, readonly, nullable) SRGBaseTopic *topic;
@property (nonatomic, readonly) TopicSection topicSection;

@property (nonatomic, copy, nullable) NSString *title;
@property (nonatomic) CGPoint contentOffset;

@property (nonatomic, copy, nullable) NSString *parentTitle;

@property (nonatomic, readonly, nullable) NSArray *items;

- (void)refreshWithRequestQueue:(SRGRequestQueue *)requestQueue page:(nullable SRGPage *)page completionBlock:(SRGPaginatedItemListCompletionBlock)completionBlock;

@end

NS_ASSUME_NONNULL_END
