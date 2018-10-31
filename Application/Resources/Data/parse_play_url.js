// parsePlayUrl v0.1

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

    // Get BU
    var bu = null;
    switch (true) {
    case hostname.includes("rts.ch") || hostname.includes("srgplayer-rts") || (hostname.includes("play-mmf") && pathname.startsWith("/rts/play/")):
        bu = "rts";
        break;
    case hostname.includes("rsi.ch") || hostname.includes("srgplayer-rsi"):
        bu = "rsi";
        break;
    case hostname.includes("rtr.ch") || hostname.includes("srgplayer-rtr"):
        bu = "rtr";
        break;
    case hostname.includes("swissinfo.ch") || hostname.includes("srgplayer-swi"):
        bu = "swi";
        break;
    case hostname.includes("srf.ch") || hostname.includes("srgplayer-srf"):
        bu = "srf";
        break;
    }

    if (! bu) {
        console.log("No known SRG BU hostname.");
        return null;
    }

    if (hostname.includes("play-mmf")) {
        pathname = pathname.substring(4);
    }

    /**
     *  Catch special case: shared RTS media urls built by RTS MAM.
     *
     *  Ex: https://www.rts.ch/video/emissions/signes/9901229-la-route-de-lexil-en-langue-des-signes.html
     */
     if (bu == "rts" && (pathname.startsWith("/video/") || pathname.startsWith("/audio/")) && pathname.endsWith(".html")) {
        var lastPath = pathname.substr(pathname.lastIndexOf('/') + 1);
        var mediaId = lastPath.split('.')[0].split('-')[0];
        if (mediaId) {
            var mediaType = (pathname.startsWith("/video/")) ? "video" : "audio";
            return openMedia(bu, mediaType, mediaId, null);
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
            // TODO: returns TV homepage
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
            // TODO: returns default homepage
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

    // Redirect fallback.
    console.log("Can't parse Play URL. Redirect.");
    return schemeForBu(bu) + "://redirect";
};

var openMedia = function(bu, mediaType, mediaId, startTime) {
  var redirect = schemeForBu(bu) + "://open?media=urn:" + bu + ":" + mediaType + ":" + mediaId;
  if (startTime) {
    redirect = redirect + "&startTime=" + startTime;
  }
  return redirect;
};

var openShow = function(bu, showTransmission, showId) {
  var redirect = schemeForBu(bu) + "://open?show=urn:" + bu + ":show:" + showTransmission + ":" + showId;
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
