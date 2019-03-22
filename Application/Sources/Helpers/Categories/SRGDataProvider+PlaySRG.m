//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGDataProvider+PlaySRG.h"

@implementation SRGDataProvider (PlaySRG)

- (SRGRequest *)play_increaseSocialCountForActivityType:(UIActivityType)activityType
                                            subdivision:(SRGSubdivision *)subdivision
                                    withCompletionBlock:(SRGSocialCountOverviewCompletionBlock)completionBlock;
{
    if ([activityType.lowercaseString containsString:@"whatsapp"]) {
        return [self increaseSocialCountForType:SRGSocialCountTypeWhatsAppShare
                                    subdivision:subdivision
                            withCompletionBlock:completionBlock];
    }
    else if ([activityType.lowercaseString containsString:@"googleplus"]) {
        return [self increaseSocialCountForType:SRGSocialCountTypeGooglePlusShare
                                    subdivision:subdivision
                            withCompletionBlock:completionBlock];
    }
    else if ([activityType isEqualToString:UIActivityTypePostToFacebook] || [activityType.lowercaseString containsString:@"facebook"]) { // Also catches Facebook Messenger
        return [self increaseSocialCountForType:SRGSocialCountTypeFacebookShare
                                    subdivision:subdivision
                            withCompletionBlock:completionBlock];
    }
    else if ([activityType isEqualToString:UIActivityTypePostToTwitter] || [activityType.lowercaseString containsString:@"twitter"]) {
        return [self increaseSocialCountForType:SRGSocialCountTypeTwitterShare
                                    subdivision:subdivision
                            withCompletionBlock:completionBlock];
    }
    else {
        return nil;
    }
}

@end

