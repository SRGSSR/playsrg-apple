//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "Download.h"

@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@interface Download (Private)

/**
 *  Add a download object, without notification
 */
+ (BOOL)addDownload:(Download *)download;

/**
 *  Create a download from a dictionary of its fields
 */
- (nullable instancetype)initWithDictionary:(NSDictionary *)dictionary;

/**
 *  URLs downloaded
 */
@property (nonatomic, readonly, nullable) NSURL *downloadMediaURL;
@property (nonatomic, readonly, nullable) NSURL *downloadImageURL;

/**
 *  Save downloaded files
 */
- (BOOL)setLocalMediaFileWithTmpFile:(NSURL *)tmpFile MIMEType:(NSString *)MIMEType;
- (BOOL)setLocalImageFileWithTmpFile:(NSURL *)tmpFile MIMEType:(NSString *)MIMEType;

@end

NS_ASSUME_NONNULL_END
