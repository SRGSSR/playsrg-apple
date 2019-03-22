//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGBaseTopic+PlaySRG.h"

#import "ApplicationConfiguration.h"

@interface NSURL (DataProvider_Private)

- (NSURL *)srg_URLForDimension:(SRGImageDimension)dimension withValue:(CGFloat)value uid:(nullable NSString *)uid type:(SRGImageType)type;

@end

@implementation SRGBaseTopic (PlaySRG)

#pragma mark SRGImageMetadata protocol

- (NSURL *)imageURLForDimension:(SRGImageDimension)dimension withValue:(CGFloat)value type:(SRGImageType)type
{
    NSURL *imageURL = [ApplicationConfiguration.sharedApplicationConfiguration imageURLForTopicUid:self.uid];
    return [imageURL srg_URLForDimension:dimension withValue:value uid:self.uid type:type];
}

#pragma mark SRGImage protocol

- (NSString *)imageTitle
{
    return [ApplicationConfiguration.sharedApplicationConfiguration imageTitleForTopicUid:self.uid];
}

- (NSString *)imageCopyright
{
    return [ApplicationConfiguration.sharedApplicationConfiguration imageCopyrightForTopicUid:self.uid];
}

#pragma mark Getter

- (NSURL *)imageURL
{
    return [ApplicationConfiguration.sharedApplicationConfiguration imageURLForTopicUid:self.uid];
}

@end
