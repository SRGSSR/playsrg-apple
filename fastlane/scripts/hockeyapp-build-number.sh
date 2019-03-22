#!/bin/bash -e

while getopts t: OPT; do
    case "$OPT" in
        t)
            HOCKEY_TOKEN="$OPTARG"
            ;;
        \?)
            usage
            exit 1
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${HOCKEY_TOKEN}" ]; then
	echo "Missing Hockey API token. Use -t to specify."
	exit 1
fi

BUILD_NUMBER=0

for APP_ID; do
    APP_BUILD_NUMBER=`curl --silent --header "X-HockeyAppToken: ${HOCKEY_TOKEN}" "https://rink.hockeyapp.net/api/2/apps/${APP_ID}/app_versions?format=xml" | xpath "/response/app-versions/app-version[status = 2 or status = 1][1]/version/text()" 2> /dev/null`
    if [ "${APP_BUILD_NUMBER}" -gt "${BUILD_NUMBER}" ]; then
        BUILD_NUMBER=${APP_BUILD_NUMBER}
    fi
done

export HOCKEY_APP_BUILD_NUMBER=${BUILD_NUMBER}
echo "${BUILD_NUMBER}"

