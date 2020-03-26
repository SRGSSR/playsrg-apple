# Remote configuration

The proprietary project can be configured remotely using [Firebase](https://firebase.google.com/). All primitive parameters (strings, numbers, booleans, JSON) from the `ApplicationConfiguration.json` file can be overridden. 

Some parameters are mandatory and others are optional. All applications are provided with a default configuration, available even when the Firebase service could not be queried (e.g. if no network connection is initially available).

If a parameter is overridden in the Firebase console, its value will be used, otherwise the local value will be used instead. If you want to disable an optional parameter for which a local value is available, you must therefore define an override for it in the Firebase console, providing no value.

The remote configuration has a validity of 15 minutes (30 seconds when debugging and in nightly builds), and is applied when the application wakes up from the background.

If a remote configuration is found to be invalid (usually a mandatory parameter is missing), the application will ignore it and continue with the previous valid configuration.

## Application configuration

* `appStoreProductIdentifier` (mandatory, number): Application product identifier on the AppStore.
* `businessUnit` (mandatory, string): The identifier of the business unit.
* `googleCastReceiverIdentifier` (optional, string): Identifier of the Google Cast receiver to use. If not set, the default Google Cast receiver is used.
* `pageSize` (optional, number): The page size to use for media lists in general, 20 if not set.
* `voiceOverLanguageCode` (optional, string): The code of the language associated with the application. If set, this language is used when reading texts for accessibility purposes, otherwise the device language is used.

## URLs

* `betaTestingURL` (optional, string): The URL of the page where beta testers can register.
* `feedbackURL` (optional, string): The URL of the feedback form.
* `dataProtectionURL` (optional, string): The URL of the data protection information page.
* `impressumURL` (optional, string): The URL of the impressum page. If none is provided, the corresponding menu entry will not be displayed. 
* `historyServiceURL` (optional, string): The URL of the history service.
* `middlewareURL` (mandatory, string): The URL of the Play application middleware.
* `playURL` (mandatory, string): The base URL of the Play portal, used when building sharing URLs.
* `sourceCodeURL` (optional, string); The URL where the application source code can be found.
* `termsAndConditionsURL` (optional, string): The URL of the terms and conditions page.
* `whatsNewURL` (mandatory, string): The URL at which the update information can be retrieved.

## Analytics

* `comScoreVirtualSite` (mandatory, string): The comScore virtual site to send events to.
* `netMetrixIdentifier` (mandatory, string): The NetMetrix application identifier.

## Channel configuration

* `tvChannels` (optional, JSON): A JSON array of JSON dictionaries describing TV channel configuration, and made of the following keys:
    * `uid` (mandatory, string): The unique identifier of the TV channel.
    * `name` (mandatory, string): The TV channel name.
    * `resourceUid` (mandatory, string): Local unique identifier for referencing resources related to the channel.
* `radioChannels` (optional, JSON): A JSON array of JSON dictionaries describing radio channel configuration, and made of the following keys:
    * `uid` (mandatory, string): The unique identifier of the radio channel.
    * `name` (mandatory, string): The radio channel name.
    * `resourceUid` (mandatory, string): Local unique identifier for referencing resources related to the channel.
    * `color` (mandatory, string): The radio channel primary hex color. Used as navigation bar background color.
    * `homeSections` (optional, string, multiple): The sections to be displayed on the radio channel homepage. Refer to _Audio homepage_ for available values. If omitted, the global `audioHomeSections` setting is used instead (in which case this value is required).
    * `titleColor` (optional, string): Hex color of the text displayed within the navigation bar (should provide sufficient contrast with `color`). If omitted, white.
    * `hasDarkStatusBar` (optional, boolean): `true` iff the status bar should be dark for this channel. If omitted, `false`.

## Video homepage

`videoHomeSections` (optional, string, multiple): The sections to be displayed on the videos homepage, in the order they must appear.

### Home sections

* `tvEvents`: Event modules.
* `tvFavoriteShows`: TV shows added to the favorites.
* `tvLatest`: The latest medias.
* `tvShowsAccess`: A-Z and By date access buttons.
* `tvSoonExpiring`: Soon expiring videos.
* `tvTopics`: Topics.
* `tvTrending`: Trending medias and editorial picks. See `tvTrendingEpisodesOnly` and `tvTrendingEditorialLimit` options.
* `tvMostPopular`: The most popular videos.

### Topic configuration

* `topicSections` (optional, string, multiple): The sections to be displayed when opening a topic. If none is provided, latest medias are displayed. Available values are:
   * `latest`: The latest medias.
   * `mostPopular`: The most popular medias
* `topicSectionsWithSubtopics` (optional, string, multiple): The sections to be displayed when opening a topic with subtopics. If none is provided, only subtopics are displayed. Available values are the same as `topicSections`.

### User interface options

* `topicHomeHeadersHidden` (optional, boolean): If set to `true`, the quick access header item on home page topics swimlanes will not be displayed.
* `tvFeaturedHomeSectionHeaderHidden` (optional, boolean): If set to `true`, featured TV media lists will not display any header.
* `tvTrendingEpisodesOnly` (optional, boolean): If set to `true`, `tvTrending` only returns episodes.
* `tvTrendingEditorialLimit` (optional, number): The maximum number of editorial recommendations returned by `tvTrending`. If not set, all are returned.

## Audio homepage

`audioHomeSections` (optional, string, multiple): The sections to be displayed on the audio homepage of a radio channel, in the order they must appear.

### Home sections:

* `radioAllShows`: All available shows.
* `radioFavoriteShows`: Radio shows added to the favorites.
* `radioLatest`: The latest audios.
* `radioLatestEpisodes`: The latest episodes.
* `radioLatestVideos`: The latest videos.
* `radioMostPopular`: The most popular audios.
* `radioMyListShows`: Shows from "My list".
* `radioShowsAccess`: A-Z and By date access buttons.

### User interface options

* `radioFeaturedHomeSectionHeaderHidden` (optional, boolean): If set to `true`, featured radio media lists will not display any header.

## Livestream homepage

`liveHomeSections` (optional, string, multiple): The sections to be displayed on the live homepage, in the order they must appear.

### Home sections

* `tvLive`: TV livestreams.
* `radioLive`: Radio livestreams.
* `radioLiveSatellite`: Satellite radio livestreams.
* `tvLiveCenter`: SwissTXT livestreams.
* `tvScheduledLivestreams`: Scheduled livestreams.

## Search

* `searchSettingsHidden` (optional, boolean): Set to `true` to hide support for search settings.
* `searchSettingSubtitledHidden` (optional, boolean): Set to `true` to hide the subtitled option in the search settings.
* `showsSearchHidden ` (optional, boolean): Set to `true` to hide show search results.

## Continuous playback

* `continuousPlaybackPlayerViewTransitionDuration` (optional, number): Duration in seconds for continuous playback when the player view is displayed. If empty, continuous playback is disabled; if equal to 0, upcoming media playback starts immediately.
* `continuousPlaybackForegroundTransitionDuration` (optional, number): Duration in seconds for continuous playback when the application runs in foreground and the player view is not displayed. If empty, continuous playback is disabled; if equal to 0, upcoming media playback starts immediately.
* `continuousPlaybackBackgroundTransitionDuration` (optional, number): Duration in seconds for continuous playback when the application runs in background. If empty, continuous playback is disabled; if equal to 0, upcoming media playback starts immediately.

## Other functionalities

* `audioDescriptionAvailabilityHidden` (optional, boolean): Set to `true` to hide audio description availability setting.
* `downloadsHintsHidden` (optional, boolean): If set to `true`, hints will not be displayed in lists for medias which can be downloaded.
* `hiddenOnboardings` (optional, string, multiple): Identifier list of onboardings which must be hidden.
* `historySynchronizationInterval` (optional, number): Duration in seconds for history synchronization. If omitted, defaults to 30 seconds. Miminum value is 10 seconds.
* `minimumSocialViewCount` (optional, number): The threshold under which social view counts will not be displayed. If omitted, 0.
* `moreEpisodesHidden` (optional, boolean): If set to `true`, the option to display more episodes for a media will not be available from the long-press and peek menus.
* `subtitleAvailabilityHidden` (optional, boolean): Set to `true` to hide the subtitle availability setting.
