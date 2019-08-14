# URL schemes

Play applications can be opened with a custom URL scheme having the following format: `play(srf|rts|rsi|rtr|swi)(-beta|-nightly|-debug)`.

## Actions

The application supports Apple universal links. Replacing the `http`or `https` scheme of a Play website URL with the corresponding application scheme yields a link which can be opened with the application:

`[scheme]://[play_website_url_without_the_original_scheme]`

The available actions are:

* Open a media within the player: `[scheme]://open?media=[media_urn]`. An optional `&start-time=[start_time]` parameter can be added to start VOD / AOD playback at the specified position in second.
* Open a show page: `[scheme]://open?show=[show_urn]`.
* Open a topic page: `[scheme]://open?topic=[topic_urn]`.
* Open a module page: `[scheme]://open?module=[module_urn]`.
* Open a page: `[scheme]://open?page-id=[page_id]`.
	* Home page: `home`.
	* Search page: `search`. Optional `query` and `mediaType` (with `video` or `audio` values) parameters can be provided.
	* Shows A to Z page: `az`. An optional `index` single character parameter can be provided to open the page at the specified index.
	* Shows by date page: `bydate`. An optional `date` parameter with the `yyyy-MM-dd` format can be provided.
* Open a URL: `[scheme]://open?url=[url]`.

For media, show and page links, an optional `&channel-id=[channel_id]` parameter can be added, which resets the homepage to the specified radio channel homepage. If this parameter is not specified or does not match a valid channel, the homepage is reset to the TV one instead.

For a `Debug`, `Nightly` or a `Beta` build, `&server=[server_title]` parameter can be added to force a server selection update. The available server list can be found under *Settings* > *Advanced features* > *Server*.

### URL generation

An [online tool](https://play-mmf.herokuapp.com/deeplink/index.html) is available for QR code generation of URLs with supported custom schemes.

## Examples

Open one of the following links on a mobile device to open the corresponding items in the associated Play application, if installed.

### RSI

| Item | Type | Production link | Beta link | Nightly link | Debug link |
|:--:|:--:|:--:|:--:|:--:|:--:|
| Telegiornale (2018/10/03) | Video | `playrsi://open?media=urn:rsi:video:10889069` | `playrsi-beta://open?media=urn:rsi:video:10889069` | `playrsi-nightly://open?media=urn:rsi:video:10889069` | `playrsi-debug://open?media=urn:rsi:video:10889069` |
| Radiogiornale | Radio show | `playrsi://open?show=urn:rsi:show:radio:2100980` | `playrsi-beta://open?show=urn:rsi:show:radio:2100980` | `playrsi-nightly://open?show=urn:rsi:show:radio:2100980` | `playrsi-debug://open?show=urn:rsi:show:radio:2100980` |

### RTR

| Item | Type | Production link | Beta link | Nightly link | Debug link |
|:--:|:--:|:--:|:--:|:--:|:--:|
| Telesguard (2018/10/03) | Video | `playrtr://open?media=urn:rtr:video:8e0c23b1-5ea6-463a-b48e-7d474158e992` | `playrtr-beta://open?media=urn:rtr:video:8e0c23b1-5ea6-463a-b48e-7d474158e992` | `playrtr-nightly://open?media=urn:rtr:video:8e0c23b1-5ea6-463a-b48e-7d474158e992` | `playrtr-debug://open?media=urn:rtr:video:8e0c23b1-5ea6-463a-b48e-7d474158e992` |
| Gratulaziuns | Radio show | `playrtr://open?show=urn:rtr:show:radio:a8b76055-1621-4d01-88c9-421e2ac14828` | `playrtr-beta://open?show=urn:rtr:show:radio:a8b76055-1621-4d01-88c9-421e2ac14828` | `playrtr-nightly://open?show=urn:rtr:show:radio:a8b76055-1621-4d01-88c9-421e2ac14828` | `playrtr-debug://open?show=urn:rtr:show:radio:a8b76055-1621-4d01-88c9-421e2ac14828` |

### RTS

| Item | Type | Production link | Beta link | Nightly link | Debug link |
|:--:|:--:|:--:|:--:|:--:|:--:|
| 19h30 (2018/10/03) | Video | `playrts://open?media=urn:rts:video:9890897` | `playrts-beta://open?media=urn:rts:video:9890897` | `playrts-nightly://open?media=urn:rts:video:9890897` | `playrts-debug://open?urn=urn:rts:video:9890897` |
| Sexomax | Radio show | `playrts://open?show=urn:rts:show:radio:8864883` | `playrts-beta://open?show=urn:rts:show:radio:8864883` | `playrts-nightly://open?show=urn:rts:show:radio:8864883` | `playrts-debug://open?show=urn:rts:show:radio:8864883` |

### SRF

| Item | Type | Production link | Beta link | Nightly link | Debug link |
|:--:|:--:|:--:|:--:|:--:|:--:|
| 10vor10 (2018/10/03) | Video | `playsrf://open?media=urn:srf:video:da6fdf91-3e91-46fb-be50-914e47203e45` | `playsrf-beta://open?media=urn:srf:video:da6fdf91-3e91-46fb-be50-914e47203e45` | `playsrf-nightly://open?media=urn:srf:video:da6fdf91-3e91-46fb-be50-914e47203e45` | `playsrf-debug://open?media=urn:srf:video:da6fdf91-3e91-46fb-be50-914e47203e45` |
| Buchzeichen | Radio show | `playsrf://open?show=urn:srf:show:radio:132857ed-76c6-4659-9e36-ab1e5bdf6e7f` | `playsrf-beta://open?show=urn:srf:show: radio:132857ed-76c6-4659-9e36-ab1e5bdf6e7f` | `playsrf-nightly://open?show=urn:srf:show: radio:132857ed-76c6-4659-9e36-ab1e5bdf6e7f` | `playsrf-debug://open?show=urn:srf:show: radio:132857ed-76c6-4659-9e36-ab1e5bdf6e7f` |

### SWI

| Item | Type | Production link | Beta link | Nightly link | Debug link |
|:--:|:--:|:--:|:--:|:--:|:--:|
| Zermatt’s new tri-cable car system | Video | `playswi://open?media=urn:swi:video:44438410` | `playswi-beta://open?media=urn:swi:video:44438410` | `playswi-nightly://open?media=urn:swi:video:44438410` | `playswi-debug://open?media=urn:swi:video:44438410` |