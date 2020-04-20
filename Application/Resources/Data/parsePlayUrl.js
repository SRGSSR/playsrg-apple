// parsePlayUrl

var parsePlayUrlVersion = 24;
var parsePlayUrlBuild = "mmf";

if(! console) {
    var console = {
        log:function(){}
    }
}

function parseForPlayApp(scheme, hostname, pathname, queryParams, anchor) {
	// fix path issue
	pathname = pathname.replace("//", "/");

	// Get BU
	var bu = getBuFromHostname(hostname,pathname);
	if (! bu) {
		console.log("This URL is not a Play SRG URL.");
		return null;
	}

	// Get server
	var server = serverForUrl(hostname, pathname, queryParams);

	/**
	 *  Catch special case: Player web
	 *
	 *  Ex: https://tp.srgssr.ch/p/rts/default?urn=urn:rts:video:6735513
	 *  Ex: https://player.rts.ch/p/rts/default?urn=urn:rts:video:6735513&start=60
	 */
	if (bu == "tp") {
		if (pathname.startsWith("/p/")) {
			var mediaURN = queryParams["urn"];
			if (mediaURN) {
				var redirectBu = "tp";
				switch (true) {
					case pathname.startsWith("/p/srf/"):
						redirectBu = "srf";
						break;
					case pathname.startsWith("/p/rts/"):
						redirectBu = "rts";
						break;
					case pathname.startsWith("/p/rsi/"):
						redirectBu = "rsi";
						break;
					case pathname.startsWith("/p/rtr/"):
						redirectBu = "rtr";
						break;
					case pathname.startsWith("/p/swi/"):
						redirectBu = "swi";
						break;
				}
				var startTime = queryParams["start"];
				return openMediaURN(server, redirectBu, mediaURN, startTime);
			}
		}
	}

	/**
	 *  Catch special case: radio swiss
	 *
	 *  Ex: http://www.radioswisspop.ch/de/webplayer
	 *  Ex: http://www.radioswissclassic.ch/fr/webplayer
	 *  Ex: http://www.radioswissjazz.ch/it/webplayer
	 */
	if (bu == "radioswiss") {
		var redirectBu = null;
		switch (true) {
			case pathname.startsWith("/de"):
				redirectBu = "srf";
				break;
			case pathname.startsWith("/fr"):
				redirectBu = "rts";
				break;
			case pathname.startsWith("/it"):
				redirectBu = "rsi";
				break;
		}
		if (redirectBu) {
			return openURL(server, redirectBu, scheme, hostname, pathname, queryParams, anchor);
		}
	}

	/**
	 *  Catch special case: Play MMF
	 *
	 *  Ex: https://play-mmf.herokuapp.com/mmf/
	 *  Ex: https://play-mmf.herokuapp.com/mmf/media/urn:rts:video:_rts_info_delay
	 */
	if (bu == "mmf") {
		if (pathname.includes("/media/")) {
			var lastPathComponent = pathname.split("/").slice(-1)[0];
			return openMediaURN(server, bu, lastPathComponent, null);
		}

		// Returns default TV homepage
		return openTvHomePage(server, bu);
	}

	if (hostname.includes("play-mmf") && ! pathname.startsWith("/mmf/")) {
		pathname = pathname.substring(4);
	}

	if (hostname.includes("play-web")) {
		pathname = pathname.substring(4);
		pathname = pathname.replace("/stage/play", "/play");
		pathname = pathname.replace("/test/play", "/play");
	}

	/**
	 *  Catch special case: shared RTS media urls built by RTS MAM.
	 *
	 *  Ex: https://www.rts.ch/video
	 *  Ex: https://www.rts.ch/video/emissions/signes/9901229-la-route-de-lexil-en-langue-des-signes.html
	 *  Ex: https://www.rts.ch/audio/la-1ere
	 */
	if (bu == "rts" && (pathname.startsWith("/video") || pathname.startsWith("/audio"))) {
		var mediaId = null;

		if (pathname.endsWith(".html")) {
			var lastPath = pathname.substr(pathname.lastIndexOf('/') + 1);
			mediaId = lastPath.split('.')[0].split('-')[0];
		}

		if (mediaId) {
			var mediaType = (pathname.startsWith("/video")) ? "video" : "audio";
			return openMedia(server, bu, mediaType, mediaId, null);
		}
		else if (pathname.startsWith("/video")) {
			// Returns default TV homepage
			return openTvHomePage(server, bu);
		}
		else {
			var channelId = null;
			var paths = pathname.split('/');
			if (paths.length > 2) {
				var radioId = paths[2];
				switch (radioId) {
					case "la-1ere":
						channelId = "a9e7621504c6959e35c3ecbe7f6bed0446cdf8da";
						break;
					case "espace-2":
						channelId = "a83f29dee7a5d0d3f9fccdb9c92161b1afb512db";
						break;
					case "couleur3":
						channelId = "8ceb28d9b3f1dd876d1df1780f908578cbefc3d7";
						break;
					case "option-musique":
						channelId = "f8517e5319a515e013551eea15aa114fa5cfbc3a";
						break;
				}
			}
			// Returns default radio homepage
			return openRadioHomePage(server, bu, channelId);
		}
	}

	if (! pathname.startsWith("/play")) {
		console.log("No /play path in url.");
		return null;
	}

	/**
	 *  Catch classic media urls
	 *
	 *  Ex: https://www.rts.ch/play/tv/faut-pas-croire/video/exportations-darmes--la-suisse-vend-t-elle-la-guerre-ou-la-paix-?id=9938530
	 *  Ex: https://www.srf.ch/play/tv/_/video/_?urn=urn:srf:scheduled_livestream:video:6d49170d-16e9-45ef-a8aa-00873333a610 (strange)
	 */
	var mediaType = null;
	switch (true) {
		case pathname.includes("/video/"):
			mediaType = "video";
			break;
		case pathname.includes("/audio/"):
			mediaType = "audio";
			break;
	}

	if (mediaType) {
		var mediaUrn = queryParams["urn"];
		var mediaId = queryParams["id"];
		var startTime = queryParams["startTime"];
		if (mediaUrn) {
			return openMediaURN(server, bu, mediaUrn, startTime);
		}
		else if (mediaId) {	
			return openMedia(server, bu, mediaType, mediaId, startTime);
		}
		else {
			mediaType = null;
		}
	}

	/**
	 *  Catch redirect media urls
	 *
	 *  Ex: https://www.rts.ch/play/tv/redirect/detail/9938530
	 */
	switch (true) {
		case pathname.includes("/tv/redirect/detail/"):
			mediaType = "video";
			break;
		case pathname.includes("/radio/redirect/detail/"):
			mediaType = "audio";
			break;
	}

	if (mediaType) {
		var mediaId = pathname.substr(pathname.lastIndexOf('/') + 1);
		if (mediaId) {
			var startTime = queryParams["startTime"];
			return openMedia(server, bu, mediaType, mediaId, startTime);
		}
		else {
			mediaType = null;
		}
	}

	/**
	 *  Catch live TV urls
	 *
	 *  Ex: https://www.srf.ch/play/tv/live?tvLiveId=c49c1d73-2f70-0001-138a-15e0c4ccd3d0
	 *  Ex: https://www.srf.ch/play/tv/live/?tvLiveId=c49c1d73-2f70-0001-138a-15e0c4ccd3d0
	 */
	if (pathname.endsWith("/tv/live") || pathname.endsWith("/tv/live/") || pathname.endsWith("/tv/direct") || pathname.endsWith("/tv/direct/")) {
		var mediaId = queryParams["tvLiveId"];
		if (mediaId) {
			return openMedia(server, bu, "video", mediaId, null);
		}
		else {
			// Returns default TV homepage
			return openTvHomePage(server, bu);
		}
	}

	/**
	 *  Catch live radio urls
	 *
	 *  Ex: https://www.rsi.ch/play/radio/livepopup/rete-uno
	 *  Ex: https://www.rsi.ch/play/radio/legacy-livepopup/rete-uno
	 */
	if (pathname.includes("/radio/livepopup/") || pathname.includes("/radio/legacy-livepopup/")) {
		var mediaBu = null;
		var mediaId = null;
		switch (pathname.substr(pathname.lastIndexOf('/') + 1)) {
			case "radio-srf-1":
				mediaBu = "srf";
				mediaId = "69e8ac16-4327-4af4-b873-fd5cd6e895a7";
				break;
			case "radio-srf-2-kultur":
				mediaBu = "srf";
				mediaId = "c8537421-c9c5-4461-9c9c-c15816458b46";
				break;
			case "radio-srf-3":
				mediaBu = "srf";
				mediaId = "dd0fa1ba-4ff6-4e1a-ab74-d7e49057d96f";
				break;
			case "radio-srf-4-news":
				mediaBu = "srf";
				mediaId = "ee1fb348-2b6a-4958-9aac-ec6c87e190da";
				break;
			case "radio-srf-musikwelle":
				mediaBu = "srf";
				mediaId = "a9c5c070-8899-46c7-ac27-f04f1be902fd";
				break;
			case "radio-srf-virus":
				mediaBu = "srf";
				mediaId = "66815fe2-9008-4853-80a5-f9caaffdf3a9";
				break;
			case "la-1ere":
				mediaBu = "rts";
				mediaId = "3262320";
				break;
			case "espace-2":
				mediaBu = "rts";
				mediaId = "3262362";
				break;
			case "couleur-3":
				mediaBu = "rts";
				mediaId = "3262363";
				break;
			case "option-musique":
				mediaBu = "rts";
				mediaId = "3262364";
				break;
			case "rete-uno":
				mediaBu = "rsi";
				mediaId = "livestream_ReteUno";
				break;
			case "rete-due":
				mediaBu = "rsi";
				mediaId = "livestream_ReteDue";
				break;
			case "rete-tre":
				mediaBu = "rsi";
				mediaId = "livestream_ReteTre";
				break;
			case "rtr":
				mediaBu = "rtr";
				mediaId = "a029e818-77a5-4c2e-ad70-d573bb865e31";
				break;
		}

		if (mediaBu && mediaId) {
			return openMedia(server, mediaBu, "audio", mediaId, null);
		}
		else {
			// Returns default radio homepage
			return openRadioHomePage(server, bu, null);
		}
	}

	/**
	 *  Catch tv video popup urls
	 *
	 *  Ex: https://www.srf.ch/play/tv/popupvideoplayer?id=b833a5af-63c6-4310-bb80-05341310a4f5
	 */
	if (pathname.includes("/tv/popupvideoplayer")) {
		var mediaId = queryParams["id"];
		if (mediaId) {
			return openMedia(server, bu, "video", mediaId, null);
		}
		else {
			// Returns default TV homepage
			return openTvHomePage(server, bu);
		}
	}

	/**
	 *  Catch radio audio popup urls
	 *
	 *  Ex: https://www.srf.ch/play/radio/popupaudioplayer?id=dc5e9465-ac64-409a-9878-ee47de3d1346
	 */
	if (pathname.includes("/radio/popupaudioplayer")) {
		var mediaId = queryParams["id"];
		if (mediaId) {
			return openMedia(server, bu, "audio", mediaId, null);
		}
		else {
			// Returns default radio homepage
			return openRadioHomePage(server, bu, null);
		}
	}

	/**
	 *  Catch classic show urls
	 *
	 *  Ex: https://www.rts.ch/play/tv/emission/faut-pas-croire?id=6176
	 */
	var showTransmission = null;
	switch (true) {
		case pathname.includes("/tv/sendung") || pathname.includes("/tv/emission") || pathname.includes("/tv/programma") || pathname.includes("/tv/emissiuns"):
			showTransmission = "tv";
			break;
		case pathname.includes("/radio/sendung") || pathname.includes("/radio/emission") || pathname.includes("/radio/programma") || pathname.includes("/radio/emissiuns"):
			showTransmission = "radio";
			break;
	}

	if (showTransmission) {
		var showId = queryParams["id"];
		if (showId) {
			return openShow(server, bu, showTransmission, showId);
		}
		else {
			showTransmission = null;
		}
	}

	/**
	 *  Catch redirect and simple show urls
	 *
	 *  Ex: https://www.rts.ch/play/tv/quicklink/6176
	 *  Ex: https://www.rts.ch/play/tv/show/9674517
	 */
	switch (true) {
		case pathname.includes("/tv/quicklink/"):
		case pathname.includes("/tv/show/"):
			showTransmission = "tv";
			break;
		case pathname.includes("/radio/quicklink/"):
		case pathname.includes("/radio/show/"):
			showTransmission = "radio";
			break;
	}

	if (showTransmission) {
		var showId = pathname.substr(pathname.lastIndexOf('/') + 1);
		if (showId) {
			return openShow(server, bu, showTransmission, showId);
		}
		else {
			showTransmission = null;
		}
	}

	/**
	 *  Catch home TV urls
	 *
	 *  Ex: https://www.srf.ch/play/tv
	 */
	if (pathname.endsWith("/tv")) {
		return openTvHomePage(server, bu);
	}

	/**
	 *  Catch home radio urls
	 *
	 *  Ex: https://www.srf.ch/play/radio?station=ee1fb348-2b6a-4958-9aac-ec6c87e190da
	 */
	if (pathname.endsWith("/radio")) {
		var channelId = queryParams["station"];
		return openRadioHomePage(server, bu, channelId);
	}

	/**
	 *  Catch AZ TV urls
	 *
	 *  Ex: https://www.rts.ch/play/tv/emissions?index=G
	 */
	if (pathname.endsWith("/tv/sendungen") || pathname.endsWith("/tv/emissions") || pathname.endsWith("/tv/programmi") || pathname.endsWith("/tv/emissiuns")) {
		var index = queryParams["index"];
		if (index) {
			index = index.toLowerCase();
			index = (index.length > 1) ? null : index;
		}
		return openAtoZ(server, bu, null, index);
	}

	/**
	 *  Catch AZ radio urls
	 *
	 *  Ex: https://www.rts.ch/play/radio/emissions?index=S&station=8ceb28d9b3f1dd876d1df1780f908578cbefc3d7
	 */
	if (pathname.endsWith("/radio/sendungen") || pathname.endsWith("/radio/emissions") || pathname.endsWith("/radio/programmi") || pathname.endsWith("/radio/emissiuns")) {
		var channelId = queryParams["station"];
		var index = queryParams["index"];
		if (index) {
			index = index.toLowerCase();
			index = (index.length > 1) ? null : index;
		}
		return openRadioAtoZ(server, bu, channelId, index);
	}

	/**
	 *  Catch by date TV urls
	 *
	 *  Ex: https://www.rtr.ch/play/tv/emissiuns-tenor-data?date=07-03-2019
	 */
	if (pathname.endsWith("/tv/sendungen-nach-datum") || pathname.endsWith("/tv/emissions-par-dates") || pathname.endsWith("/tv/programmi-per-data") || pathname.endsWith("/tv/emissiuns-tenor-data")) {
		var date = queryParams["date"];
		if (date) {
			// Returns an ISO format
			var dateArray = date.split("-");
			if (dateArray.length == 3 && dateArray[2].length == 4 && dateArray[1].length == 2 && dateArray[0].length == 2) {
				date = dateArray[2] + "-" + dateArray[1] + "-" + dateArray[0];
			}
			else {
				date = null;
			}
		}
		return openByDate(server, bu, null, date);
	}

	/**
	 *  Catch by date radio urls
	 *
	 *  Ex: https://www.rts.ch/play/radio/emissions-par-dates?date=07-03-2019&station=8ceb28d9b3f1dd876d1df1780f908578cbefc3d7
	 */
	if (pathname.endsWith("/radio/sendungen-nach-datum") || pathname.endsWith("/radio/emissions-par-dates") || pathname.endsWith("/radio/programmi-per-data") || pathname.endsWith("/radio/emissiuns-tenor-data")) {
		var channelId = queryParams["station"];
		var date = queryParams["date"];
		if (date) {
			// Returns an ISO format
			var dateArray = date.split("-");
			if (dateArray.length == 3 && dateArray[2].length == 4 && dateArray[1].length == 2 && dateArray[0].length == 2) {
				date = dateArray[2] + "-" + dateArray[1] + "-" + dateArray[0];
			}
			else {
				date = null;
			}
		}
		return openRadioByDate(server, bu, channelId, date);
	}

	/**
	 *  Catch search urls
	 *
	 *  Ex: https://www.rsi.ch/play/ricerca?query=federer%20finale
	 *  Ex: https://www.rtr.ch/play/retschertga?query=Federer%20tennis&mediaType=video
	 */
	if (pathname.endsWith("/suche") || pathname.endsWith("/recherche") || pathname.endsWith("/ricerca") || pathname.endsWith("/retschertga") || pathname.endsWith("/search")) {
		var query = queryParams["query"];
		var mediaType = queryParams["mediaType"];
		if (mediaType) {
			mediaType = mediaType.toLowerCase();
			if (mediaType != "video" && mediaType != "audio") {
				mediaType = null;
			}
		}
		return openSearch(server, bu, query, mediaType);
	}

	/**
	 *  Catch TV topics urls
	 *
	 *  Ex: https://www.rts.ch/play/tv/categories/info
	 */
	if (pathname.endsWith("/tv/themen") || pathname.endsWith("/tv/categories") || pathname.endsWith("/tv/categorie") || pathname.endsWith("/tv/tematicas") || pathname.endsWith("/tv/topics")) {
		return openTvHomePage(server, bu);
	}
	else if (pathname.includes("/tv/themen") || pathname.includes("/tv/categories") || pathname.includes("/tv/categorie") || pathname.includes("/tv/tematicas") || pathname.includes("/tv/topics")) {
		var lastPathComponent = pathname.split("/").slice(-1)[0];

		var topicId = null;

		/* INJECT TVTOPICS OBJECT */

		if (typeof tvTopics !== 'undefined' && lastPathComponent.length > 0) {
			topicId = tvTopics[server][bu][lastPathComponent];
		}

		if (topicId) {
			return openTopic(server, bu, "tv", topicId);
		}
		else {
			return openTvHomePage(server, bu);
		}
	}

	/**
	 *  Catch TV event urls
	 *
	 *  Ex: https://www.srf.ch/play/tv/event/10-jahre-auf-und-davon
	 *. Ex: https://www.rsi.ch/play/tv/event/event-playrsi-8858482
	 */
	if (pathname.endsWith("/tv/event")) {
		return openTvHomePage(server, bu);
	}
	else if (pathname.includes("/tv/event")) {
		var lastPathComponent = pathname.split("/").slice(-1)[0];

		var eventId = null;

		/* INJECT TVEVENTS OBJECT */

		if (typeof tvEvents !== 'undefined' && lastPathComponent.length > 0) {
			eventId = tvEvents[server][bu][lastPathComponent];
		}

		if (eventId) {
			return openModule(server, bu, "event", eventId);
		}
		else {
			return openTvHomePage(server, bu);
		}
	}

	/**
	 *  Catch base play urls
	 *
	 *  Ex: https://www.srf.ch/play/
	 *. Ex: https://www.rsi.ch/play
	 */
	if (pathname.endsWith("/play/") || pathname.endsWith("/play")) {
		return openTvHomePage(server, bu);
	}

	/**
	 *  Catch play help urls
	 *
	 *  Ex: https://www.srf.ch/play/tv/hilfe
	 *  Ex: https://www.srf.ch/play/tv/hilfe/geoblock
	 *  Ex: https://www.rts.ch/play/tv/aide
	 *  Ex: https://www.rsi.ch/play/tv/guida
	 *  Ex: https://www.rtr.ch/play/tv/agid
	 *  Ex: https://play.swissinfo.ch/play/tv/help
	 */
	if (pathname.endsWith("/hilfe") || pathname.includes("/hilfe/") || pathname.endsWith("/aide") || pathname.includes("/aide/") || pathname.endsWith("/guida") || pathname.includes("/guida/") || pathname.endsWith("/agid") || pathname.includes("/agid/") || pathname.endsWith("/help") || pathname.includes("/help/")) {
		return openURL(server, bu, scheme, hostname, pathname, queryParams, anchor);
	}

	// Redirect fallback.
	console.log("Can't parse Play URL. Unsupported URL.");
	return schemeForBu(bu) + "://unsupported?server=" + server;
};

// ---- Open functions

function openMedia(server, bu, mediaType, mediaId, startTime) {
    var urn="urn:" + bu + ":" + mediaType + ":" + mediaId;
    return openMediaURN(server, bu, urn, startTime);
}

function openMediaURN(server, bu, mediaURN, startTime) {
	var options = {};
	if (startTime) {
	    options['start_time'] = startTime;
	}
	if (server) {
	    options['server'] = server;
	}
    return buildBuUri(bu,"media",mediaURN,options);
}

function openShow(server, bu, showTransmission, showId) {
    var showUrn="urn:" + bu + ":show:" + showTransmission + ":" + showId;
    var options = {};
	if (server) {
	    options['server'] = server;
	}
    return buildBuUri(bu,"show",showUrn,options);
}

function openTopic(server, bu, topicTransmission, topicId) {
    var topicUrn="urn:" + bu + ":topic:" + topicTransmission + ":" + topicId;
    var options = {};
	if (server) {
	    options['server'] = server;
	}
    return buildBuUri(bu,"topic",topicUrn,options);
}

function openModule(server, bu, moduleType, moduleId) {
    var topicUrn="urn:" + bu + ":module:" + moduleType + ":" + moduleId;
    var options = {};
	if (server) {
	    options['server'] = server;
	}
    return buildBuUri(bu,"module",topicUrn,options);
}

function openTvHomePage(server,bu){
    var options = {};
    if (server) {
        options['server'] = server;
    }
    return buildBuUri(bu,"home",null,options);
}

function openRadioHomePage(server,bu,channelId){
    if (!channelId) {
        channelId = primaryChannelUidForBu(bu);
    }
    var options={};
    if(channelId){
        options["channel_id"] = channelId;
    }
    if (server) {
        options['server'] = server;
    }
    return buildBuUri(bu,"home",null,options);
}

function openAtoZ(server,bu,channelId,index){
   var options = {};
   if(channelId) {
       options['channel_id'] = channelId;
   }
   if(index) {
        options['index'] = index;
   }
   if (server) {
        options['server'] = server;
   }
   return buildBuUri(bu,"az",null,options);
}

function openRadioAtoZ(server,bu,channelId,index){
    if (!channelId) {
    	channelId = primaryChannelUidForBu(bu);
    }
    return openAtoZ(server,bu,channelId,index);
}

function openByDate(server,bu,channelId,date){
    var options = {};
    if(channelId) {
        options['channel_id'] = channelId;
    }

    if(date) {
            options['date'] = date;
        }
    if (server) {
        options['server'] = server;
    }
    return buildBuUri(bu, "bydate", null, options);
}

function openRadioByDate(server,bu,channelId,date) {
    if (!channelId) {
        channelId = primaryChannelUidForBu(bu);
    }
    return openByDate(server,bu,channelId,date);
}

function openSearch(server, bu, query, mediaType){
    var options = {};
    if(query) {
        options['query'] = query;
    }
    if(mediaType) {
        options['media_type'] = mediaType;
    }
    if (server) {
        options['server'] = server;
    }
    return buildBuUri(bu,"search", null, options);
}

function openURL(server, bu, scheme, hostname, pathname, queryParams, anchor) {
	if (! scheme) {
		scheme = "http";
	}

	var queryParamsString = "";
	if (queryParams) {
		for (var key in queryParams) {
			queryParamsString = queryParamsString + "&" + key + "=" + encodeURIComponent(queryParams[key]);
		}
	}
	if (queryParamsString.length > 0) {
		queryParamsString = queryParamsString.replace('&','?');
	}

	var anchorString = "";
	if (anchor) {
		anchorString = "#" + anchor;
	}

	var url = scheme + "://" + hostname + pathname + queryParamsString + anchorString;
    var options = {};
    options['url'] = url;
    if (server) {
        options['server'] = server;
    }
    return buildBuUri(bu,"link",null,options)
}

// --- parsing functions

function primaryChannelUidForBu(bu) {
	switch (bu) {
		case "srf":
			return "69e8ac16-4327-4af4-b873-fd5cd6e895a7";
			break;
		case "rts":
			return "a9e7621504c6959e35c3ecbe7f6bed0446cdf8da";
			break;
		case "rsi":
			return "rete-uno";
			break;
		case "rtr":
			return "12fb886e-b7aa-4e55-beb2-45dbc619f3c4";
			break;
		default:
			return null;
	}
}

function schemeForBu(bu) {
	switch (bu) {
		case "srf":
			return "playsrf";
			break;
		case "rts":
			return "playrts";
			break;
		case "rsi":
			return "playrsi";
			break;
		case "rtr":
			return "playrtr";
			break;
		case "swi":
			return "playswi";
			break;
		case "mmf":
		case "tp":
			return "letterbox";
			break;
		default:
			return null;
	}
}

function serverForUrl(hostname, pathname, queryParams) {
	var server = "production";
	if (hostname.includes("stage")) {
		server = "stage";
	}
	else if (hostname.includes("test")) {
		server = "test";
	}
	else if (hostname.includes("play-mmf")) {
		if (pathname.startsWith("/mmf/")) {
			server = "play mmf";
		}
		else {
			var serverParam = queryParams["server"];
			switch (serverParam) {
				case "stage":
					server = "stage";
					break;
				case "test":
					server = "test";
					break;
			}
		}
	}
	else if (hostname.includes("play-web")) {
		if (pathname.includes("/stage/play")) {
			server = "stage";
		}
		else if (pathname.includes("/test/play")) {
			server = "test";
		}
	}
	return server;
}

function getBuFromHostname(hostname, pathname) {
    switch (true) {
    	case hostname.endsWith("tp.srgssr.ch") || hostname.endsWith("player.rts.ch") || hostname.endsWith("player.rsi.ch") || hostname.endsWith("player.rtr.ch") || hostname.endsWith("player.swissinfo.ch") || hostname.endsWith("player.srf.ch"):
    		return "tp";
    	case hostname.includes("rts.ch") || hostname.includes("srgplayer-rts") || (hostname.includes("play-mmf") && pathname.startsWith("/rts/")) || (hostname.includes("play-web") && pathname.startsWith("/rts/")):
    		return  "rts";
    	case hostname.includes("rsi.ch") || hostname.includes("srgplayer-rsi") || (hostname.includes("play-mmf") && pathname.startsWith("/rsi/")) || (hostname.includes("play-web") && pathname.startsWith("/rsi/")):
    		return  "rsi";
    	case hostname.includes("rtr.ch") || hostname.includes("srgplayer-rtr") || (hostname.includes("play-mmf") && pathname.startsWith("/rtr/")) || (hostname.includes("play-web") && pathname.startsWith("/rtr/")):
    		return "rtr";
    	case hostname.includes("swissinfo.ch") || hostname.includes("srgplayer-swi") || (hostname.includes("play-mmf") && pathname.startsWith("/swi/")) || (hostname.includes("play-web") && pathname.startsWith("/swi/")):
    		return "swi";
    	case hostname.includes("srf.ch") || hostname.includes("srgplayer-srf") || (hostname.includes("play-mmf") && pathname.startsWith("/srf/")) || (hostname.includes("play-web") && pathname.startsWith("/srf/")):
    		return "srf";
    	case hostname.includes("play-mmf") && pathname.startsWith("/mmf/"):
    		return "mmf";
    	case hostname.includes("radioswisspop.ch") || hostname.includes("radioswissclassic.ch") || hostname.includes("radioswissjazz.ch"):
    		  return "radioswiss";
    }
    return null;
 }

/**
* Build scheme://host[/path][?queryParams[0]&...&queryParams[n-1]]
* Sample:
*   playrts://media/urn:xxx?position=0&server=mmf
*/
function buildUri(scheme, host, path, queryParams) {
    var uri = scheme + "://" + host;
    if (path) {
        uri = uri + "/" + path;
    }
    if (queryParams && queryParams !== {}) {
        uri = uri + "?";
        var optionIndex = 0;
        for (var option in queryParams) {
            if(queryParams[option]) {
               if(optionIndex > 0) {
                    uri = uri + "&";
               }
               uri = uri + option + "=" + encodeURIComponent(queryParams[option]);
               optionIndex++;
            }
        }
    }
    return uri;
}

function buildBuUri(bu, host, path, queryParams) {
    return buildUri(schemeForBu(bu), host, path, queryParams);
}
