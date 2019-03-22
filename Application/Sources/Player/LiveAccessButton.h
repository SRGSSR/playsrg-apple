//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <SRGDataProvider/SRGDataProvider.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface LiveAccessButton : UIButton

@property (nonatomic, getter=isLeftSeparatorHidden) BOOL leftSeparatorHidden;
@property (nonatomic, getter=isRightSeparatorHidden) BOOL rightSeparatorHidden;

@property (nonatomic) UIColor *highlightedBackgroundColor;
@property (nonatomic) SRGMedia *media;

@end

NS_ASSUME_NONNULL_END
