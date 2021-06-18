//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "TVChannel.h"

@interface TVChannel ()

@end

@implementation TVChannel

@end

UIImage *TVChannelLogoImage(TVChannel *tvChannel)
{
    return [UIImage imageNamed:[NSString stringWithFormat:@"logo_%@", tvChannel.resourceUid]] ?: [UIImage imageNamed:@"tv"];
}

UIImage *TVChannelLargeLogoImage(TVChannel *tvChannel)
{
    return [UIImage imageNamed:[NSString stringWithFormat:@"logo_%@-large", tvChannel.resourceUid]] ?: [UIImage imageNamed:@"tv-large"];
}
