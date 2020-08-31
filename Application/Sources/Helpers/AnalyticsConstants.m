//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "AnalyticsConstants.h"
#import "NSBundle+PlaySRG.h"

// See reference specifications at https://confluence.srg.beecollaboration.com/display/SRGPLAY/Play+SRG+simplified+page+view+analytics

AnalyticsPageLevel const AnalyticsPageLevelApplication = @"application";
AnalyticsPageLevel const AnalyticsPageLevelAudio = @"audio";
AnalyticsPageLevel const AnalyticsPageLevelEvent = @"event";
AnalyticsPageLevel const AnalyticsPageLevelFeature = @"feature";
AnalyticsPageLevel const AnalyticsPageLevelGoogleCast = @"google cast";
AnalyticsPageLevel const AnalyticsPageLevelLive = @"live";
AnalyticsPageLevel const AnalyticsPageLevelPlay = @"play";
AnalyticsPageLevel const AnalyticsPageLevelPreview = @"preview";
AnalyticsPageLevel const AnalyticsPageLevelSearch = @"search";
AnalyticsPageLevel const AnalyticsPageLevelShow = @"show";
AnalyticsPageLevel const AnalyticsPageLevelUser = @"user";
AnalyticsPageLevel const AnalyticsPageLevelVideo = @"video";

AnalyticsPageTitle const AnalyticsPageTitleBetaTesting = @"beta testing";
AnalyticsPageTitle const AnalyticsPageTitleBetaTvTesting = @"beta TV testing";
AnalyticsPageTitle const AnalyticsPageTitleDevices = @"devices";
AnalyticsPageTitle const AnalyticsPageTitleDownloads = @"downloads";
AnalyticsPageTitle const AnalyticsPageTitleEvents = @"events";
AnalyticsPageTitle const AnalyticsPageTitleFavorites = @"favorites";
AnalyticsPageTitle const AnalyticsPageTitleFeatures = @"features";
AnalyticsPageTitle const AnalyticsPageTitleFeedback = @"feedback";
AnalyticsPageTitle const AnalyticsPageTitleHistory = @"history";
AnalyticsPageTitle const AnalyticsPageTitleHome = @"home";
AnalyticsPageTitle const AnalyticsPageTitleLatest = @"latest";
AnalyticsPageTitle const AnalyticsPageTitleLatestEpisodes = @"latest episodes";
AnalyticsPageTitle const AnalyticsPageTitleLicense = @"license";
AnalyticsPageTitle const AnalyticsPageTitleLicenses = @"licenses";
AnalyticsPageTitle const AnalyticsPageTitleMostPopular = @"most popular";
AnalyticsPageTitle const AnalyticsPageTitleNotifications = @"notifications";
AnalyticsPageTitle const AnalyticsPageTitlePlayer = @"player";
AnalyticsPageTitle const AnalyticsPageTitleRadio = @"radio";
AnalyticsPageTitle const AnalyticsPageTitleRadioSatellite = @"satellite radio";
AnalyticsPageTitle const AnalyticsPageTitleSettings = @"settings";
AnalyticsPageTitle const AnalyticsPageTitleShowsAZ = @"shows a-z";
AnalyticsPageTitle const AnalyticsPageTitleShowsCalendar = @"shows calendar";
AnalyticsPageTitle const AnalyticsPageTitleSoonExpiring = @"soon expiring";
AnalyticsPageTitle const AnalyticsPageTitleSourceCode = @"source code";
AnalyticsPageTitle const AnalyticsPageTitleSports = @"sports";
AnalyticsPageTitle const AnalyticsPageTitleTrending = @"trending";
AnalyticsPageTitle const AnalyticsPageTitleTV = @"tv";
AnalyticsPageTitle const AnalyticsPageTitleWatchLater = @"watch later";
AnalyticsPageTitle const AnalyticsPageTitleWhatsNew = @"what is new";

AnalyticsTitle const AnalyticsTitleContinuousPlayback = @"continuous_playback";
AnalyticsTitle const AnalyticsTitleDownloadAdd = @"download_add";
AnalyticsTitle const AnalyticsTitleDownloadRemove = @"download_remove";
AnalyticsTitle const AnalyticsTitleDownloadRemoveAll = @"download_remove_all";
AnalyticsTitle const AnalyticsTitleDownloadOpenMedia = @"download_open";
AnalyticsTitle const AnalyticsTitleGoogleCast = @"google_cast";
AnalyticsTitle const AnalyticsTitleHistoryRemove = @"history_remove";
AnalyticsTitle const AnalyticsTitleHistoryRemoveAll = @"history_remove_all";
AnalyticsTitle const AnalyticsTitleHistoryOpenMedia = @"history_open";
AnalyticsTitle const AnalyticsTitleIdentity = @"identity";
AnalyticsTitle const AnalyticsTitleNotificationOpen = @"notification_open";
AnalyticsTitle const AnalyticsTitleNotificationPushOpen = @"push_notification_open";
AnalyticsTitle const AnalyticsTitleOpenURL = @"open_url";
AnalyticsTitle const AnalyticsTitlePictureInPicture = @"picture_in_picture";
AnalyticsTitle const AnalyticsTitleQuickActions = @"quick_actions";
AnalyticsTitle const AnalyticsTitleSharingMedia = @"media_share";
AnalyticsTitle const AnalyticsTitleSharingModule = @"module_share";
AnalyticsTitle const AnalyticsTitleSharingShow = @"show_share";
AnalyticsTitle const AnalyticsTitleSubscriptionAdd = @"subscription_add";
AnalyticsTitle const AnalyticsTitleSubscriptionRemove = @"subscription_remove";
AnalyticsTitle const AnalyticsTitleFavoriteAdd = @"favorite_add";
AnalyticsTitle const AnalyticsTitleFavoriteRemove = @"favorite_remove";
AnalyticsTitle const AnalyticsTitleFavoriteRemoveAll = @"favorite_remove_all";
AnalyticsTitle const AnalyticsTitleFavoriteOpen = @"favorite_open";
AnalyticsTitle const AnalyticsTitleSearchOpen = @"search_open";
AnalyticsTitle const AnalyticsTitleSearchTeaserOpen = @"search_teaser_open";
AnalyticsTitle const AnalyticsTitleUserActivity = @"user_activity_ios";
AnalyticsTitle const AnalyticsTitleWatchLaterAdd = @"watch_later_add";
AnalyticsTitle const AnalyticsTitleWatchLaterRemove = @"watch_later_remove";
AnalyticsTitle const AnalyticsTitleWatchLaterRemoveAll = @"watch_later_remove_all";
AnalyticsTitle const AnalyticsTitleWatchLaterOpenMedia = @"watch_later_open";

AnalyticsSource const AnalyticsSourceAutomatic = @"automatic";
AnalyticsSource const AnalyticsSourceButton = @"button";
AnalyticsSource const AnalyticsSourceClose = @"close";
AnalyticsSource const AnalyticsSourceDeepLink = @"deep_link";
AnalyticsSource const AnalyticsSourceHandoff = @"handoff";
AnalyticsSource const AnalyticsSourceLongPress = @"long_click";
AnalyticsSource const AnalyticsSourceNotification = @"notification";
AnalyticsSource const AnalyticsSourceNotificationPush = @"push_notification";
AnalyticsSource const AnalyticsSourcePeekMenu = @"peek_menu";
AnalyticsSource const AnalyticsSourceSchemeURL = @"scheme_url";
AnalyticsSource const AnalyticsSourceSelection = @"selection";
AnalyticsSource const AnalyticsSourceSwipe = @"swipe";

AnalyticsType const AnalyticsTypeActionLive = @"openlive";
AnalyticsType const AnalyticsTypeActionFavorites = @"openfavorites";
AnalyticsType const AnalyticsTypeActionDownloads = @"opendownloads";
AnalyticsType const AnalyticsTypeActionHistory = @"openhistory";
AnalyticsType const AnalyticsTypeActionSearch = @"opensearch";
AnalyticsType const AnalyticsTypeActionPlayMedia = @"play_media";
AnalyticsType const AnalyticsTypeActionDisplay = @"display";
AnalyticsType const AnalyticsTypeActionDisplayShow = @"display_show";
AnalyticsType const AnalyticsTypeActionDisplayPage = @"display_page";
AnalyticsType const AnalyticsTypeActionDisplayURL = @"display_url";
AnalyticsType const AnalyticsTypeActionCancel = @"cancel";
AnalyticsType const AnalyticsTypeActionNotificationAlert = @"notification_alert";
AnalyticsType const AnalyticsTypeActionDisplayLogin = @"display_login";
AnalyticsType const AnalyticsTypeActionCancelLogin = @"cancel_login";
AnalyticsType const AnalyticsTypeActionLogin = @"login";
AnalyticsType const AnalyticsTypeActionLogout = @"logout";
AnalyticsType const AnalyticsTypeActionOpenPlayApp = @"open_play_app";

AnalyticsValue const AnalyticsTypeValueSharingContent = @"content";
AnalyticsValue const AnalyticsTypeValueSharingContentAtTime = @"content_at_time";
AnalyticsValue const AnalyticsTypeValueSharingCurrentClip = @"current_clip";
