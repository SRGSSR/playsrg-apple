//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "NotificationService.h"

#import "UserNotification.h"

@import MobileCoreServices;
@import SRGDataProviderNetwork;

static NSString *NotificationServiceUTIFromMIMEType(NSString *MIMEType)
{
    return (NSString *)CFBridgingRelease(UTTypeCreatePreferredIdentifierForTag(kUTTagClassMIMEType, (__bridge CFStringRef _Nonnull)MIMEType, NULL));
}

@interface NotificationService ()

@property (nonatomic) SRGDataProvider *dataProvider;

@property (nonatomic, copy) void (^contentHandler)(UNNotificationContent *contentToDeliver);
@property (nonatomic) UNNotificationContent *notificationContent;

@property (nonatomic) NSURLSessionDownloadTask *downloadTask;

@end

@implementation NotificationService

#pragma mark Object lifecycle

- (instancetype)init
{
    if (self = [super init]) {
        self.dataProvider = [[SRGDataProvider alloc] initWithServiceURL:SRGIntegrationLayerProductionServiceURL()];
    }
    return self;
}

#pragma mark Subclassing hooks

- (void)didReceiveNotificationRequest:(UNNotificationRequest *)request withContentHandler:(void (^)(UNNotificationContent * _Nonnull))contentHandler
{
    UNNotificationContent *notificationContent = request.content;
    
    // Keep references for expiration method implementation
    self.notificationContent = notificationContent;
    self.contentHandler = contentHandler;
    
    UserNotification *notification = [[UserNotification alloc] initWithRequest:request];
    [UserNotification saveNotification:notification read:NO];
    
    self.downloadTask = [self imageDownloadTaskForNotification:notification content:notificationContent withContentHandler:contentHandler];
    [self.downloadTask resume];
}

- (void)serviceExtensionTimeWillExpire
{
    [self.downloadTask cancel];
    self.contentHandler(self.notificationContent);
}

#pragma mark UNNotificationAttachment for image

- (NSURLSessionDownloadTask *)imageDownloadTaskForNotification:(UserNotification *)notification
                                                       content:(UNNotificationContent *)content
                                            withContentHandler:(void (^)(UNNotificationContent * _Nonnull))contentHandler
{
    NSParameterAssert(contentHandler);
    
    NSURL *scaledImageURL = [self.dataProvider URLForImage:notification.image withSize:SRGImageSizeMedium];
    if (! scaledImageURL) {
        contentHandler(content);
        return nil;
    }
    
    return [[NSURLSession sharedSession] downloadTaskWithURL:scaledImageURL completionHandler:^(NSURL *temporaryFileURL, NSURLResponse *response, NSError *error) {
        if (error) {
            contentHandler(content);
            return;
        }
        
        NSString *MIMEType = response.MIMEType;
        if (! MIMEType) {
            contentHandler(content);
            return;
        }
        
        NSString *UTI = NotificationServiceUTIFromMIMEType(MIMEType);
        if (! UTI) {
            contentHandler(content);
            return;
        }
        
        NSDictionary *options = @{ UNNotificationAttachmentOptionsTypeHintKey : UTI };
        UNNotificationAttachment *attachment = [UNNotificationAttachment attachmentWithIdentifier:@"" URL:temporaryFileURL options:options error:NULL];
        if (! attachment) {
            contentHandler(content);
            return;
        }
        
        UNMutableNotificationContent *mutableContent = content.mutableCopy;
        mutableContent.attachments = @[attachment];
        contentHandler(mutableContent.copy);
    }];
}

@end
