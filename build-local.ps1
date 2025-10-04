# LaunchNow Local Build Script (PowerShell)
# This script mimics the GitHub Actions build process locally on Windows/PowerShell

$ErrorActionPreference = "Stop"

Write-Host "🚀 LaunchNow Local Build Script" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green

# Configuration
$SCHEME_NAME = "LaunchNow"
$CONFIGURATION = "Release"
$BUILD_DIR = "build"

# Clean up previous builds
Write-Host "🧹 Cleaning up previous builds..." -ForegroundColor Yellow
if (Test-Path $BUILD_DIR) {
    Remove-Item -Recurse -Force $BUILD_DIR
}
New-Item -ItemType Directory -Path $BUILD_DIR | Out-Null

# Show Xcode version (if on macOS with Xcode)
Write-Host "🔧 Xcode Information:" -ForegroundColor Cyan
try {
    xcodebuild -version
    Write-Host ""
} catch {
    Write-Host "❌ Xcode not found or not available in this environment" -ForegroundColor Red
    Write-Host "This script is designed for macOS with Xcode installed" -ForegroundColor Red
    exit 1
}

# Check project compatibility
Write-Host "📋 Checking project compatibility..." -ForegroundColor Cyan
try {
    $output = xcodebuild -list -project LaunchNow.xcodeproj 2>&1
    if ($LASTEXITCODE -eq 0) {
        Write-Host "✅ Project format is compatible with current Xcode" -ForegroundColor Green
        Write-Host $output
    } else {
        throw "Project incompatible"
    }
} catch {
    Write-Host "❌ Project format incompatibility detected" -ForegroundColor Red
    Write-Host "Please ensure you have Xcode 16.0 or later, or downgrade the project format" -ForegroundColor Red
    exit 1
}

Write-Host ""

# Clean build
Write-Host "🧹 Cleaning build folder..." -ForegroundColor Yellow
xcodebuild clean -project LaunchNow.xcodeproj -scheme $SCHEME_NAME -configuration $CONFIGURATION

Write-Host ""

# Build the app
Write-Host "🔨 Building LaunchNow..." -ForegroundColor Cyan
xcodebuild build `
    -project LaunchNow.xcodeproj `
    -scheme $SCHEME_NAME `
    -configuration $CONFIGURATION `
    -destination 'platform=macOS' `
    CODE_SIGN_IDENTITY="" `
    CODE_SIGNING_REQUIRED=NO `
    CODE_SIGNING_ALLOWED=NO

Write-Host ""

# Create archive
Write-Host "📦 Creating archive..." -ForegroundColor Cyan
xcodebuild archive `
    -project LaunchNow.xcodeproj `
    -scheme $SCHEME_NAME `
    -configuration $CONFIGURATION `
    -destination 'platform=macOS' `
    -archivePath "$BUILD_DIR/LaunchNow.xcarchive" `
    CODE_SIGN_IDENTITY="" `
    CODE_SIGNING_REQUIRED=NO `
    CODE_SIGNING_ALLOWED=NO

Write-Host ""

# Create app bundle and distribution files
Write-Host "📱 Creating distribution files..." -ForegroundColor Cyan

# Create app bundle directory
New-Item -ItemType Directory -Path "$BUILD_DIR/LaunchNow" -Force | Out-Null

# Copy app from archive
$appPath = "$BUILD_DIR/LaunchNow.xcarchive/Products/Applications/LaunchNow.app"
if (Test-Path $appPath) {
    Copy-Item -Recurse $appPath "$BUILD_DIR/LaunchNow/"
    Write-Host "✅ App bundle created successfully" -ForegroundColor Green
    
    # Create DMG (requires macOS)
    Write-Host "💿 Creating DMG..." -ForegroundColor Cyan
    try {
        hdiutil create -volname "LaunchNow" -srcfolder "$BUILD_DIR/LaunchNow" -ov -format UDZO "$BUILD_DIR/LaunchNow.dmg"
        Write-Host "✅ DMG created: $BUILD_DIR/LaunchNow.dmg" -ForegroundColor Green
    } catch {
        Write-Host "⚠️ DMG creation failed (requires macOS)" -ForegroundColor Yellow
    }
    
    # Create ZIP
    Write-Host "🗜️ Creating ZIP..." -ForegroundColor Cyan
    $currentLocation = Get-Location
    Set-Location "$BUILD_DIR/LaunchNow"
    Compress-Archive -Path "*" -DestinationPath "../LaunchNow.zip" -Force
    Set-Location $currentLocation
    Write-Host "✅ ZIP created: $BUILD_DIR/LaunchNow.zip" -ForegroundColor Green
    
} else {
    Write-Host "❌ App bundle not found in archive" -ForegroundColor Red
    Write-Host "Archive contents:" -ForegroundColor Red
    if (Test-Path "$BUILD_DIR/LaunchNow.xcarchive/Products/") {
        Get-ChildItem "$BUILD_DIR/LaunchNow.xcarchive/Products/" -Recurse
    } else {
        Write-Host "Products directory not found" -ForegroundColor Red
    }
    exit 1
}

Write-Host ""
Write-Host "🎉 Build completed successfully!" -ForegroundColor Green
Write-Host "📁 Build artifacts:" -ForegroundColor Cyan
Write-Host "   • App: $BUILD_DIR/LaunchNow/LaunchNow.app" -ForegroundColor White
Write-Host "   • DMG: $BUILD_DIR/LaunchNow.dmg" -ForegroundColor White
Write-Host "   • ZIP: $BUILD_DIR/LaunchNow.zip" -ForegroundColor White
Write-Host "   • Archive: $BUILD_DIR/LaunchNow.xcarchive" -ForegroundColor White

# Show file sizes
Write-Host ""
Write-Host "📊 File sizes:" -ForegroundColor Cyan
if (Test-Path "$BUILD_DIR/LaunchNow.dmg") {
    $dmgSize = (Get-Item "$BUILD_DIR/LaunchNow.dmg").Length / 1MB
    Write-Host "   DMG: $([math]::Round($dmgSize, 2)) MB" -ForegroundColor White
}
if (Test-Path "$BUILD_DIR/LaunchNow.zip") {
    $zipSize = (Get-Item "$BUILD_DIR/LaunchNow.zip").Length / 1MB
    Write-Host "   ZIP: $([math]::Round($zipSize, 2)) MB" -ForegroundColor White
}

Write-Host ""
Write-Host "✨ Ready for distribution!" -ForegroundColor Green