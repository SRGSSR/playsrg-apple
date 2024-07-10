//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

@import UIKit;

NS_ASSUME_NONNULL_BEGIN

/**
 *  Songs view styles
 */
typedef NS_ENUM(NSInteger, SongsViewStyle) {
    /**
     *  Not displayed.
     */
    SongsViewStyleNone = 0,
    /**
     *  Collapsed when added to the view.
     */
    SongsViewStyleCollapsed,
    /**
     *  Expanded when added to the view.
     */
    SongsViewStyleExpanded
};

/**
 *  Show types for radios
 */
typedef NS_ENUM(NSInteger, ShowType) {
    /**
     *  Not displayed.
     */
    ShowTypeNone = 0,
    /**
     *  Usual audios shows
     */
    ShowTypeShow,
    /**
     *  Podcasts
     */
    ShowTypePodcast
};

@interface Channel : NSObject

/**
 *  Create the channel from a dictionary. Return `nil` if the dictionary format is incorrect.
 */
- (nullable instancetype)initWithDictionary:(NSDictionary *)dictionary NS_DESIGNATED_INITIALIZER;

/**
 *  The unique identifier of the channel.
 */
@property (nonatomic, readonly, copy) NSString *uid;

/**
 *  Local unique identifier for referencing resources in a common way.
 */
@property (nonatomic, readonly, copy) NSString *resourceUid;

/**
 *  The channel name.
 */
@property (nonatomic, readonly, copy) NSString *name;

/**
 * The URL used to share the channel website.
 */
@property (nonatomic, readonly, copy, nullable) NSURL *shareURL;

/**
 *  The channel primary color.
 */
@property (nonatomic, readonly) UIColor *color;

/**
 *  The channel second color.
 */
@property (nonatomic, readonly) UIColor *secondColor;

/**
 *  The channel title color.
 */
@property (nonatomic, readonly) UIColor *titleColor;

/**
 *  Return `YES` iff the status bar should be dark for this channel.
 */
@property (nonatomic, readonly, getter=hasDarkStatusBar) BOOL darkStatusBar;

/**
 *  The songs view style when added to the view.
 */
@property (nonatomic, readonly) SongsViewStyle songsViewStyle;

/**
 *  The type of show hosted by the channel.
 */
@property (nonatomic, readonly) ShowType showType;

/**
 *  The channel content page identifier.
 */
@property (nonatomic, readonly, copy, nullable) NSString *contentPageId;

@end

NS_ASSUME_NONNULL_END
