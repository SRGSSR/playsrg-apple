//
//  Copyright (c) SRG SSR. All rights reserved.
//
//  License information is available from the LICENSE file.
//

#import "AnalyticsConstants.h"

// See reference specifications at https://confluence.srg.beecollaboration.com/display/SRGPLAY/Play+SRG+simplified+page+view+analytics

AnalyticsPageLevel const AnalyticsPageLevelApplication = @"application";
AnalyticsPageLevel const AnalyticsPageLevelAudio = @"audio";
AnalyticsPageLevel const AnalyticsPageLevelAutomobile = @"automobile";
AnalyticsPageLevel const AnalyticsPageLevelEpisode = @"episode";
AnalyticsPageLevel const AnalyticsPageLevelFeature = @"feature";
AnalyticsPageLevel const AnalyticsPageLevelGoogleCast = @"google cast";
AnalyticsPageLevel const AnalyticsPageLevelLive = @"live";
AnalyticsPageLevel const AnalyticsPageLevelMostPopular = @"most popular";
AnalyticsPageLevel const AnalyticsPageLevelPlay = @"play";
AnalyticsPageLevel const AnalyticsPageLevelPreview = @"preview";
AnalyticsPageLevel const AnalyticsPageLevelScheduledLivestream = @"scheduled livestream";
AnalyticsPageLevel const AnalyticsPageLevelSearch = @"search";
AnalyticsPageLevel const AnalyticsPageLevelSection = @"section";
AnalyticsPageLevel const AnalyticsPageLevelShow = @"show";
AnalyticsPageLevel const AnalyticsPageLevelSignLanguage = @"sign language";
AnalyticsPageLevel const AnalyticsPageLevelTopic = @"topic";
AnalyticsPageLevel const AnalyticsPageLevelUser = @"user";
AnalyticsPageLevel const AnalyticsPageLevelVideo = @"video";

AnalyticsPageTitle const AnalyticsPageTitleDevices = @"devices";
AnalyticsPageTitle const AnalyticsPageTitleDownloads = @"downloads";
AnalyticsPageTitle const AnalyticsPageTitleFavorites = @"favorites";
AnalyticsPageTitle const AnalyticsPageTitleFeatures = @"features";
AnalyticsPageTitle const AnalyticsPageTitleHistory = @"history";
AnalyticsPageTitle const AnalyticsPageTitleHome = @"home";
AnalyticsPageTitle const AnalyticsPageTitleLatest = @"latest";
AnalyticsPageTitle const AnalyticsPageTitleLatestEpisodes = @"latest episodes";
AnalyticsPageTitle const AnalyticsPageTitleLatestEpisodesFromFavorites = @"latest episodes from favorites";
AnalyticsPageTitle const AnalyticsPageTitleLicense = @"license";
AnalyticsPageTitle const AnalyticsPageTitleLicenses = @"licenses";
AnalyticsPageTitle const AnalyticsPageTitleLivePrograms = @"live programs";
AnalyticsPageTitle const AnalyticsPageTitleLogin = @"login";
AnalyticsPageTitle const AnalyticsPageTitleMedia = @"media";
AnalyticsPageTitle const AnalyticsPageTitleMostPopular = @"most popular";
AnalyticsPageTitle const AnalyticsPageTitleNotifications = @"notifications";
AnalyticsPageTitle const AnalyticsPageTitlePlayer = @"player";
AnalyticsPageTitle const AnalyticsPageTitleProgramGuide = @"program guide";
AnalyticsPageTitle const AnalyticsPageTitleRadio = @"radio";
AnalyticsPageTitle const AnalyticsPageTitleRadioSatellite = @"satellite radio";
AnalyticsPageTitle const AnalyticsPageTitleResumePlayback = @"resume playback";
AnalyticsPageTitle const AnalyticsPageTitleScheduledLivestreams = @"scheduled livestreams";
AnalyticsPageTitle const AnalyticsPageTitleSettings = @"settings";
AnalyticsPageTitle const AnalyticsPageTitleShowsAZ = @"shows a-z";
AnalyticsPageTitle const AnalyticsPageTitleShowsCalendar = @"shows calendar";
AnalyticsPageTitle const AnalyticsPageTitleSports = @"sports";
AnalyticsPageTitle const AnalyticsPageTitleTopics = @"topics";
AnalyticsPageTitle const AnalyticsPageTitleTV = @"tv";
AnalyticsPageTitle const AnalyticsPageTitleWatchLater = @"watch later";
AnalyticsPageTitle const AnalyticsPageTitleWhatsNew = @"what is new";

AnalyticsTitle const AnalyticsTitleGoogleCast = @"google_cast";
AnalyticsTitle const AnalyticsTitleIdentity = @"identity";
AnalyticsTitle const AnalyticsTitleNotificationOpen = @"notification_open";
AnalyticsTitle const AnalyticsTitleNotificationPushOpen = @"push_notification_open";
AnalyticsTitle const AnalyticsTitleOpenURL = @"open_url";
AnalyticsTitle const AnalyticsTitlePictureInPicture = @"picture_in_picture";
AnalyticsTitle const AnalyticsTitleSharingMedia = @"media_share";
AnalyticsTitle const AnalyticsTitleSharingShow = @"show_share";
AnalyticsTitle const AnalyticsTitleSharingSection = @"section_share";

AnalyticsSource const AnalyticsSourceAutomatic = @"automatic";
AnalyticsSource const AnalyticsSourceButton = @"button";
AnalyticsSource const AnalyticsSourceClose = @"close";
AnalyticsSource const AnalyticsSourceContextMenu = @"context_menu";
AnalyticsSource const AnalyticsSourceCustomURL = @"scheme_url";
AnalyticsSource const AnalyticsSourceNotification = @"notification";
AnalyticsSource const AnalyticsSourceNotificationPush = @"push_notification";
AnalyticsSource const AnalyticsSourceSelection = @"selection";
AnalyticsSource const AnalyticsSourceSwipe = @"swipe";
AnalyticsSource const AnalyticsSourceUniversalLink = @"deep_link";

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

AnalyticsValue const AnalyticsValueSharingContent = @"content";
AnalyticsValue const AnalyticsValueSharingContentAtTime = @"content_at_time";
AnalyticsValue const AnalyticsValueSharingCurrentClip = @"current_clip";
