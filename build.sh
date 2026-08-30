#!/usr/bin/env bash
set -e

APP_NAME="Time Sayer"
BUNDLE_NAME="${APP_NAME}.app"

echo "🔨 Compiling ${APP_NAME}..."
mkdir -p .build/cache
mkdir -p "${BUNDLE_NAME}/Contents/MacOS"
mkdir -p "${BUNDLE_NAME}/Contents/Resources"

swiftc \
    -module-cache-path .build/cache \
    -O \
    -o "${BUNDLE_NAME}/Contents/MacOS/TimeSayer" \
    Sources/TimeSayer/*.swift \
    -framework Cocoa \
    -framework AVFoundation \
    -framework Carbon

chmod +x "${BUNDLE_NAME}/Contents/MacOS/TimeSayer"

if [ -f "Resources/AppIcon.icns" ]; then
    cp "Resources/AppIcon.icns" "${BUNDLE_NAME}/Contents/Resources/AppIcon.icns"
fi

echo "📦 Generating Info.plist..."
cat <<EOF > "${BUNDLE_NAME}/Contents/Info.plist"
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
    <key>CFBundleExecutable</key>
    <string>TimeSayer</string>
    <key>CFBundleIdentifier</key>
    <string>com.harrison.TimeSayer</string>
    <key>CFBundleName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleDisplayName</key>
    <string>${APP_NAME}</string>
    <key>CFBundleIconFile</key>
    <string>AppIcon</string>
    <key>CFBundlePackageType</key>
    <string>APPL</string>
    <key>CFBundleShortVersionString</key>
    <string>1.0.0</string>
    <key>CFBundleVersion</key>
    <string>1</string>
    <key>LSMinimumSystemVersion</key>
    <string>13.0</string>
    <key>LSUIElement</key>
    <true/>
    <key>NSHighResolutionCapable</key>
    <true/>
    <key>NSSupportsAutomaticGraphicsSwitching</key>
    <true/>
    <key>NSPrincipalClass</key>
    <string>NSApplication</string>
</dict>
</plist>
EOF

echo "✅ Successfully built ${BUNDLE_NAME}!"
echo ""
echo "To launch Time Sayer now, run:"
echo "  open \"${BUNDLE_NAME}\""
echo ""
echo "To install to Applications, run:"
echo "  cp -R \"${BUNDLE_NAME}\" /Applications/"
