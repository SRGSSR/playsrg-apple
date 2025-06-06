# Remote configuration

The proprietary project can be configured remotely using [Firebase](https://firebase.google.com/). All primitive parameters (strings, numbers, booleans, JSON) from the `ApplicationConfiguration.json` file can be overridden. 

Some parameters are mandatory and others are optional. All applications are provided with a default configuration, available even when the Firebase service could not be queried (e.g. if no network connection is initially available).

If a parameter is overridden in the Firebase console, its value will be used, otherwise the local value will be used instead. If you want to disable an optional parameter for which a local value is available, you must therefore define an override for it in the Firebase console, providing no value.

The remote configuration has a validity of 15 minutes (30 seconds when debugging and in nightly builds), and is applied when the application wakes up from the background.

If a remote configuration is found to be invalid (usually a mandatory parameter is missing), the application will ignore it and continue with the previous valid configuration.

## Application configuration

* `appStoreProductIdentifier` (mandatory, number): Application product identifier on the AppStore.
* `businessUnit` (mandatory, string): The identifier of the business unit.
* `pageSize` (optional, number): The page size to use for media or show lists in general, 20 if not set.
* `detailPageSize` (optional, number): The page size to use for media or show lists in detail page with load more capability, 40 if not set.
* `voiceOverLanguageCode` (optional, string): The code of the language associated with the application. If set, this language is used when reading texts for accessibility purposes, otherwise the device language is used.
* `userConsentDefaultLanguage` (optional , string): The default language for user consent. If omitted, the default language in user consent configuration is used. 

## URLs

* `betaTestingURL` (optional, string): The URL of the page where beta testers can register.
* `feedbackURL` (optional, string): The URL of the legacy feedback form (deprecated in iOS 3.9.4).
* `supportFormURL` (optional, string): The URL of the feedback form.
* `faqURL` (optional, string): The URL of the FAQs.
* `dataProtectionURL` (optional, string): The URL of the data protection information page.
* `impressumURL` (optional, string): The URL of the impressum page. If none is provided, the corresponding menu entry will not be displayed.
* `dataProviderProductionServiceURL (optional, string): The URL of the production DataProvider service. If omitted, the default Integration Layer production URL is used.
* `dataProviderStageServiceURL (optional, string): The URL of the stage/int DataProvider service. If omitted, the default Integration Layer stage URL is used.
* `dataProviderTestServiceURL (optional, string): The URL of the test/dev DataProvider service. If omitted, the default Integration Layer test URL is used.
* `identityWebserviceURL` (optional, string): The URL of the identity webservices.
* `identityWebsiteURL` (optional, string): The URL of the identity web portal.
* `userDataServiceURL` (optional, string): The URL of the service with which user data can be synchronized (history, preferences, playlists).
* `middlewareURL` (mandatory, string): The URL of the Play application middleware.
* `playURLs` (mandatory, JSON): A JSON dictionary describing all base URLs of the Play web portals, used when building sharing URLs. Key (string) is the identifier of the business unit, value (string) is the base URL of the Play web portal. The `businessUnit` property value MUST be in the keys.
* `playServiceURL` (mandatory, string): The base URL of the Play web service.
* `sourceCodeURL` (optional, string); The URL where the application source code can be found.
* `termsAndConditionsURL` (optional, string): The URL of the terms and conditions page.
* `whatsNewURL` (mandatory, string): The URL at which the update information can be retrieved.

## Email

* `supportEmailAddress` (optional, string): The email to send support information to. (deprecated in iOS 3.9.4)

## Analytics

* `sourceKey` (mandatory, string): The source identifier to send events to.
* `siteName` (mandatory, string): The iOS and iPadOS site name to send events to.
* `tvSiteName` (mandatory, string): The tvOS site name to send events to.

## Channel configuration

TV and radio channels are configured with corresponding JSON dictionaries:

* `tvChannels` (optional, JSON): A JSON array of JSON dictionaries describing TV channel configuration. Available common keys are listed below.
* `radioChannels` (optional, JSON): A JSON array of JSON dictionaries describing radio channel configuration. Available common keys are listed below, with the additional following specific keys:
    * `homeSections` (optional, string, multiple): The sections to be displayed on the channel homepage. Refer to _Audio homepage_ for available values. If omitted, the global `audioHomeSections` setting is used instead (in which case this value is required).
* `satelliteRadioChannels` (optional, JSON): A JSON array of JSON dictionaries describing Swiss satellite radio channel configuration. Available common keys are listed below.

The keys common to both TV and radio channels JSON dictionaries are:

* `uid` (mandatory, string): The unique identifier of the channel.
* `name` (mandatory, string): The channel name.
* `resourceUid` (mandatory, string): Local unique identifier for referencing resources related to the channel.
* `color` (optional, string): The channel primary hex color. Used as navigation bar background color. If omitted, gray.
* `secondColor` (optional, string): The channel second hex color. Currently used for gradients. If omitted, same as `color`.
* `titleColor` (optional, string): Hex color of the text displayed on top of colored areas (should provide sufficient contrast with `color` and `secondColor`). If omitted, white.
* `hasDarkStatusBar` (optional, boolean): `true` iff the status bar should be dark for this channel. If omitted, `false`.
* `songsViewStyle` (optional, string): The songs view style when added to the view. Never displayed if not set. Available values are:
   * `collapsed`: Collapsed when added to the view.
   * `expanded`: Expanded when added to the view.
* `showType` (optional, string): Whether the channel has content of type show or podcast. It will affect some section titles. If empty, the default value is `show`. Available values are:
   * `show`
   * `podcast`
* `shareURL` (optional, string): The URL used to share the channel website.
* `contentPageId` (optional, string) - BETA ONLY: The page identifier of the content page to use for the channel page. If omitted, the preconfigured page is used with the related sections for this channel.

The radio channel JSON dictionaries have one more key:

* `homepageHidden` (optional, boolean): Set to `true` iff a homepage does not have to be displayed for the radio channel. If omitted, `false`.

## Topics

* `topicColors` (optional, JSON): A JSON dictionary describing all topic colors. Key (string) is the topic `urn` (the topic unique identifier), value (a JSON dictionary) has two properties:
	* `firstColor` (mandatory, string): The first topic gradient primary hex color. Used in background in topic and show pages.
	* `secondColor` (mandatory, string): The second topic gradient primary hex color. Used in background in topic and show pages.
    * `reduceBrightness` (optional, boolean): Set to `true` if the brightness of the colors should be reduced for contrast purpose. If omitted, `false`.

## Shows

* `predefinedShowPagePreferred` (optional, boolean): Set to `true` iff show pages need to be displayed with the predefined layout (ie: only one predefined section with available episodes). If omitted, `false`.
* `showLeadPreferred` (optional, boolean): Set to `true` iff show pages and show elements should display lead instead of description. If omitted, `false`.

## Audio homepage

* `audioHomeSections` (optional, string, multiple): The sections to be displayed on the audio homepage of a radio channel, in the order they must appear.
* `audioContentHomepagePreferred` (optional, boolean): Set to `true` iff audio tab only needs one content homepage to be displayed and ignores radio channel homepages. If omitted, `false`.

### Home sections:

Feeds

* `radioAllShows`: All available shows. ([audio/alphabeticalByChannel](https://il.srgssr.ch/integrationlayer/2.0/_BU_/showList/radio/alphabeticalByChannel/_CHANNEL_ID_))
* `radioLatest`: The latest audios. ([audio/latestByChannel](https://il.srgssr.ch/integrationlayer/2.0/_BU_/mediaList/audio/latestByChannel/_CHANNEL_ID_))
* `radioLatestEpisodes`: The latest episodes. ([audio/latestEpisodesByChannel](https://il.srgssr.ch/integrationlayer/2.0/_BU_/mediaList/audio/latestEpisodesByChannel/_CHANNEL_ID_))
* `radioLatestVideos`: The latest videos. ([video/latestByChannel](https://il.srgssr.ch/integrationlayer/2.0/_BU_/mediaList/video/latestByChannel/_CHANNEL_ID_))
* `radioMostPopular`: The most popular audios. ([audio/mostClickedByChannel](https://il.srgssr.ch/integrationlayer/2.0/_BU_/mediaList/audio/mostClickedByChannel/_CHANNEL_ID_))
* `radioShowsAccess`: A-Z and By Date access buttons. ([audio/alphabeticalByChannel](https://il.srgssr.ch/integrationlayer/2.0/_BU_/showList/radio/alphabeticalByChannel/_CHANNEL_ID_) + [audio/episodesByDateAndChannel](https://il.srgssr.ch/integrationlayer/2.0/_BU_/mediaList/audio/episodesByDateAndChannel/_CHANNEL_ID_/_DAY_DATE_))

User data

* `radioFavoriteShows`: Radio shows added to the favorites. (*Local* + [showList/byUrns](https://il.srgssr.ch/integrationlayer/2.0/showList/byUrns?urns=))
* `radioLatestFromFavorites`: The latest audios from the user favorite shows. (*Local* + [mediaList/byUrns](https://il.srgssr.ch/integrationlayer/2.0/mediaList/byUrns?urns=))
* `radioResumePlayback`: Audios for which playback can be resumed. (*Local* + [mediaList/byUrns](https://il.srgssr.ch/integrationlayer/2.0/mediaList/byUrns?urns=))
* `radioWatchLater`: Audios added to the Later list. (*Local* + [mediaList/byUrns](https://il.srgssr.ch/integrationlayer/2.0/mediaList/byUrns?urns=))

### User interface options

* `radioFeaturedHomeSectionHeaderHidden` (optional, boolean): If set to `true`, featured radio media lists will not display any header.

## Livestream homepage

* `liveHomeSections` (optional, string, multiple): The sections to be displayed on the live homepage on iOS and iPadOS, in the order they must appear.
* `tvLiveHomeSections` (optional, string, multiple): The sections to be displayed on the live homepage on tvOS, in the order they must appear.

### Home sections

Feeds

* `tvLive`: TV livestreams. ([video/livestreams](https://il.srgssr.ch/integrationlayer/2.0/_BU_/mediaList/video/livestreams))
* `radioLive`: Radio livestreams. ([audio/livestreams](https://il.srgssr.ch/integrationlayer/2.0/_BU_/mediaList/audio/livestreams))
* `radioLiveSatellite`: Swiss Satellite radio livestreams. ([audio/livestreams](https://il.srgssr.ch/integrationlayer/2.0/_BU_/mediaList/audio/livestreams?onlyThirdPartyContentProvider=ssatr))
* `tvLiveCenterScheduledLivestreams`: Sport livestreams (with result). ([video/scheduledLivestreams/livecenter](https://il.srgssr.ch/integrationlayer/2.0/_BU_/mediaList/video/scheduledLivestreams/livecenter?types=scheduled_livestream))
* `tvLiveCenterScheduledLivestreamsAll`: Sport livestreams (all). ([video/scheduledLivestreams/livecenter](https://il.srgssr.ch/integrationlayer/2.0/_BU_/mediaList/video/scheduledLivestreams/livecenter?types=scheduled_livestream&onlyEventsWithResult=false))
* `tvLiveCenterEpisodes`: Past sport livestreams (with result). ([video/scheduledLivestreams/livecenter](https://il.srgssr.ch/integrationlayer/2.0/_BU_/mediaList/video/scheduledLivestreams/livecenter?types=episode))
* `tvLiveCenterEpisodesAll`: Past sport livestreams (all). ([video/scheduledLivestreams/livecenter](https://il.srgssr.ch/integrationlayer/2.0/_BU_/mediaList/video/scheduledLivestreams/livecenter?types=episode&onlyEventsWithResult=false))
* `tvScheduledLivestreams`: Scheduled livestreams. ([video/scheduledLivestreams](https://il.srgssr.ch/integrationlayer/2.0/_BU_/mediaList/video/scheduledLivestreams))
* `tvScheduledLivestreamsNews`: News scheduled livestreams. ([video/scheduledLivestreams](https://il.srgssr.ch/integrationlayer/2.0/_BU_/mediaList/video/scheduledLivestreams?eventType=news))
* `tvScheduledLivestreamsSport`: Sport scheduled livestreams (without highlight segments). ([video/scheduledLivestreams](https://il.srgssr.ch/integrationlayer/2.0/_BU_/mediaList/video/scheduledLivestreams?eventType=sport))
* `tvScheduledLivestreamsSignLanguage`: Sign language livestreams. ([video/scheduledLivestreams](https://il.srgssr.ch/integrationlayer/2.0/_BU_/mediaList/video/scheduledLivestreams?signLanguageOnly=true))

## Search

* `searchSettingsHidden` (optional, boolean): Set to `true` to hide support for search settings.
* `searchSettingSubtitledHidden` (optional, boolean): Set to `true` to hide the subtitled option in the search settings.
* `showsSearchHidden ` (optional, boolean): Set to `true` to hide show search results.

## Resume playback

* `endTolerance` (optional, number): Duration tolerance in seconds at the end of a media to consider it as finished and then subsequently not resume it from last position, but from the beginning. If empty, the default value is 0 seconds.
* `endToleranceRatio` (optional, number): Percentage tolerance as a floating number at the end of a media to consider it as finished and then subsequently not resume it from last position, but from the beginning. If empty, the default value is 0.0.

## Continuous playback

* `continuousPlaybackPlayerViewTransitionDuration` (optional, number): Duration in seconds for continuous playback when the player view is displayed. If empty, continuous playback is disabled; if equal to 0, upcoming media playback starts immediately.
* `continuousPlaybackForegroundTransitionDuration` (optional, number): Duration in seconds for continuous playback when the application runs in foreground and the player view is not displayed. If empty, continuous playback is disabled; if equal to 0, upcoming media playback starts immediately.
* `continuousPlaybackBackgroundTransitionDuration` (optional, number): Duration in seconds for continuous playback when the application runs in background. If empty, continuous playback is disabled; if equal to 0, upcoming media playback starts immediately.

## TV guide

* `tvGuideUnavailable` (optional, boolean): If set to `true`, TV guide access is removed and replaced with the legacy _by date_ access.
* `tvGuideOtherBouquets` (optional, string, multiple): TV guide other bouquets to display below the main vendor bouquet. Available values:
	* `thirdparty`: Third party bouquet delivered for the vendor.
	* `rsi`: RSI vendor bouquet.
	* `rts`: RT vendor bouquet.
	* `srf`: SR vendor bouquet.

## Other functionalities

* `audioDescriptionAvailabilityHidden` (optional, boolean): Set to `true` to hide audio description availability setting.
* `downloadsHintsHidden` (optional, boolean): If set to `true`, hints will not be displayed in lists for medias which can be downloaded.
* `hiddenOnboardings` (optional, string, multiple): Identifier list of onboardings which must be hidden.
* `historySynchronizationInterval` (optional, number): Duration in seconds for history synchronization. If omitted, defaults to 30 seconds. Miminum value is 10 seconds.
* `minimumSocialViewCount` (optional, number): The threshold under which social view counts will not be displayed. If omitted, 0.
* `posterImagesEnabled` (optional, boolean): If set to `true`, show poster images are displayed where appropriate.
* `podcastImagesEnabled` (optional, boolean): If set to `true`, show square images are displayed where appropriate.
* `showsUnavailable` (optional, boolean): If set to `true`, all features related to shows are removed.
* `subtitleAvailabilityHidden` (optional, boolean): Set to `true` to hide the subtitle availability setting.
* `discoverySubtitleOptionLanguage` (optional, string): Set system subtitle language to this value once and at the beginning to help user discover that content is subtitled in that language.
* `webFirstBadgeEnabled` (optional, boolean): Set to `true` to display the web first badge on media.
