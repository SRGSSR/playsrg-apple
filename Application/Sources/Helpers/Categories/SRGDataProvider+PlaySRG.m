//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "SRGDataProvider+PlaySRG.h"

@implementation SRGDataProvider (PlaySRG)

- (SRGRequest *)play_increaseSocialCountForActivityType:(UIActivityType)activityType
                                                    URN:(NSString *)URN
                                                  event:(NSString *)event
                                    withCompletionBlock:(SRGSocialCountOverviewCompletionBlock)completionBlock;
{
    if ([activityType.lowercaseString containsString:@"whatsapp"]) {
        return [self increaseSocialCountForType:SRGSocialCountTypeWhatsAppShare
                                            URN:URN
                                          event:event
                            withCompletionBlock:completionBlock];
    }
    else if ([activityType.lowercaseString containsString:@"googleplus"]) {
        return [self increaseSocialCountForType:SRGSocialCountTypeGooglePlusShare
                                            URN:URN
                                          event:event
                            withCompletionBlock:completionBlock];
    }
    else if ([activityType isEqualToString:UIActivityTypePostToFacebook] || [activityType.lowercaseString containsString:@"facebook"]) { // Also catches Facebook Messenger
        return [self increaseSocialCountForType:SRGSocialCountTypeFacebookShare
                                            URN:URN
                                          event:event
                            withCompletionBlock:completionBlock];
    }
    else if ([activityType isEqualToString:UIActivityTypePostToTwitter] || [activityType.lowercaseString containsString:@"twitter"]) {
        return [self increaseSocialCountForType:SRGSocialCountTypeTwitterShare
                                            URN:URN
                                          event:event
                            withCompletionBlock:completionBlock];
    }
    else {
        return nil;
    }
}

@end

