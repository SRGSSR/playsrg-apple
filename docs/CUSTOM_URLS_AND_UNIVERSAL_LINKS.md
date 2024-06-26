# Custom URL and Universal Link support

Play applications can be opened with custom URLs starting with a URL scheme defined for each app. They can also be opened with universal links on iOS, provided the associated business unit website has enabled support for it.

## Custom URLs

The Play iOS and tvOS applications can be started using [custom URLs](https://developer.apple.com/documentation/xcode/defining-a-custom-url-scheme-for-your-app) having a reserved scheme. The scheme to use depends on the business unit and build variant to use, and has the following format:

`play(srf|rts|rsi|rtr|swi)(-beta|-nightly|-debug)`

For example Play RTS can be opened with URLs starting with `playrts://...`, while Play SRF debug build can be opened with URLs starting with `playsrf-debug://...`.

The hostname (first item after the `//` in the URL) describes the action which must be performed.

#### iOS application

Following actions are currently available for iOS application:

* Open a media within the player: `[scheme]://media/[media_urn]`. An optional `start_time=[start_time]` parameter can be added to start VOD / AOD playback at the specified position in second.
* Open a show page: `[scheme]://show/[show_urn]`.
* Open a topic page: `[scheme]://topic/[topic_urn]`.
* Open a section page: `[scheme]://section/[section_id]`.
* Open a micro page: `[scheme]://micropage/[page_id]`.
* Open a content page: `[scheme]://page/[page_id]`.
* Open a home page: `[scheme]://home`.
* Open shows A to Z page: `[scheme]://az`. An optional `index` single lowercase character parameter can be provided to open the page at the specified index.
* Open program guide page (videos), or shows by date page (audios): `[scheme]://bydate`. An optional `date` parameter with the `yyyy-MM-dd` format can be provided.
* Open the livestreams page: `[scheme]://livestreams`.
* Open search page: `[scheme]://search`. Optional `query` and `media_type` (with `video` or `audio` values) parameters can be provided.
* Open a URL: `[scheme]://link?url=[url]`.

For media, show and page links, an optional `channel_id=[channel_id]` parameter can be added, which resets the homepage to the specified radio channel homepage. If this parameter is not specified or does not match a valid channel, the homepage is reset to the TV one instead.

For a debug, nightly or beta build, a `server=[server_title]` parameter can also be added to force a server selection update. The available server list can be found in the application under *Settings* > *Advanced features* > *Server*.

The Play iOS application also supports pseudo-universal link URLs, obtained by replacing the URL scheme in the original portal URL with the application custom URL scheme:

* Open a Play web page: `[scheme]://[play_website_url]`. It uses the [parsePlayUrl.js](https://github.com/SRGSSR/playsrg-playfff/blob/main/docs/DEEP_LINK.md) file with the related function to attempt transforming the URL.

For example, if you want to open [https://www.rts.ch/play/tv/emissions?index=l](https://www.rts.ch/play/tv/emissions?index=l) with the Play RTS debug app, simply replace `https` with `playrts-debug`, as follows: [playrts-debug://www.rts.ch/play/tv/emissions?index=l](playrts-debug://www.rts.ch/play/tv/emissions?index=l)

#### tvOS application

The Play tvOS application supports only those custom URLs:

* Open a media page: `[scheme]://media/[media_urn]`. If it's a 24/7 livestream, the player page is open instead.
* Open a show page: `[scheme]://show/[show_urn]`.
* Open a micro page: `[scheme]://micropage/[page_id]`.
* Open a content page: `[scheme]://page/[page_id]`.

Refer to the _Testing_ section for more information about how custom URLs can be supplied to an application during tests.

## Universal Links

#### iOS application

The Play iOS application supports Apple universal links, provided that the associated business unit website declares a corresponding [association file](https://developer.apple.com/library/archive/documentation/General/Conceptual/AppSearch/UniversalLinks.html). If this is the case, you can open most of URLs of a Play business unit portal in the associated Play iOS application.

For test purposes, `Debug`, `Nightly` and `Beta` builds are associated to [play-web-staging web portal](https://play-web-staging.herokuapp.com/srf/play/tv). The first path component is the business unit. The [apple-app-site-association](https://play-web-staging.herokuapp.com/.well-known/apple-app-site-association) sorted arrays determine which build to open if more that one build for a BU are installed.

For example, if you want to open [https://www.rts.ch/play/tv/emissions?index=l](https://www.rts.ch/play/tv/emissions?index=l) with the Play RTS debug app, switch the BU domain to `play-web-staging.herokuapp.com/[BU]`: [https://play-web-staging.herokuapp.com/rts/play/tv/emissions?index=l](https://play-web-staging.herokuapp.com/rts/play/tv/emissions?index=l).

Refer to the _Testing_ section for more information about how universal URLs can be supplied to an application during tests.

#### tvOS application

The Play tvOS application does not support Apple universal links.

## Testing

To test custom or universal links, you can either:

- Use Safari (mobile or simulator):
  - Copy / paste the `url` in the address bar.
  - Load the page.
  - For universal links, scroll to the top and see a banner to open the app. 
- Use a text application, like Notes or Messages:
  - Copy / paste the `url` in the application.
  - Tap on the link to open it.
- Use the Simulator and the command line:
  - Open a simulator.
  - Run `xcrun simctl openurl booted <url>`.

The `Debug` builds can be associated to Play MMF portal if needed, by changing `BU__DOMAIN[config=Debug]` configuration value. [See MMF documentation](https://github.com/sRGSSR/playsrg-mmf?tab=readme-ov-file#associated-domains).

## Custom URL generation

The [Play MMF Deeplink tool](https://play-mmf.herokuapp.com/deeplink/index.html) is available for QR code generation of custom URLs with application supported custom schemes.

## Changelog

#### iOS application

- 3.8.4 version: Non-production builds are connected to Play web staging domain.
- 3.8.3 version: New micropage action. Share supported hostnames to the JS script.
- 3.6.8 version: New livestreams page action.
- 3.2.0 version: New section page action and module page action removal (modules not available on the web portal and in applications anymore).
- 2.9.6 version: Universal link version 2 support.

#### tvOS application

- 1.8.3 version: New micropage action.
- 1.0.0 version: New media and show actions.

## Examples

Open one of the following links on a mobile device to open the corresponding items in the associated Play application, if installed.

### RSI

| Item | Type | Production link | Beta link | Nightly link | Debug link |
|:--:|:--:|:--:|:--:|:--:|:--:|
| Telegiornale (2018/10/03) | Video | `playrsi://media/urn:rsi:video:10889069` | `playrsi-beta://media/urn:rsi:video:10889069` | `playrsi-nightly://media/urn:rsi:video:10889069` | `playrsi-debug://media/urn:rsi:video:10889069` |
| Radiogiornale | Radio show | `playrsi://show/urn:rsi:show:radio:2100980` | `playrsi-beta://show/urn:rsi:show:radio:2100980` | `playrsi-nightly://show/urn:rsi:show:radio:2100980` | `playrsi-debug://show/urn:rsi:show:radio:2100980` |

### RTR

| Item | Type | Production link | Beta link | Nightly link | Debug link |
|:--:|:--:|:--:|:--:|:--:|:--:|
| Telesguard (2018/10/03) | Video | `playrtr://media/urn:rtr:video:8e0c23b1-5ea6-463a-b48e-7d474158e992` | `playrtr-beta://media/urn:rtr:video:8e0c23b1-5ea6-463a-b48e-7d474158e992` | `playrtr-nightly://media/urn:rtr:video:8e0c23b1-5ea6-463a-b48e-7d474158e992` | `playrtr-debug://media/urn:rtr:video:8e0c23b1-5ea6-463a-b48e-7d474158e992` |
| Gratulaziuns | Radio show | `playrtr://show/urn:rtr:show:radio:a8b76055-1621-4d01-88c9-421e2ac14828` | `playrtr-beta://show/urn:rtr:show:radio:a8b76055-1621-4d01-88c9-421e2ac14828` | `playrtr-nightly://show/urn:rtr:show:radio:a8b76055-1621-4d01-88c9-421e2ac14828` | `playrtr-debug://show/urn:rtr:show:radio:a8b76055-1621-4d01-88c9-421e2ac14828` |

### RTS

| Item | Type | Production link | Beta link | Nightly link | Debug link |
|:--:|:--:|:--:|:--:|:--:|:--:|
| 19h30 (2018/10/03) | Video | `playrts://media/urn:rts:video:9890897` | `playrts-beta://media/urn:rts:video:9890897` | `playrts-nightly://media/urn:rts:video:9890897` | `playrts-debug://open?urn=urn:rts:video:9890897` |
| Sexomax | Radio show | `playrts://show/urn:rts:show:radio:8864883` | `playrts-beta://show/urn:rts:show:radio:8864883` | `playrts-nightly://show/urn:rts:show:radio:8864883` | `playrts-debug://show/urn:rts:show:radio:8864883` |

### SRF

| Item | Type | Production link | Beta link | Nightly link | Debug link |
|:--:|:--:|:--:|:--:|:--:|:--:|
| 10vor10 (2018/10/03) | Video | `playsrf://media/urn:srf:video:da6fdf91-3e91-46fb-be50-914e47203e45` | `playsrf-beta://media/urn:srf:video:da6fdf91-3e91-46fb-be50-914e47203e45` | `playsrf-nightly://media/urn:srf:video:da6fdf91-3e91-46fb-be50-914e47203e45` | `playsrf-debug://media/urn:srf:video:da6fdf91-3e91-46fb-be50-914e47203e45` |
| Buchzeichen | Radio show | `playsrf://show/urn:srf:show:radio:132857ed-76c6-4659-9e36-ab1e5bdf6e7f` | `playsrf-beta://show/urn:srf:show: radio:132857ed-76c6-4659-9e36-ab1e5bdf6e7f` | `playsrf-nightly://show/urn:srf:show: radio:132857ed-76c6-4659-9e36-ab1e5bdf6e7f` | `playsrf-debug://show/urn:srf:show: radio:132857ed-76c6-4659-9e36-ab1e5bdf6e7f` |

### SWI

| Item | Type | Production link | Beta link | Nightly link | Debug link |
|:--:|:--:|:--:|:--:|:--:|:--:|
| Zermatt’s new tri-cable car system | Video | `playswi://media/urn:swi:video:44438410` | `playswi-beta://media/urn:swi:video:44438410` | `playswi-nightly://media/urn:swi:video:44438410` | `playswi-debug://media/urn:swi:video:44438410` |