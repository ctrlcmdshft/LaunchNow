# GitHub Actions CI/CD for LaunchNow

This directory contains GitHub Actions workflows for automated building, testing, and releasing of the LaunchNow macOS application.

## Workflows

### 1. `build.yml` - Main Build & Test
**Triggers:** Push to `main`/`develop`, Pull Requests to `main`
- Builds the app using Xcode
- Runs tests (if any)
- Creates build artifacts
- Uploads build as artifacts for download

### 2. `lint.yml` - Code Quality
**Triggers:** Push to `main`/`develop`, Pull Requests to `main`
- Runs SwiftLint for code style checking
- Checks for code statistics
- Reports any issues

### 3. `release.yml` - Release Automation
**Triggers:** Git tags starting with `v` (e.g., `v1.0.0`)
- Creates production builds
- Generates DMG and ZIP files
- Creates GitHub releases automatically
- Uploads release assets

## Setup Instructions

### 1. Enable GitHub Actions
1. Push these workflow files to your repository
2. Go to your GitHub repo → Actions tab
3. Actions should automatically be enabled

### 2. Creating Releases
To create a new release:

```bash
# Tag a new version
git tag v1.0.0
git push origin v1.0.0
```

This will automatically:
- Build the app
- Create a GitHub release 
- Upload DMG and ZIP files

### 3. Code Signing (Optional)
For distribution, you may want to add code signing:

1. Add your Apple Developer certificates to GitHub Secrets:
   - `APPLE_CERTIFICATE_BASE64` - Your certificate in base64
   - `APPLE_CERTIFICATE_PASSWORD` - Certificate password
   - `APPLE_TEAM_ID` - Your Apple Developer Team ID

2. Update the workflows to use signing:
   ```yaml
   CODE_SIGN_IDENTITY: "Developer ID Application"
   CODE_SIGNING_REQUIRED: YES
   DEVELOPMENT_TEAM: ${{ secrets.APPLE_TEAM_ID }}
   ```

### 4. Notarization (For Distribution)
For public distribution, add notarization:

1. Add to GitHub Secrets:
   - `APPLE_ID` - Your Apple ID
   - `APPLE_APP_PASSWORD` - App-specific password

2. Add notarization step to release workflow

## File Structure
```
.github/
├── workflows/
│   ├── build.yml      # Main build workflow
│   ├── lint.yml       # Code quality checks
│   └── release.yml    # Release automation
└── export-options.plist # Xcode export settings
```

## Customization

### Xcode Version
Update `XCODE_VERSION` in workflows if needed:
```yaml
env:
  XCODE_VERSION: '15.4'  # Change as needed
```

### Build Configuration
Modify build settings in workflows:
```yaml
env:
  SCHEME_NAME: 'LaunchNow'
  CONFIGURATION: 'Release'
```

### Supported macOS Versions
The workflows use `macos-14` runners. Update if needed:
```yaml
runs-on: macos-14  # or macos-13, macos-latest
```

## Monitoring

### Build Status
- Check the Actions tab in your GitHub repository
- Build status badges can be added to README.md

### Artifacts
- Build artifacts are stored for 30 days
- Release assets are permanent
- Download links are available in releases

## Xcode Version Compatibility

### Current Issue
Your LaunchNow project uses Xcode project format 77, which requires Xcode 16.0 or later. GitHub Actions may not always have the latest Xcode versions available immediately.

### Solutions

#### Option 1: Use Adaptive Build Workflow
The `build-adaptive.yml` workflow automatically detects and uses the newest available Xcode version:

```yaml
# Uses the latest available Xcode automatically
runs-on: macos-latest
```

#### Option 2: Downgrade Project Format (Recommended)
1. Open your project in Xcode
2. Go to Project Settings → Project Format
3. Change to "Xcode 15.0-compatible" or earlier
4. This maintains compatibility with GitHub Actions

#### Option 3: Use Xcode Cloud
Apple's Xcode Cloud always has the latest Xcode versions:
1. Set up Xcode Cloud in App Store Connect
2. Configure build workflows there
3. More suitable for cutting-edge Xcode features

### Workflow Files

- `build.yml` - Standard build (requires Xcode 16.0+)
- `build-adaptive.yml` - Adaptive build (works with available Xcode)
- `release.yml` - Release automation
- `lint.yml` - Code quality checks

## Troubleshooting

### Common Issues
1. **Project format incompatibility**: 
   ```
   error: Unable to read project 'LaunchNow.xcodeproj'
   Reason: The project is in a future Xcode project file format (77)
   ```
   **Solution**: Use `build-adaptive.yml` or downgrade project format

2. **Scheme not found**: Update `SCHEME_NAME` in workflows
3. **Build failures**: Check Xcode version compatibility
4. **Code signing**: May need to disable for CI builds
5. **Missing dependencies**: Ensure all Swift packages are properly configured

### Debug Steps
1. Check workflow logs in Actions tab
2. Look for Xcode version compatibility messages
3. Verify Xcode project settings locally
4. Test build with `xcodebuild` command locally
5. Consider using the adaptive build workflow

### Xcode Version Matrix
| Project Format | Required Xcode | GitHub Actions Support |
|---------------|----------------|----------------------|
| Format 76     | Xcode 15.0+   | ✅ Supported        |
| Format 77     | Xcode 16.0+   | ⚠️ Limited          |
| Format 78+    | Xcode 16.1+   | ❌ Not yet          |