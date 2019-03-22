//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>
#import <Mantle/Mantle.h>

NS_ASSUME_NONNULL_BEGIN

@interface Recommendation : MTLModel <MTLJSONSerializing>

/**
 *  The recommendation identifier.
 */
@property (nonatomic, nullable, readonly) NSString *recommendationUid;

/**
 *  The recommended URN list.
 *
 *  @discussion Contains as first item the URN which the recommendation was retrieved for, to which the recommended
 *              medias are appended.
 */
@property (nonatomic, readonly) NSArray<NSString *> *URNs;

@end

NS_ASSUME_NONNULL_END
