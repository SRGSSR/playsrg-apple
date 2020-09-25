//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import Mantle;

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, UpdateType) {
    UpdateTypeNone = 0,
    UpdateTypeMandatory,
    UpdateTypeOptional
};

@interface UpdateInfo : MTLModel <MTLJSONSerializing>

@property (nonatomic, readonly) UpdateType type;
@property (nonatomic, readonly, copy, nullable) NSString *reason;

@end

NS_ASSUME_NONNULL_END
