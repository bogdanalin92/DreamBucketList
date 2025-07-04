#!/bin/bash

# Script to get SHA-256 fingerprint for App Check configuration
# This fingerprint needs to be added to Firebase Console > Project Settings > App Check

echo "Getting debug SHA-256 fingerprint for App Check..."
echo "=============================================="

cd android

# Method 1: Using gradlew signingReport
echo "Method 1: Using gradlew signingReport"
./gradlew signingReport | grep "SHA256"

echo ""
echo "Method 2: Using keytool directly on debug keystore"
# Method 2: Direct keytool access to debug keystore
DEBUG_KEYSTORE="$HOME/.android/debug.keystore"

if [ -f "$DEBUG_KEYSTORE" ]; then
    echo "Debug keystore found at: $DEBUG_KEYSTORE"
    keytool -list -v -keystore "$DEBUG_KEYSTORE" -alias androiddebugkey -storepass android -keypass android | grep "SHA256"
else
    echo "Debug keystore not found at default location"
fi

echo ""
echo "Instructions:"
echo "1. Copy the SHA256 fingerprint from above"
echo "2. Go to Firebase Console > Project Settings > App Check"
echo "3. Click on your Android app"
echo "4. Add the SHA256 fingerprint to the Play Integrity configuration"
echo "5. Make sure App Check is enabled for Firestore in Firebase Console"
