#!/bin/bash -e

while getopts t: OPT; do
    case "$OPT" in
        t)
            APP_CENTER_TOKEN="$OPTARG"
            ;;
        \?)
            usage
            exit 1
            ;;
    esac
done
shift $((OPTIND-1))

if [ -z "${APP_CENTER_TOKEN}" ]; then
	echo "Missing App Center API token. Use -t to specify."
	exit 1
fi

BUILD_NUMBER=0

for APP_SECRET; do
    APP_BUILD_NUMBER=`curl --silent --header "X-API-Token: ${APP_CENTER_TOKEN}" "https://api.appcenter.ms/v0.1/sdk/apps/${APP_SECRET}/releases/latest" | jq ".version | tonumber" 2> /dev/null`
    if [ "${APP_BUILD_NUMBER}" -gt "${BUILD_NUMBER}" ]; then
        BUILD_NUMBER=${APP_BUILD_NUMBER}
    fi
done

export APP_CENTER_BUILD_NUMBER=${BUILD_NUMBER}
echo ${BUILD_NUMBER}

