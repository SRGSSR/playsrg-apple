// parse_play_url

var parsePlayUrlVersion = "v1.0-dev10";
var parsePlayUrlBuild = "36147C9F3282C77C9A14AA1C29BB847B6C4D1294";
var parsePlayUrlBuildDate = "2019-05-05 18:17:42";

var parsePlayUrl = function(urlString) {
    var url = urlString;
    try {
        url = new URL(urlString);
    }
    catch(error) {
        console.log("Can't read URL: " + error);
        return null;
    }

    var queryParams = {};
    for (let queryItem of url.searchParams) {
        queryParams[queryItem[0]] = queryItem[1];
    }

    return parseForPlayApp(url.hostname, url.pathname, queryParams, url.hash);
}


var parseForPlayApp = function(hostname, pathname, queryParams, anchor) {

    // fix path issue
    pathname = pathname.replace("//", "/");

    // Get BU
    var bu = null;
    switch (true) {
    case hostname.includes("rts.ch") || hostname.includes("srgplayer-rts") || (hostname.includes("play-mmf") && pathname.startsWith("/rts/")):
        bu = "rts";
        break;
    case hostname.includes("rsi.ch") || hostname.includes("srgplayer-rsi") || (hostname.includes("play-mmf") && pathname.startsWith("/rsi/")):
        bu = "rsi";
        break;
    case hostname.includes("rtr.ch") || hostname.includes("srgplayer-rtr") || (hostname.includes("play-mmf") && pathname.startsWith("/rtr/")):
        bu = "rtr";
        break;
    case hostname.includes("swissinfo.ch") || hostname.includes("srgplayer-swi") || (hostname.includes("play-mmf") && pathname.startsWith("/swi/")):
        bu = "swi";
        break;
    case hostname.includes("srf.ch") || hostname.includes("srgplayer-srf") || (hostname.includes("play-mmf") && pathname.startsWith("/srf/")):
        bu = "srf";
        break;
    }

    if (! bu) {
        console.log("This hostname URL is not part of Play SRG URLs.");
        return null;
    }

    if (hostname.includes("play-mmf")) {
        pathname = pathname.substring(4);
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
                return openMedia(bu, mediaType, mediaId, null);
            }
        else if (pathname.startsWith("/video")) {
            // Returns default TV homepage
            return openPage(bu, "tv:home", null, null);
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
            return openPage(bu, "radio:home", channelId, null);
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
        var mediaId = queryParams["id"];
        if (mediaId) {
            var startTime = queryParams["startTime"];            
            return openMedia(bu, mediaType, mediaId, startTime);
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
            return openMedia(bu, mediaType, mediaId, startTime);
        }
        else {
            mediaType = null;
        }
    }

    /**
     *  Catch live TV urls
     *
     *  Ex: https://www.srf.ch/play/tv/live?tvLiveId=c49c1d73-2f70-0001-138a-15e0c4ccd3d0
     */
    if (pathname.endsWith("/tv/live") || pathname.endsWith("/tv/direct")) {
        var mediaId = queryParams["tvLiveId"];
        if (mediaId) {
            return openMedia(bu, "video", mediaId, null);
        }
        else {
            // Returns default TV homepage
            return openPage(bu, "tv:home", null, null);
        }
    }

    /**
     *  Catch live radio urls
     *
     *  Ex: https://www.rsi.ch/play/radio/livepopup/rete-uno
     */
    if (pathname.includes("/radio/livepopup/")) {
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
            return openMedia(mediaBu, "audio", mediaId, null);
        }
        else {
            // Returns default radio homepage
            return openPage(bu, "radio:home", null, null);
        }
    }

    /**
     *  Catch live tv popup urls
     *
     *  Ex: https://www.srf.ch/play/tv/popupvideoplayer?id=b833a5af-63c6-4310-bb80-05341310a4f5
     */
    if (pathname.includes("/tv/popupvideoplayer")) {
        var mediaId = queryParams["id"];
        if (mediaId) {
            return openMedia(bu, "video", mediaId, null);
        }
        else {
            // Returns default TV homepage
            return openPage(bu, "tv:home", null, null);
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
            return openShow(bu, showTransmission, showId);
        }
        else {
            showTransmission = null;
        }
    }

    /**
     *  Catch redirect show urls
     *
     *  Ex: https://www.rts.ch/play/tv/quicklink/6176
     */
    switch (true) {
    case pathname.includes("/tv/quicklink/"):
        showTransmission = "tv";
        break;
    case pathname.includes("/radio/quicklink/"):
        showTransmission = "radio";
        break;
    }

    if (showTransmission) {
        var showId = pathname.substr(pathname.lastIndexOf('/') + 1);
        if (showId) {
            return openShow(bu, showTransmission, showId);
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
        return openPage(bu, "tv:home", null, null);
    }

    /**
     *  Catch home radio urls
     *
     *  Ex: https://www.srf.ch/play/radio?station=ee1fb348-2b6a-4958-9aac-ec6c87e190da
     */
    if (pathname.endsWith("/radio")) {
        var channelId = queryParams["station"];
        return openPage(bu, "radio:home", channelId, null);
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
        var options = new Array( { key: "index", value: index } );
        return openPage(bu, "tv:az", null, options);
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
        var options = new Array( { key: "index", value: index } );
        return openPage(bu, "radio:az", channelId, options);
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
        var options = new Array( { key: "date", value: date } );
        return openPage(bu, "tv:bydate", null, options);
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
        var options = new Array( { key: "date", value: date } );
        return openPage(bu, "radio:bydate", channelId, options);
    }

    /**
     *  Catch search urls
     *
     *  Ex: https://www.rsi.ch/play/ricerca?query=federer%20finale
     *
     *  Ex: https://www.rtr.ch/play/tv/retschertga?query=federer%2520tennis
     *  Ex: https://www.rtr.ch/play/tv/retschertga?query=federer%2520tennis#radio
     *  Ex: https://www.rtr.ch/play/radio/retschertga?query=federer%2520tennis
     *  Ex: https://www.rtr.ch/play/radio/retschertga?query=federer%2520tennis#tv
     */
    if (pathname.endsWith("/suche") || pathname.endsWith("/recherche") || pathname.endsWith("/ricerca") || pathname.endsWith("/retschertga") || pathname.endsWith("/search")) {
        var query = queryParams["query"];
        var mediaType = queryParams["mediaType"];
        var transmission = null;
        if (pathname.includes("/tv/")) {
            transmission = "tv";
            query = decodeURIComponent(query);
            if (anchor == "#radio") {
                transmission = "radio";
            }
        }
        else if (pathname.includes("/radio/")) {
            transmission = "radio";
            query = decodeURIComponent(query);
            if (anchor == "#tv") {
                transmission = "tv";
            }
        }
        if (mediaType) {
            mediaType = mediaType.toLowerCase();
            if (mediaType != "video" && mediaType != "audio") {
                mediaType = null;
            }
        }
        var transmissionComponent = (transmission != null) ? transmission + ":" : "";
        var options = new Array( { key: "query", value: query }, { key: "mediaType", value: mediaType } );
        return openPage(bu, transmissionComponent + "search", null, options);
    }

    /**
     *  Catch TV topics urls
     *
     *  Ex: https://www.rts.ch/play/tv/categories/info
     */
    if (pathname.endsWith("/tv/themen") || pathname.endsWith("/tv/categories") || pathname.endsWith("/tv/categorie") || pathname.endsWith("/tv/tematicas") || pathname.endsWith("/tv/topics")) {
        return openPage(bu, "tv:home", null, null);
    }
    if (pathname.includes("/tv/themen") || pathname.includes("/tv/categories") || pathname.includes("/tv/categorie") || pathname.includes("/tv/tematicas") || pathname.includes("/tv/topics")) {
        var lastPathComponent = pathname.split("/").slice(-1)[0]; 

        var topicId = null;

        var tvTopics = {"rts":{"documentaires":"623","series":"1353","tataki":"54537","prime-time":"47040","sport":"1095","info":"1081","kids":"2743","webcreation":"45703"},"rtr":{"uffants":"dfb7ae6d-cb73-431b-a817-b1663ec2f58a","battaporta":"2d48ba80-566c-4359-9e8d-8d9b2d570e0a","rtr-social":"50bb90d6-41af-4bbd-b92c-6ef5db16a9b3","archiv":"c50140e7-5740-4c44-abd0-0f7d9ea68da7","actualitad":"20e7478f-1ea1-49c3-81c2-5f157d6ff092","cuntrasts":"7d7f21be-6727-4939-9126-5bca25eb3a49"},"swi":{"politics":"4","society":"6","business":"1","sci--tech":"5","culture":"2"},"srf":{"news":"a709c610-b275-4c0c-a496-cba304c36712","wissen--ratgeber":"b58dcf14-96ac-4046-8676-fd8a942c0e88","dokumentationen":"516421f0-ec89-43ba-823b-1b5ceec262f3","audiodeskription":"4acf86dd-7ff7-45d3-baf8-33375340d976","religion":"9a79b1de-cde8-4528-b304-d1ae1363f52f","kinder":"1d7d9cfb-6682-4d5b-9e36-322e8fa93c03","filme--serien":"fa793c13-bebc-41b9-9710-bf8a34192c15","kultur":"882cb264-cf81-4a9c-b660-d42519b7ce28","gesellschaft":"63f937e4-859e-42c4-a430-bdb74dd09645","sport":"649e36d7-ff57-41c8-9c1b-7892daf15e78","unterhaltung":"641223fa-f112-4d98-8aec-cb22262a1182","politik":"bb7b21e0-1056-4e28-bac3-c610393b5b0f","jugend":"a2d97206-0b85-4226-8afe-06e86ebd05b2","gebaerdensprache":"593eb926-d892-41ba-8b1f-eccbcfd7f15f"},"rsi":{"news":"7","giovani":"5","film-e-telefilm":"3","la-tua-storia":"1","quiz-e-tempo-libero":"4","musica":"100","oltre-la-tv":"9","sport":"8","documentari":"40","kids":"11"}}

        if (typeof tvTopics !== 'undefined' && lastPathComponent.length > 0) {
            topicId = tvTopics[bu][lastPathComponent];
        }

        if (topicId) {
            return openTopic(bu, "tv", topicId);
        }
        else {
            return openPage(bu, "tv:home", null, null);
        }
    }

    /**
     *  Catch TV event urls
     *
     *  Ex: https://www.srf.ch/play/tv/event/10-jahre-auf-und-davon
     *. Ex: https://www.rsi.ch/play/tv/event/event-playrsi-8858482
     */
    if (pathname.endsWith("/tv/event")) {
        return openPage(bu, "tv:home", null, null);
    }
    if (pathname.includes("/tv/event")) {
        var lastPathComponent = pathname.split("/").slice(-1)[0]; 

        var eventId = null;

        var tvEvents = {"rts":{"srie-kiri":"e9160b41-2aca-4513-9bee-0a20a522169f"},"rtr":{"discussiun-al-podium-iniziativa-da-chatscha":"ffe45473-250c-4694-9307-23313da7ee0c"},"swi":{},"srf":{"der-schoene-schein":"b12ec594-0e1d-4a0a-af8e-ed95960e83b2"},"rsi":{}}

        if (typeof tvEvents !== 'undefined' && lastPathComponent.length > 0) {
            eventId = tvEvents[bu][lastPathComponent];
        }

        if (eventId) {
            return openModule(bu, "event", eventId);
        }
        else {
            return openPage(bu, "tv:home", null, null);
        }
    }

    // Redirect fallback.
    console.log("Can't parse Play URL. Redirect.");
    return schemeForBu(bu) + "://redirect";
};

var openMedia = function(bu, mediaType, mediaId, startTime) {
  var redirect = schemeForBu(bu) + "://open?media=urn:" + bu + ":" + mediaType + ":" + mediaId;
  if (startTime) {
    redirect = redirect + "&start-time=" + startTime;
  }
  return redirect;
};

var openShow = function(bu, showTransmission, showId) {
  var redirect = schemeForBu(bu) + "://open?show=urn:" + bu + ":show:" + showTransmission + ":" + showId;
  return redirect;
};

var openTopic = function(bu, topicTransmission, topicId) {
  var redirect = schemeForBu(bu) + "://open?topic=urn:" + bu + ":topic:" + topicTransmission + ":" + topicId;
  return redirect;
};

var openModule = function(bu, moduleType, moduleId) {
  var redirect = schemeForBu(bu) + "://open?module=urn:" + bu + ":module:" + moduleType + ":" + moduleId;
  return redirect;
};

var openPage = function(bu, page, channelId, options) {
    if (! page) {
        page = "tv:home";
    }
    
    var redirect = schemeForBu(bu) + "://open?page=urn:" + bu + ":page:" + page;
    if (channelId) {
        redirect = redirect + "&channel-id=" + channelId;
    }
    if (options && Array.isArray(options)) {
        options.forEach(function(option) {
            if (option.key && option.value) {
                redirect = redirect + "&" + option.key + "=" + encodeURIComponent(option.value);
            }
        });
    }
    return redirect;
};

var schemeForBu = function(bu) {
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
    default:
        return null;
  }
};
