//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import <Foundation/Foundation.h>
#import <SRGDataProvider/SRGDataProvider.h>

NS_ASSUME_NONNULL_BEGIN

/**
 *  Notification sent when a favorite state changes (added or removed). Use associated keys to retrieve information
 *  about the change.
 */
OBJC_EXPORT NSString * const FavoriteStateDidChangeNotification;                            // Notification name
OBJC_EXPORT NSString * const FavoriteObjectKey;                                             // Object which has been favorited
OBJC_EXPORT NSString * const FavoriteStateKey;                                              // Key to access the current favorite state as a `BOOL` (wrapped as an `NSNumber`)

/**
 *  The default width used to store the backup image file
 */
OBJC_EXPORT CGFloat const FavoriteBackupImageWidth;

/**
 *  Favorite types
 */
typedef NS_ENUM(NSInteger, FavoriteType) {
    /**
     *  Not specified
     */
    FavoriteTypeUnspecified = 0,
    /**
     *  Media
     */
    FavoriteTypeMedia,
    /**
     *  Show
     */
    FavoriteTypeShow
};

/**
 *  Favorite media types
 */
typedef NS_ENUM(NSInteger, FavoriteMediaType) {
    /**
     *  Not specified
     */
    FavoriteMediaTypeUnknown = 0,
    /**
     *  Video
     */
    FavoriteMediaTypeVideo,
    /**
     *  Audio
     */
    FavoriteMediaTypeAudio
};

/**
 *  Favorite content types
 */
typedef NS_ENUM(NSInteger, FavoriteMediaContentType) {
    /**
     *  Not specified
     */
    FavoriteMediaContentTypeUnknown = 0,
    /**
     *  On demand
     */
    FavoriteMediaContentTypeOnDemand,
    /**
     *  Live
     */
    FavoriteMediaContentTypeLive,
    /**
     *  scheduled live
     */
    FavoriteMediaContentTypeScheduledLive
};

/**
 *  Favorite show transmission
 */
typedef NS_ENUM(NSInteger, FavoriteShowTransmission) {
    /**
     *  Not specified
     */
    FavoriteShowTransmissionUnknown = 0,
    /**
     *  TV
     */
    FavoriteShowTransmissionTV,
    /**
     *  Radio
     */
    FavoriteShowTransmissionRadio,
    /**
     *  Online
     */
    FavoriteShowTransmissionOnline
};

/**
 *  A `Favorite` collects all information associated with a favorite, and provides the interface to manage them
 */
@interface Favorite : NSObject <SRGImageMetadata>

/**
 *  @name Common properties
 */

/**
 *  The date at which the favorite was created
 */
@property (nonatomic, readonly) NSDate *creationDate;

/**
 *  The type of the favorited object
 */
@property (nonatomic, readonly) FavoriteType type;

/**
 *  The identifier of the favorited object
 */
@property (nonatomic, readonly, copy) NSString *uid;

/**
 *  The favorite title
 */
@property (nonatomic, readonly, copy) NSString *title;

/**
 *  @name Media properties
 */

/**
 *  The media type of the favorited object
 */
@property (nonatomic, readonly) FavoriteMediaType mediaType;

/**
 *  The media URN of the favorited object, if any
 */
@property (nonatomic, readonly, copy, nullable) NSString *mediaURN;

/**
 *  The media content type of the favorited object
 */
@property (nonatomic, readonly) FavoriteMediaContentType mediaContentType;

/**
 *  The date associated with the favorited object, if any
 */
@property (nonatomic, readonly, nullable) NSDate *date;

/**
 *  The duration associated with the favorited object (0 if not meaningful)
 */
@property (nonatomic, readonly) NSTimeInterval duration;

/**
 *  The recommended way to present the media.
 */
@property (nonatomic, readonly) SRGPresentation presentation;

/**
 *  The show title
 */
@property (nonatomic, readonly, copy, nullable) NSString *showTitle;

/**
 *  The start date at which the favorite should be made available, if any
 */
@property (nonatomic, readonly, nullable) NSDate *startDate;

/**
 *  The end date at which the content should not be made available anymore, if any
 */
@property (nonatomic, readonly, nullable) NSDate *endDate;

/**
 *  The youth protection color.
 */
@property (nonatomic, readonly) SRGYouthProtectionColor youthProtectionColor;

/**
 *  Return the blocking reason associated with the media (if any), calculated at the specified date. The media
 *  should be playable client-side iff the reason is `SRGBlockingReasonNone`.
 *
 *  Discussion: The original blocking reason value is not saved. If no cached object, it's only based on startDate and endDate values.
 */
- (SRGBlockingReason)blockingReasonAtDate:(NSDate *)date;

/**
 *  Return the time availability associated with the media at the specified date.
 *
 *  @discussion Time availability is only intended for informative purposes. To decide whether a media should be playable
 *              client-side, use `-blockingReasonAtDate:`.
 */
- (SRGTimeAvailability)timeAvailabilityAtDate:(NSDate *)date;

/**
 *  @name Show properties
 */

/**
 *  The show URN of the favorited object, if any
 */
@property (nonatomic, readonly, copy, nullable) NSString *showURN;

/**
 *  The show transmission of the favorited object, if known
 */
@property (nonatomic, readonly) FavoriteShowTransmission showTransmission;

/**
 *  @name Common methods
 */

/**
 *  Fetch the favorited object and return it in the completion block.
 *
 *  @param type      If set to a concrete favorite type (i.e. different from `FavoriteTypeUnspecified`), the method only
 *                   attempts to retrieve the object if the receiver has a matching type. If a concrete type is provided
 *                   and no match is found, or if an error occurs while fetching the data (network, format), an error will
 *                   be returned to the completion block.
 *  @param available Parameter to optionally return (byref) if an object is readily available or not.
 *
 *  @return SRGRequest If not `nil`, an already resumed request fetching the object, and which can be used for cancellation
 *                     purposes.
 *
 *  @discussion The completion block will be called synchronously if the object is readily available and asynchronously
 *              if it is not available and must be retrieved first.
 */
- (nullable SRGRequest *)objectForType:(FavoriteType)type available:(nullable BOOL *)pAvailable withCompletionBlock:(void (^)(id _Nullable favoritedObject, NSError * _Nullable error))completionBlock;

@end

@interface Favorite (Management)

/**
 *  Available favorites, sorted by date at which they were favorited (from the most recent to the oldest)
 */
@property (class, nonatomic, readonly) NSArray<Favorite *> *favorites;

/**
 *  Return the favorite object corresponding to the media, if any
 */
+ (nullable Favorite *)favoriteForMedia:(SRGMedia *)media;

/**
 *  Return the favorite object corresponding to the show, if any
 */
+ (nullable Favorite *)favoriteForShow:(SRGShow *)show;

/**
 *  Add a media favorite if it didn't exist, remove it otherwise
 */
+ (nullable Favorite *)toggleFavoriteForMedia:(SRGMedia *)media;

/**
 *  Add a show favorite if it didn't exist, remove it otherwise
 */
+ (nullable Favorite *)toggleFavoriteForShow:(SRGShow *)show;

/**
 *  Remove an existing favorite
 */
+ (void)removeFavorite:(Favorite *)favorite;

/**
 *  Remove all favorites
 */
+ (void)removeAllFavorites;

/**
 *  Perform migration.
 */
+ (void)migrate;

@end

NS_ASSUME_NONNULL_END
