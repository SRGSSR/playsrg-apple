//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "HomeSection.h"

NS_ASSUME_NONNULL_BEGIN

/**
 *  @name Analytics standard page levels
 */
typedef NSString * AnalyticsPageLevel NS_STRING_ENUM;

OBJC_EXPORT AnalyticsPageLevel const AnalyticsPageLevelApplication;
OBJC_EXPORT AnalyticsPageLevel const AnalyticsPageLevelAudio;
OBJC_EXPORT AnalyticsPageLevel const AnalyticsPageLevelAutomobile;
OBJC_EXPORT AnalyticsPageLevel const AnalyticsPageLevelEpisode;
OBJC_EXPORT AnalyticsPageLevel const AnalyticsPageLevelFeature;
OBJC_EXPORT AnalyticsPageLevel const AnalyticsPageLevelGoogleCast;
OBJC_EXPORT AnalyticsPageLevel const AnalyticsPageLevelLive;
OBJC_EXPORT AnalyticsPageLevel const AnalyticsPageLevelMostPopular;
OBJC_EXPORT AnalyticsPageLevel const AnalyticsPageLevelPlay;
OBJC_EXPORT AnalyticsPageLevel const AnalyticsPageLevelPreview;
OBJC_EXPORT AnalyticsPageLevel const AnalyticsPageLevelScheduledLivestream;
OBJC_EXPORT AnalyticsPageLevel const AnalyticsPageLevelSearch;
OBJC_EXPORT AnalyticsPageLevel const AnalyticsPageLevelSection;
OBJC_EXPORT AnalyticsPageLevel const AnalyticsPageLevelShow;
OBJC_EXPORT AnalyticsPageLevel const AnalyticsPageLevelTopic;
OBJC_EXPORT AnalyticsPageLevel const AnalyticsPageLevelUser;
OBJC_EXPORT AnalyticsPageLevel const AnalyticsPageLevelVideo;

/**
 *  @name Analytics standard page titles
 */
typedef NSString * AnalyticsPageTitle NS_STRING_ENUM;

OBJC_EXPORT AnalyticsPageTitle const AnalyticsPageTitleDevices;
OBJC_EXPORT AnalyticsPageTitle const AnalyticsPageTitleDownloads;
OBJC_EXPORT AnalyticsPageTitle const AnalyticsPageTitleFavorites;
OBJC_EXPORT AnalyticsPageTitle const AnalyticsPageTitleFeatures;
OBJC_EXPORT AnalyticsPageTitle const AnalyticsPageTitleHistory;
OBJC_EXPORT AnalyticsPageTitle const AnalyticsPageTitleHome;
OBJC_EXPORT AnalyticsPageTitle const AnalyticsPageTitleLatest;
OBJC_EXPORT AnalyticsPageTitle const AnalyticsPageTitleLatestEpisodes;
OBJC_EXPORT AnalyticsPageTitle const AnalyticsPageTitleLatestEpisodesFromFavorites;
OBJC_EXPORT AnalyticsPageTitle const AnalyticsPageTitleLicense;
OBJC_EXPORT AnalyticsPageTitle const AnalyticsPageTitleLicenses;
OBJC_EXPORT AnalyticsPageTitle const AnalyticsPageTitleLivePrograms;
OBJC_EXPORT AnalyticsPageTitle const AnalyticsPageTitleLogin;
OBJC_EXPORT AnalyticsPageTitle const AnalyticsPageTitleMedia;
OBJC_EXPORT AnalyticsPageTitle const AnalyticsPageTitleMostPopular;
OBJC_EXPORT AnalyticsPageTitle const AnalyticsPageTitleNotifications;
OBJC_EXPORT AnalyticsPageTitle const AnalyticsPageTitlePlayer;
OBJC_EXPORT AnalyticsPageTitle const AnalyticsPageTitleProgramGuide;
OBJC_EXPORT AnalyticsPageTitle const AnalyticsPageTitleRadio;
OBJC_EXPORT AnalyticsPageTitle const AnalyticsPageTitleRadioSatellite;
OBJC_EXPORT AnalyticsPageTitle const AnalyticsPageTitleResumePlayback;
OBJC_EXPORT AnalyticsPageTitle const AnalyticsPageTitleScheduledLivestreams;
OBJC_EXPORT AnalyticsPageTitle const AnalyticsPageTitleSettings;
OBJC_EXPORT AnalyticsPageTitle const AnalyticsPageTitleShowsAZ;
OBJC_EXPORT AnalyticsPageTitle const AnalyticsPageTitleShowsCalendar;
OBJC_EXPORT AnalyticsPageTitle const AnalyticsPageTitleSports;
OBJC_EXPORT AnalyticsPageTitle const AnalyticsPageTitleTopics;
OBJC_EXPORT AnalyticsPageTitle const AnalyticsPageTitleTV;
OBJC_EXPORT AnalyticsPageTitle const AnalyticsPageTitleWatchLater;
OBJC_EXPORT AnalyticsPageTitle const AnalyticsPageTitleWhatsNew;

/**
 *  @name Analytics event titles
 */
typedef NSString * AnalyticsTitle NS_STRING_ENUM;

/**
 *  Title for events related to addition of a calendar event
 */
OBJC_EXPORT AnalyticsTitle const AnalyticsTitleCalendarAdd;

/**
 *  Title for events related to continuous playback
 */
OBJC_EXPORT AnalyticsTitle const AnalyticsTitleContinuousPlayback;

/**
 *  Title for events related to addition of a new download
 */
OBJC_EXPORT AnalyticsTitle const AnalyticsTitleDownloadAdd;

/**
 *  Title for events related to deletion of a download
 */
OBJC_EXPORT AnalyticsTitle const AnalyticsTitleDownloadRemove;

/**
 *  Title for Google Cast events
 */
OBJC_EXPORT AnalyticsTitle const AnalyticsTitleGoogleCast;

/**
 *  Title for events related to deletion of an history entry
 */
OBJC_EXPORT AnalyticsTitle const AnalyticsTitleHistoryRemove;

/**
 *  Title for events related to identity login / logout
 */
OBJC_EXPORT AnalyticsTitle const AnalyticsTitleIdentity;

/**
 *  Title for events related to opening a notification
 */
OBJC_EXPORT AnalyticsTitle const AnalyticsTitleNotificationOpen;

/**
 *  Title for events related to opening a push notification
 */
OBJC_EXPORT AnalyticsTitle const AnalyticsTitleNotificationPushOpen;

/**
 *  Title for events related to opening an URL
 */
OBJC_EXPORT AnalyticsTitle const AnalyticsTitleOpenURL;

/**
 *  Title for picture-in-picture playback events
 */
OBJC_EXPORT AnalyticsTitle const AnalyticsTitlePictureInPicture;

/**
 *  Title for events related to 3D touch quick actions
 */
OBJC_EXPORT AnalyticsTitle const AnalyticsTitleQuickActions;

/**
 *  Title for sharing-related events
 */
OBJC_EXPORT AnalyticsTitle const AnalyticsTitleSharingMedia;
OBJC_EXPORT AnalyticsTitle const AnalyticsTitleSharingShow;
OBJC_EXPORT AnalyticsTitle const AnalyticsTitleSharingSection;

/**
 *  Title for events related to subscriptions
 */
OBJC_EXPORT AnalyticsTitle const AnalyticsTitleSubscriptionAdd;

/**
 *  Title for events related to deletion of a subscription
 */
OBJC_EXPORT AnalyticsTitle const AnalyticsTitleSubscriptionRemove;

/**
 *  Title for events related to subscriptions
 */
OBJC_EXPORT AnalyticsTitle const AnalyticsTitleFavoriteAdd;

/**
 *  Title for events related to deletion of a favorite
 */
OBJC_EXPORT AnalyticsTitle const AnalyticsTitleFavoriteRemove;

/**
 *  Title for events related to opening a user activity
 */
OBJC_EXPORT AnalyticsTitle const AnalyticsTitleUserActivity;

/**
 *  Title for events related to later list
 */
OBJC_EXPORT AnalyticsTitle const AnalyticsTitleWatchLaterAdd;

/**
 *  Title for events related to deletion of a later list entry
 */
OBJC_EXPORT AnalyticsTitle const AnalyticsTitleWatchLaterRemove;

/**
 *  @name Analytics values
 */
typedef NSString * AnalyticsSource NS_STRING_ENUM;
typedef NSString * AnalyticsType NS_STRING_ENUM;
typedef NSString * AnalyticsValue NS_STRING_ENUM;

/**
 *  Sources
 */
OBJC_EXPORT AnalyticsSource const AnalyticsSourceAutomatic;
OBJC_EXPORT AnalyticsSource const AnalyticsSourceButton;
OBJC_EXPORT AnalyticsSource const AnalyticsSourceClose;
OBJC_EXPORT AnalyticsSource const AnalyticsSourceContextMenu;
OBJC_EXPORT AnalyticsSource const AnalyticsSourceCustomURL;
OBJC_EXPORT AnalyticsSource const AnalyticsSourceHandoff;
OBJC_EXPORT AnalyticsSource const AnalyticsSourceNotification NS_SWIFT_NAME(AnalyticsSource.notification);
OBJC_EXPORT AnalyticsSource const AnalyticsSourceNotificationPush;
OBJC_EXPORT AnalyticsSource const AnalyticsSourceSelection;
OBJC_EXPORT AnalyticsSource const AnalyticsSourceSwipe;
OBJC_EXPORT AnalyticsSource const AnalyticsSourceUniversalLink;

/**
 *  Actions
 */
OBJC_EXPORT AnalyticsType const AnalyticsTypeActionLive;
OBJC_EXPORT AnalyticsType const AnalyticsTypeActionFavorites;
OBJC_EXPORT AnalyticsType const AnalyticsTypeActionDownloads;
OBJC_EXPORT AnalyticsType const AnalyticsTypeActionHistory;
OBJC_EXPORT AnalyticsType const AnalyticsTypeActionSearch;
OBJC_EXPORT AnalyticsType const AnalyticsTypeActionPlayMedia;
OBJC_EXPORT AnalyticsType const AnalyticsTypeActionDisplay;
OBJC_EXPORT AnalyticsType const AnalyticsTypeActionDisplayShow;
OBJC_EXPORT AnalyticsType const AnalyticsTypeActionDisplayPage;
OBJC_EXPORT AnalyticsType const AnalyticsTypeActionDisplayURL;
OBJC_EXPORT AnalyticsType const AnalyticsTypeActionCancel;
OBJC_EXPORT AnalyticsType const AnalyticsTypeActionNotificationAlert;
OBJC_EXPORT AnalyticsType const AnalyticsTypeActionDisplayLogin;
OBJC_EXPORT AnalyticsType const AnalyticsTypeActionCancelLogin;
OBJC_EXPORT AnalyticsType const AnalyticsTypeActionLogin;
OBJC_EXPORT AnalyticsType const AnalyticsTypeActionLogout;
OBJC_EXPORT AnalyticsType const AnalyticsTypeActionOpenPlayApp;

/**
 *  Values
 */
OBJC_EXPORT AnalyticsValue const AnalyticsValueSharingContent;
OBJC_EXPORT AnalyticsValue const AnalyticsValueSharingContentAtTime;
OBJC_EXPORT AnalyticsValue const AnalyticsValueSharingCurrentClip;

NS_ASSUME_NONNULL_END
