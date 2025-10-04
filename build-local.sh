#!/bin/bash

# LaunchNow Local Build Script
# This script mimics the GitHub Actions build process locally

set -e  # Exit on any error

echo "🚀 LaunchNow Local Build Script"
echo "================================"

# Configuration
SCHEME_NAME="LaunchNow"
CONFIGURATION="Release"
BUILD_DIR="build"

# Clean up previous builds
echo "🧹 Cleaning up previous builds..."
rm -rf "$BUILD_DIR"
mkdir -p "$BUILD_DIR"

# Show Xcode version
echo "🔧 Xcode Information:"
xcodebuild -version
echo ""

# Check project compatibility
echo "📋 Checking project compatibility..."
if xcodebuild -list -project LaunchNow.xcodeproj > /dev/null 2>&1; then
    echo "✅ Project format is compatible with current Xcode"
    xcodebuild -list -project LaunchNow.xcodeproj
else
    echo "❌ Project format incompatibility detected"
    echo "Please ensure you have Xcode 16.0 or later, or downgrade the project format"
    exit 1
fi

echo ""

# Clean build
echo "🧹 Cleaning build folder..."
xcodebuild clean \
    -project LaunchNow.xcodeproj \
    -scheme "$SCHEME_NAME" \
    -configuration "$CONFIGURATION"

echo ""

# Build the app
echo "🔨 Building LaunchNow..."
xcodebuild build \
    -project LaunchNow.xcodeproj \
    -scheme "$SCHEME_NAME" \
    -configuration "$CONFIGURATION" \
    -destination 'platform=macOS' \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO

echo ""

# Create archive
echo "📦 Creating archive..."
xcodebuild archive \
    -project LaunchNow.xcodeproj \
    -scheme "$SCHEME_NAME" \
    -configuration "$CONFIGURATION" \
    -destination 'platform=macOS' \
    -archivePath "$BUILD_DIR/LaunchNow.xcarchive" \
    CODE_SIGN_IDENTITY="" \
    CODE_SIGNING_REQUIRED=NO \
    CODE_SIGNING_ALLOWED=NO

echo ""

# Create app bundle and distribution files
echo "📱 Creating distribution files..."

# Create app bundle directory
mkdir -p "$BUILD_DIR/LaunchNow"

# Copy app from archive
if [ -d "$BUILD_DIR/LaunchNow.xcarchive/Products/Applications/LaunchNow.app" ]; then
    cp -R "$BUILD_DIR/LaunchNow.xcarchive/Products/Applications/LaunchNow.app" "$BUILD_DIR/LaunchNow/"
    echo "✅ App bundle created successfully"
    
    # Create DMG
    echo "💿 Creating DMG..."
    hdiutil create \
        -volname "LaunchNow" \
        -srcfolder "$BUILD_DIR/LaunchNow" \
        -ov -format UDZO \
        "$BUILD_DIR/LaunchNow.dmg"
    echo "✅ DMG created: $BUILD_DIR/LaunchNow.dmg"
    
    # Create ZIP
    echo "🗜️ Creating ZIP..."
    cd "$BUILD_DIR/LaunchNow"
    zip -r "../LaunchNow.zip" . > /dev/null
    cd ../..
    echo "✅ ZIP created: $BUILD_DIR/LaunchNow.zip"
    
else
    echo "❌ App bundle not found in archive"
    echo "Archive contents:"
    ls -la "$BUILD_DIR/LaunchNow.xcarchive/Products/" || echo "Products directory not found"
    exit 1
fi

echo ""
echo "🎉 Build completed successfully!"
echo "📁 Build artifacts:"
echo "   • App: $BUILD_DIR/LaunchNow/LaunchNow.app"
echo "   • DMG: $BUILD_DIR/LaunchNow.dmg"
echo "   • ZIP: $BUILD_DIR/LaunchNow.zip"
echo "   • Archive: $BUILD_DIR/LaunchNow.xcarchive"

# Show file sizes
echo ""
echo "📊 File sizes:"
if [ -f "$BUILD_DIR/LaunchNow.dmg" ]; then
    echo "   DMG: $(du -h "$BUILD_DIR/LaunchNow.dmg" | cut -f1)"
fi
if [ -f "$BUILD_DIR/LaunchNow.zip" ]; then
    echo "   ZIP: $(du -h "$BUILD_DIR/LaunchNow.zip" | cut -f1)"
fi

echo ""
echo "✨ Ready for distribution!"