//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Mantle/Mantle.h>

NS_ASSUME_NONNULL_BEGIN

@interface SearchSettingsMultiSelectionItem : MTLModel

- (instancetype)initWithName:(NSString *)name value:(NSString *)value count:(NSInteger)count;

@property (nonatomic, readonly, copy) NSString *name;
@property (nonatomic, readonly, copy) NSString *value;
@property (nonatomic, readonly) NSUInteger count;

@end

@interface SearchSettingsMultiSelectionItem (Unavailable)

- (instancetype)init NS_UNAVAILABLE;

@end

NS_ASSUME_NONNULL_END
