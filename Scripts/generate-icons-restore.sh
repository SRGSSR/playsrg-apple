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
SOURCE_RESOURCES_PATH="${SRCROOT}/Application/Resources/Apps/Play ${BUSINESS_UNIT}/${BUSINESS_UNIT}Resources.xcassets"
SOURCE_APPICON_PATH="${SOURCE_RESOURCES_PATH}/AppIcon.appiconset"
DUPLICATE_APPICON_PATH="${SOURCE_RESOURCES_PATH}/OriginalAppIcon.appiconset"

echo $PYTHON_NIGHTLIES_TAG "Restore original app icons..."

if [ ! -e "${DUPLICATE_APPICON_PATH}" ]; then
    echo $PYTHON_NIGHTLIES_TAG "Original app icons not found."
    exit 0
fi

rm -fR "${SOURCE_APPICON_PATH}"
mv "${DUPLICATE_APPICON_PATH}" "${SOURCE_APPICON_PATH}"

echo $PYTHON_NIGHTLIES_TAG "Original icons Restored."

exit 0
