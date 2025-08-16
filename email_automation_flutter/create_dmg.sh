#!/bin/bash

# Create DMG installer for Email Automation
APP_NAME="Email Automation"
DMG_NAME="Email_Automation_v1.0.0.dmg"
APP_PATH="build/macos/Build/Products/Release/${APP_NAME}.app"
DMG_PATH="build/macos/Build/Products/Release/${DMG_NAME}"

echo "Creating DMG installer for ${APP_NAME}..."

# Remove existing DMG if it exists
if [ -f "$DMG_PATH" ]; then
    rm "$DMG_PATH"
fi

# Create DMG
create-dmg \
    --volname "${APP_NAME}" \
    --volicon "macos/Runner/Assets.xcassets/AppIcon.appiconset/app_icon_1024.png" \
    --window-pos 200 120 \
    --window-size 600 400 \
    --icon-size 100 \
    --icon "${APP_NAME}.app" 175 120 \
    --hide-extension "${APP_NAME}.app" \
    --app-drop-link 425 120 \
    --no-internet-enable \
    "$DMG_PATH" \
    "$APP_PATH"

echo "DMG created successfully: $DMG_PATH"
echo "Size: $(du -h "$DMG_PATH" | cut -f1)"
