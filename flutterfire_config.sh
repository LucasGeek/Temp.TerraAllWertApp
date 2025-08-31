#!/bin/bash
# Script to generate Firebase configuration files for different environments/flavors
# Feel free to reuse and adapt this script for your own projects

if [[ $# -eq 0 ]]; then
    echo "Error: No environment specified. Use 'dev', 'stg', or 'prd'."
    exit 1
fi

case $1 in
    dev)
        flutterfire config \
        --project=terra_allwert-dev \
        --out=lib/firebase_options_dev.dart \
        --ios-bundle-id=com.terraallwert.app.dev \
        --ios-out=ios/Flavors/dev/GoogleService-Info.plist \
        --android-package-name=com.terraallwert.app.dev \
        --android-out=android/app/src/dev/google-services.json
    ;;
    stg)
        flutterfire config \
        --project=terra_allwert-stg \
        --out=lib/firebase_options_stg.dart \
        --ios-bundle-id=com.terraallwert.app.stg \
        --ios-out=ios/Flavors/stg/GoogleService-Info.plist \
        --android-package-name=com.terraallwert.app.stg \
        --android-out=android/app/src/stg/google-services.json
    ;;
    prd)
        flutterfire config \
        --project=terra_allwert-prd \
        --out=lib/firebase_options_prd.dart \
        --ios-bundle-id=com.terraallwert.app \
        --ios-out=ios/Flavors/prd/GoogleService-Info.plist \
        --android-package-name=com.terraallwert.app \
        --android-out=android/app/src/prd/google-services.json
    ;;
    *)
        echo "Error: Invalid environment specified. Use 'dev', 'stg', or 'prd'."
        exit 1
    ;;
esac