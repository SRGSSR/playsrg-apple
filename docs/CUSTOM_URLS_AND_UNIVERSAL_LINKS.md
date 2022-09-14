# Custom URL and Universal Link support

Play applications can be opened with custom URLs starting with a URL scheme defined for each app. They can also be opened with universal links, provided the associated business unit website has enabled support for it.

## Custom URLs

Play application can be started using [custom URLs](https://developer.apple.com/documentation/xcode/defining-a-custom-url-scheme-for-your-app) having a reserved scheme. The scheme to use depends on the business unit and build variant to use, and has the following format:

`play(srf|rts|rsi|rtr|swi)(-beta|-nightly|-debug)`

For example Play RTS can be opened with URLs starting with `playrts://...`, while Play SRF debug can be opened with URLs starting with `playsrf-debug://...`.

The host name (first item after the `//` in the URL) describes the action which must be performed. Following actions are currently available:

* Open a media within the player: `[scheme]://media/[media_urn]`. An optional `start_time=[start_time]` parameter can be added to start VOD / AOD playback at the specified position in second.
* Open a show page: `[scheme]://show/[show_urn]`.
* Open a topic page: `[scheme]://topic/[topic_urn]`.
* Open a section page: `[scheme]://section/[section_id]`.
* Open a home page: `[scheme]://home`.
* Open shows A to Z page: `[scheme]://az`. An optional `index` single lowercase character parameter can be provided to open the page at the specified index.
* Open program guide page (videos), or shows by date page (audios): `[scheme]://bydate`. An optional `date` parameter with the `yyyy-MM-dd` format can be provided.
* Open search page: `[scheme]://search`. Optional `query` and `media_type` (with `video` or `audio` values) parameters can be provided.
* Open a URL: `[scheme]://link?url=[url]`.

For media, show and page links, an optional `channel_id=[channel_id]` parameter can be added, which resets the homepage to the specified radio channel homepage. If this parameter is not specified or does not match a valid channel, the homepage is reset to the TV one instead.

For a debug, nightly or beta build, a `server=[server_title]` parameter can also be added to force a server selection update. The available server list can be found in the application under *Settings* > *Advanced features* > *Server*.

The Play application also supports pseudo-universal link URLs, obtained by replacing the URL scheme in the original portal URL with the application custom URL scheme.

For example, if you want to open [https://www.rts.ch/play/tv/emissions?index=l](https://www.rts.ch/play/tv/emissions?index=l) with the Play RTS debug app, simply replace `https` with `playrts-debug`, as follows: [playrts-debug://www.rts.ch/play/tv/emissions?index=l](playrts-debug://www.rts.ch/play/tv/emissions?index=l)

Refer to the _Testing_ section for more information about how custom URLs can be supplied to an application during tests.

## Universal Links

The application supports Apple universal links, provided that the associated business unit website declares a corresponding [association file](https://developer.apple.com/library/archive/documentation/General/Conceptual/AppSearch/UniversalLinks.html). If this is the case you can open most of URLs of a Play business unit portal in the associated Play application.

For test purposes, and since this feature requires support from the portal which is not always available (e.g. for internal builds or business units which have not deployed an association file), there is a way to have universal link URLs for `Debug` configuration builds using the [Play MMF Deeplink](https://play-mmf.herokuapp.com/deeplink/index.html) tool to get an associated `https://play-mmf.herokuapp.com/[BU]/[…]` URL.

For example, if you want to open [https://www.rts.ch/play/tv/emissions?index=l](https://www.rts.ch/play/tv/emissions?index=l) with the Play RTS debug app, simply decode this URL with the [Play MMF Deeplink](https://play-mmf.herokuapp.com/deeplink/index.html) tool and get the Play MMF associated URL: [https://play-mmf.herokuapp.com/rts/play/tv/emissions?index=l](https://play-mmf.herokuapp.com/rts/play/tv/emissions?index=l).

Refer to the _Testing_ section for more information about how universal URLs can be supplied to an application during tests.

## Testing

To test custom or universal links, you can either:

- Use Safari (mobile or simulator) and copy / paste the URL in the address bar.
- Start the app in the simulator and send the URL to it from the command line with `xcrun simctl openurl booted <url>`.

## URL generation

The [Play MMF Deeplink](https://play-mmf.herokuapp.com/deeplink/index.html) tool is available for QR code generation of custom URLs with supported custom schemes. It can also generate universal links for the `Debug` configuration builds (associated with `https://play-mmf.herokuapp.com/[BU]/[…]` URLs).

## Changelog

- Version 3.2.0: New section page action and module page action removal (modules not available on the web portal and in applications anymore).
- Version 2.9.6: Version 2 of universal link support.

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