# URL schemes

Play applications can be opened with a custom URL scheme having the following format: `play(srf|rts|rsi|rtr|swi)(-beta|-nightly|-debug)`.

## Actions

The application supports Apple universal links. Replacing the `http`or `https` scheme of a Play website URL with the corresponding application scheme yields a link which can be opened with the application:

`[scheme]://[play_website_url_without_the_original_scheme]`

The available actions are:

* Open a media within the player: `[scheme]://media/[media_urn]`. An optional `&start_time=[start_time]` parameter can be added to start VOD / AOD playback at the specified position in second.
* Open a show page: `[scheme]://show/[show_urn]`.
* Open a topic page: `[scheme]://topic/[topic_urn]`.
* Open a section page: `[scheme]://section/[section_id]`.
* Open a home page: `[scheme]://home`.
* Open shows A to Z page: `[scheme]://az`. An optional `index` single character parameter can be provided to open the page at the specified index.
* Open shows by date page: `[scheme]://bydate`. An optional `date` parameter with the `yyyy-MM-dd` format can be provided.
* Open search page: `[scheme]://search`. Optional `query` and `media_type` (with `video` or `audio` values) parameters can be provided.
* Open a URL: `[scheme]://link?url=[url]`.

For media, show and page links, an optional `channel_id=[channel_id]` parameter can be added, which resets the homepage to the specified radio channel homepage. If this parameter is not specified or does not match a valid channel, the homepage is reset to the TV one instead.

For a `Debug`, `Nightly` or a `Beta` build, `server=[server_title]` parameter can be added to force a server selection update. The available server list can be found under *Settings* > *Advanced features* > *Server*.

### Changelog

- Version 3.2.0: New section page action and module page action removal (modules not available on the web portal and in applications anymore).
- Version 2.9.6: Version 2 of universal link support.

### URL generation

An [online tool](https://play-mmf.herokuapp.com/deeplink/index.html) is available for QR code generation of URLs with supported custom schemes.

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