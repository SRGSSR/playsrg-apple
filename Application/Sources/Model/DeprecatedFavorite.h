//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import Foundation;
@import SRGDataProviderModel;

NS_ASSUME_NONNULL_BEGIN

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
 *  Deprecated favorites (previously stored in plists). Kept for migration purposes only.
 */
@interface DeprecatedFavorite : NSObject <SRGImageMetadata>

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

@end

@interface DeprecatedFavorite (WatchLaterMigration)

/**
 *  Available media favorites, sorted by date at which they were favorited (from the oldest to the most recent)
 */
@property (class, nonatomic, readonly) NSArray<DeprecatedFavorite *> *mediaFavorites;

/**
 *  Available show favorites, sorted by date at which they were favorited (from the oldest to the most recent)
 */
@property (class, nonatomic, readonly) NSArray<DeprecatedFavorite *> *showFavorites;

/**
 *  Remove "old" favorites files (without notifying changes)
 */
+ (void)finishMigrationForFavorites:(NSArray<DeprecatedFavorite *> *)favorites;

@end

NS_ASSUME_NONNULL_END
