#!/bin/bash -e -x

# Requirements:
# brew install imagemagick ghostscript

PYTHON_NIGHTLIES_TAG="---->"
PYTHON_NIGHTLIES_CLOSING_TAG="***********************"

if [ "${CONFIGURATION}" == "AppStore" ]; then
    exit 0
fi

export PATH="${PATH}:/usr/local/bin:/opt/local/bin"

BUSINESS_UNIT=`echo ${PRODUCT_NAME} | sed 's/Play //g'`
SOURCE_IOS_RESOURCES_PATH="${SRCROOT}/Application/Resources/Apps/Play ${BUSINESS_UNIT}/${BUSINESS_UNIT}Resources.xcassets"
SOURCE_IOS_APPICON_PATH="${SOURCE_IOS_RESOURCES_PATH}/AppIcon.appiconset"
DUPLICATE_IOS_APPICON_PATH="${SOURCE_IOS_RESOURCES_PATH}/OriginalAppIcon.appiconset"
SOURCE_TVOS_RESOURCES_PATH="${SRCROOT}/TV Application/Resources/Play ${BUSINESS_UNIT}/${BUSINESS_UNIT}Assets.xcassets"
SOURCE_TVOS_APPICON_PATH="${SOURCE_TVOS_RESOURCES_PATH}/App Icon & Top Shelf Image.brandassets/App Icon.imagestack/Layer 4.imagestacklayer/Content.imageset"
DUPLICATE_TVOS_APPICON_PATH="${SOURCE_TVOS_RESOURCES_PATH}/OriginalAppIcon.appiconset"

echo $PYTHON_NIGHTLIES_TAG "Duplicate original icons..."

cp -fR "${SOURCE_IOS_APPICON_PATH}" "${DUPLICATE_IOS_APPICON_PATH}"
cp -fR "${SOURCE_TVOS_APPICON_PATH}" "${DUPLICATE_TVOS_APPICON_PATH}"

BUNDLE_IDENTIFIER=${PRODUCT_BUNDLE_IDENTIFIER}
BUILD_NUMBER=${CURRENT_PROJECT_VERSION}
VERSION_STRING=${MARKETING_VERSION}

echo $PYTHON_NIGHTLIES_TAG "Version found ${CONFIGURATION}-${VERSION_STRING}-${BUILD_NUMBER}"

echo $PYTHON_NIGHTLIES_TAG "Making ${CONFIGURATION} app icons..."

LAST_RUN_FILE="${SRCROOT}/Scripts/generate-icons-caches/generate-icons-last-run.txt"
CURRENT_RUN="${BUNDLE_IDENTIFIER}-${CONFIGURATION}-${BUILD_NUMBER}"
LAST_RUN=""

if [ -f $LAST_RUN_FILE ]; then
    LAST_RUN=`cat ${LAST_RUN_FILE}`
fi

if [ "$LAST_RUN" == "$CURRENT_RUN" ]; then
    echo $PYTHON_NIGHTLIES_TAG "Last run had same configuration: $CURRENT_RUN. No need to recreate dev/beta icons, except if not created before."
fi

CONTENTS_JSON="${SOURCE_IOS_APPICON_PATH}/Contents.json"

echo "Processing Icons..."
for CONTENTS_JSON in "${SOURCE_IOS_APPICON_PATH}/Contents.json" "${SOURCE_TVOS_APPICON_PATH}/Contents.json";
do
    ICON_COUNT=$(jq -r '.images | length-1' "${CONTENTS_JSON}")
    for i in $(jot - 0 ${ICON_COUNT});
    do
        filename=$(jq -r ".images[${i}] | .filename" "${CONTENTS_JSON}")
        size=$(jq -r ".images[${i}] | .size" "${CONTENTS_JSON}")
        scale=@$(jq -r ".images[${i}] | .scale" "${CONTENTS_JSON}")
        idiom=$(jq -r ".images[${i}] | .idiom" "${CONTENTS_JSON}")

        if [ ${scale} == "@1x" ]; then
           scale=""
        fi
        if [ ${idiom} == "iphone" ]; then
           idiom=""
        fi
        
        if [ ${filename} == "null" ]; then
            continue
        fi

        SOURCE_ICON_FOLDER="${CONTENTS_JSON//Contents.json/}"
        SOURCE_ICON_PATH="${SOURCE_ICON_FOLDER}/${filename}"
        TARGET_ICON_PATH="${SOURCE_ICON_PATH}"

        if [ ! -e "${SOURCE_ICON_PATH}" ]; then
            echo $PYTHON_NIGHTLIES_TAG "warning: App icon not found: ${SOURCE_ICON_PATH}"
            continue
        fi

        SCRIPT_DIR=`dirname $BASH_SOURCE`
        CACHE_APPICON_PATH="${SCRIPT_DIR}/generate-icons-caches"

        if [ ! -e "${CACHE_APPICON_PATH}" ]; then
            mkdir ${CACHE_APPICON_PATH}
        fi

        if [ "${CONFIGURATION}" == "Beta" ]; then
            TITLE="Beta"
        elif [ "${CONFIGURATION}" == "Nightly" ]; then
    	    TITLE="Nightly"
        elif [ "${CONFIGURATION}" == "Debug" ]; then
            TITLE="Debug"
        else
            TITLE="Dev"
        fi

        SCRIPT_ICON_PATH="${CACHE_APPICON_PATH}/${TITLE}-${filename}"

        if [ "$LAST_RUN" != "$CURRENT_RUN" ] || [! -e "${SCRIPT_ICON_PATH}"]; then
            WIDTH=`identify -format %w "${SOURCE_ICON_PATH}"`
            if [ ${idiom} == "tv" ]; then
              HEIGHT=`echo "${WIDTH}/16" | bc`  
            else
              HEIGHT=`echo "${WIDTH}/6" | bc`  
            fi

            if [ "${BUILD_NUMBER}" != "" ]; then
                CAPTION="${TITLE}-${BUILD_NUMBER}"
            else
                CAPTION="${TITLE}"
            fi

            echo $PYTHON_NIGHTLIES_TAG "Making app icon ${CAPTION} | ${filename}"
            convert -background '#0005' -fill white -gravity center -size ${WIDTH}x${HEIGHT} caption:"${CAPTION}" "${SOURCE_ICON_PATH}" +swap -gravity south -composite "${SCRIPT_ICON_PATH}"
        fi

        SOURCE_ICON_PATH="${SCRIPT_ICON_PATH}"
        echo "Copying icon from '${SOURCE_ICON_PATH}' ... "
        echo "... in '${TARGET_ICON_PATH}'"
        cp -f "${SOURCE_ICON_PATH}" "${TARGET_ICON_PATH}"
    done
done

if [ -f $LAST_RUN_FILE ]; then
    rm $LAST_RUN_FILE;
fi

echo $CURRENT_RUN > $LAST_RUN_FILE

echo $PYTHON_NIGHTLIES_TAG "After the compilation, execute 'generate-icons-restore.sh' to restore original app icons."
echo $PYTHON_NIGHTLIES_CLOSING_TAG
exit 0
