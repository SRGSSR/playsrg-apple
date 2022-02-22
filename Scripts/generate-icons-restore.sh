#!/usr/bin/env bash

if [ "${CONFIGURATION}" == "AppStore" ] || [ "${CONFIGURATION}" == "Debug" ] || [ "${ENABLE_PREVIEWS}" == "YES" ]; then
    exit 0
fi

export PATH="${PATH}:/usr/local/bin:/opt/local/bin"

BUSINESS_UNIT="${PRODUCT_NAME//Play /}"
SOURCE_IOS_RESOURCES_PATH="${SRCROOT}/Application/Resources/Apps/Play ${BUSINESS_UNIT}/${BUSINESS_UNIT}Resources.xcassets"
SOURCE_IOS_APPICON_PATH="${SOURCE_IOS_RESOURCES_PATH}/AppIcon.appiconset"
DUPLICATE_IOS_APPICON_PATH="${SRCROOT}/OriginalAppIcon.appiconset"
SOURCE_TVOS_RESOURCES_PATH="${SRCROOT}/TV Application/Resources/Play ${BUSINESS_UNIT}/${BUSINESS_UNIT}Assets.xcassets"
SOURCE_TVOS_APPICON_PATH="${SOURCE_TVOS_RESOURCES_PATH}/App Icon & Top Shelf Image.brandassets/App Icon.imagestack/Layer 4.imagestacklayer/Content.imageset"
DUPLICATE_TVOS_APPICON_PATH="${SRCROOT}/OriginalTVAppIcon.appiconset"
SOURCE_TVOS_APPSTOREICON_PATH="${SOURCE_TVOS_RESOURCES_PATH}/App Icon & Top Shelf Image.brandassets/App Icon - App Store.imagestack/Layer 4.imagestacklayer/Content.imageset"
DUPLICATE_TVOS_APPSTOREICON_PATH="${SRCROOT}/OriginalAppStoreTVIcon.appiconset"

echo "Restore original iOS app icons..."

if [ ! -e "${DUPLICATE_IOS_APPICON_PATH}" ]; then
    echo "Original iOS app icons not found."
    exit 0
fi

rm -fR "${SOURCE_IOS_APPICON_PATH}"
mv "${DUPLICATE_IOS_APPICON_PATH}" "${SOURCE_IOS_APPICON_PATH}"

echo "Original iOS app icons restored."

echo "Restore original tvOS app icons..."

if [ ! -e "${DUPLICATE_TVOS_APPICON_PATH}" ]; then
    echo "Original tvOS app icons not found."
    exit 0
fi

rm -fR "${SOURCE_TVOS_APPICON_PATH}"
mv "${DUPLICATE_TVOS_APPICON_PATH}" "${SOURCE_TVOS_APPICON_PATH}"

echo "Original tvOS app icons restored."

echo "Restore original tvOS AppStore icons..."

if [ ! -e "${DUPLICATE_TVOS_APPSTOREICON_PATH}" ]; then
    echo "Original tvOS AppStore icons not found."
    exit 0
fi

rm -fR "${SOURCE_TVOS_APPSTOREICON_PATH}"
mv "${DUPLICATE_TVOS_APPSTOREICON_PATH}" "${SOURCE_TVOS_APPSTOREICON_PATH}"

echo "Original tvOS AppStore icons restored."
exit 0
