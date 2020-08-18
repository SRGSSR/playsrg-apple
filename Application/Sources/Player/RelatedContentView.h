//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGDataProvider/SRGDataProvider.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface RelatedContentView : UIView

@property (class, nonatomic, readonly) RelatedContentView *view;

@property (nonatomic) SRGRelatedContent *relatedContent;

@end

NS_ASSUME_NONNULL_END
