//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import SRGDataProviderModel;

NS_ASSUME_NONNULL_BEGIN

@interface HomeStatusHeaderView : UIView

+ (CGFloat)heightForServiceMessage:(SRGServiceMessage *)serviceMessage withSize:(CGSize)size;

@property (class, nonatomic, readonly) HomeStatusHeaderView *view;

@property (nonatomic, nullable) SRGServiceMessage *serviceMessage;

@end

NS_ASSUME_NONNULL_END
