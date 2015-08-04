#!/bin/sh
#
#  xcode_build_dsym_upload.sh
#
#  Copyright (c) 2014 AppDynamics Inc. All rights reserved.
#
#  Documentation: Please refer to AppDynamics Inc. documentation of how to use this script inside Xcode.
#

# These values can be set externally if you wish to change the defaults
ADRUM_UPLOAD_WHEN_BUILT_FOR_SIMULATOR=${ADRUM_UPLOAD_WHEN_BUILT_FOR_SIMULATOR:=1}
ADRUM_TREAT_UPLOAD_FAILURES_AS_ERRORS=${ADRUM_TREAT_UPLOAD_FAILURES_AS_ERRORS:=1}
ADRUM_EUM_PROCESSOR=${ADRUM_EUM_PROCESSOR:="https://api.eum-appdynamics.com"}

# Script starts here

# Helper functions
echoMessageAndExitWithCode() {
    echo "${1}"
    exit ${2}
}

rawurlencode() {
    local string="${1}"
    local strlen=${#string}
    local encoded=""

    for (( pos=0 ; pos<strlen ; pos++ )); do
        c=${string:$pos:1}
        case "$c" in
            [-_.~a-zA-Z0-9] ) o="${c}" ;;
            * )               printf -v o '%%%02x' "'$c"
        esac
        encoded+="${o}"
    done
    echo "${encoded}"
}


echo "Uploading dSYM to AppDynamics EUM Processor"
echo ""

# Check to make sure the necessary parameters are defined
if [ ! "${ADRUM_ACCOUNT_NAME}" ]; then
    echoMessageAndExitWithCode "error: ADRUM_ACCOUNT_NAME is not defined." 1
fi

if [ ! "${ADRUM_LICENSE_KEY}" ]; then
    echoMessageAndExitWithCode "error: ADRUM_LICENSE_KEY is not defined." 1
fi

# Print product information
BUNDLE_VERSION=$(/usr/libexec/PlistBuddy -c 'Print CFBundleVersion' ${INFOPLIST_FILE})
BUNDLE_SHORT_VERSION=$(/usr/libexec/PlistBuddy -c 'Print CFBundleShortVersionString' ${INFOPLIST_FILE})

echo "Product Name: ${PRODUCT_NAME}"
echo "Product Version: ${BUNDLE_SHORT_VERSION}"
echo "Product Build: ${BUNDLE_VERSION}"

# Print AppDynamics information
echo "AppDynamics EUM Account Name: ${ADRUM_ACCOUNT_NAME}"
echo "AppDynamics EUM License Key: ${ADRUM_LICENSE_KEY}"
echo "AppDynamics EUM Processor: ${ADRUM_EUM_PROCESSOR}"

# Check if this is a simulator build
if [ "$EFFECTIVE_PLATFORM_NAME" == "-iphonesimulator" ]; then
if [ $ADRUM_UPLOAD_WHEN_BUILT_FOR_SIMULATOR -eq 0 ]; then
    echoMessageAndExitWithCode "info: simulator build - ADRUM_UPLOAD_WHEN_BUILT_FOR_SIMULATOR is 0 (false). Skipping upload" 0
fi
fi

DSYM_SOURCE=${DWARF_DSYM_FOLDER_PATH}/${DWARF_DSYM_FILE_NAME}
DSYM_ZIP_PATH="$TMPDIR$DWARF_DSYM_FILE_NAME.zip"

# create dSYM .zip file
echo "dSYM file location: ${DSYM_SOURCE}"
if [ ! -d "$DSYM_SOURCE" ]; then
    echoMessageAndExitWithCode "error: dSYM file not found at: ${DSYM_SOURCE}" 1
fi

NOW=$(date +"%T")

echo "Time: ${NOW}. Compressing dSYM to: ${DSYM_ZIP_PATH} ..."
(zip --recurse-paths --quiet "${DSYM_ZIP_PATH}" "${DSYM_SOURCE}") || echoMessageAndExitWithCode "error: failed to create compressed dSYM file" "$?"
echo ""
NOW=$(date +"%T")
echo "Time: ${NOW}. Successfully compressed dSYM to: ${DSYM_ZIP_PATH}"

# Upload dSYM to AppDynamics Collector
URI="/eumaggregator/crash-reports/iOSDSym"
URL=${ADRUM_EUM_PROCESSOR}${URI}
NOW=$(date +"%T")
echo "Time ${NOW}. Started uploading dSYM to AppDynamics EUM Processor. URL: ${URL}..."

ACCOUNT_NAME_ENCODED=$( rawurlencode "${ADRUM_ACCOUNT_NAME}" )
ADRUM_LICENSE_KEY_ENCODED=$( rawurlencode "${ADRUM_LICENSE_KEY}" )

HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" --upload-file "${DSYM_ZIP_PATH}" --user "${ACCOUNT_NAME_ENCODED}:${ADRUM_LICENSE_KEY_ENCODED}" "${URL}")
CURL_STATUS=$?
NOW=$(date +"%T")
echo "Time ${NOW}. Upload attempt completed. curl return code: ${CURL_STATUS}"

if [ $CURL_STATUS -eq 0 ]; then
    echo "HTTP Status Code: ${HTTP_STATUS}"
fi

# Remove tempopary dSYM archive
echo "Deleting temporary dSYM archive: ${DSYM_ZIP_PATH}"
rm -f "${DSYM_ZIP_PATH}"

if [ $HTTP_STATUS -ne 200 -o $CURL_STATUS -ne 0 ]; then
if [ $ADRUM_TREAT_UPLOAD_FAILURES_AS_ERRORS -eq 1 ]; then
    MESSAGE=$(printf "error: dSYM archive upload failed\nTo ignore this condition and build succesfully, add:\nADRUM_TREAT_UPLOAD_FAILURES_AS_ERRORS=0\nto the environment before invoking this script")
    echoMessageAndExitWithCode "${MESSAGE}" 1
else
    echo echoMessageAndExitWithCode "warning: dSYM archive upload failed, but ingnored due to ADRUM_TREAT_UPLOAD_FAILURES_AS_ERRORS=0" 0
fi
else
    echo echoMessageAndExitWithCode "dSYM uploaded sucessfully to AppDynamics EUM Processor" 0
fi
