# iOS Setup Guide for Aura Verify

This guide covers setting up iOS development and CI/CD deployment for the Aura Verify app.

## Prerequisites

- macOS with Xcode 15+ installed
- Apple Developer Program membership ($99/year)
- Flutter SDK 3.24.5+

## Local Development Setup

### 1. Install Dependencies

```bash
# Install CocoaPods
sudo gem install cocoapods

# Install Fastlane
sudo gem install fastlane

# Install iOS dependencies
cd ios
pod install
```

### 2. Configure Xcode

1. Open `ios/Runner.xcworkspace` in Xcode
2. Select the "Runner" target
3. Under "Signing & Capabilities":
   - Select your Team
   - Set Bundle Identifier to `io.aura.verify.business`
   - Enable "Automatically manage signing"

### 3. Run on Simulator/Device

```bash
# List available devices
flutter devices

# Run on iOS Simulator
flutter run -d "iPhone 15 Pro"

# Run on physical device
flutter run -d <device_id>
```

## CI/CD Setup (GitHub Actions)

### Required GitHub Secrets

Configure these in your repository Settings > Secrets and variables > Actions:

| Secret Name | Description | How to Get |
|-------------|-------------|------------|
| `APPLE_TEAM_ID` | 10-character Team ID | [Apple Developer Account](https://developer.apple.com/account) > Membership |
| `APP_STORE_CONNECT_API_KEY_ID` | API Key ID (e.g., ABC123XYZ) | [App Store Connect](https://appstoreconnect.apple.com/access/api) |
| `APP_STORE_CONNECT_API_ISSUER_ID` | Issuer ID (UUID format) | Same page as above |
| `APP_STORE_CONNECT_API_KEY_BASE64` | Base64-encoded .p8 key | See below |
| `BUILD_CERTIFICATE_BASE64` | Base64-encoded .p12 certificate | Export from Keychain Access |
| `P12_PASSWORD` | Password for .p12 file | Set when exporting |
| `KEYCHAIN_PASSWORD` | Temporary keychain password | Any secure password |
| `PROVISION_PROFILE_BASE64` | Base64-encoded .mobileprovision | Download from Apple Developer |

### Creating an App Store Connect API Key

1. Go to [App Store Connect > Users and Access > Keys](https://appstoreconnect.apple.com/access/api)
2. Click "+" to generate a new key
3. Name: "CI/CD Aura Verify"
4. Access: "App Manager" or "Developer"
5. Download the .p8 file (only available once!)
6. Encode it for GitHub:

```bash
# Encode the API key
base64 -i AuthKey_XXXXXXXXXX.p8 | tr -d '\n'

# Copy output to APP_STORE_CONNECT_API_KEY_BASE64 secret
```

### Creating a Distribution Certificate

1. Open Keychain Access on macOS
2. Keychain Access > Certificate Assistant > Request a Certificate From a Certificate Authority
3. Enter your email, select "Saved to disk"
4. Go to [Apple Developer > Certificates](https://developer.apple.com/account/resources/certificates/list)
5. Create a new "Apple Distribution" certificate
6. Download and double-click to install
7. Export from Keychain:
   - Right-click certificate > Export
   - Choose .p12 format
   - Set a password
8. Encode for GitHub:

```bash
base64 -i Certificates.p12 | tr -d '\n'
# Copy to BUILD_CERTIFICATE_BASE64 secret
```

### Creating a Provisioning Profile

1. Go to [Apple Developer > Profiles](https://developer.apple.com/account/resources/profiles/list)
2. Click "+" to create new profile
3. Select "App Store" distribution
4. Select your App ID (`io.aura.verify.business`)
5. Select your distribution certificate
6. Name it (e.g., "Aura Verify App Store")
7. Download and encode:

```bash
base64 -i Aura_Verify_App_Store.mobileprovision | tr -d '\n'
# Copy to PROVISION_PROFILE_BASE64 secret
```

## Fastlane Commands

```bash
cd ios

# Build without code signing (for CI testing)
fastlane build

# Build and upload to TestFlight
fastlane beta

# Build and upload to App Store
fastlane release

# Run tests
fastlane test

# Increment build number
fastlane bump

# Check current version
fastlane get_version
```

## Using Fastlane Match (Recommended for Teams)

Match manages certificates and profiles in a private git repository.

### Initial Setup

1. Create a private repository for certificates:
   ```bash
   # e.g., github.com/aura-blockchain/certificates
   ```

2. Generate an encryption password:
   ```bash
   openssl rand -base64 24
   # Save this as MATCH_PASSWORD in GitHub Secrets
   ```

3. Initialize match:
   ```bash
   cd ios
   fastlane match init
   fastlane match appstore
   ```

### CI/CD with Match

Add these additional secrets:
- `MATCH_PASSWORD`: Encryption password for certificates repo
- `MATCH_GIT_URL`: URL to certificates repo

## Troubleshooting

### "No signing certificate" Error

1. Ensure you have a valid Apple Distribution certificate
2. Check that your provisioning profile includes this certificate
3. Verify PROVISION_PROFILE_BASE64 is correctly encoded

### "Bundle identifier mismatch"

Ensure `ios/Runner.xcodeproj/project.pbxproj` has:
```
PRODUCT_BUNDLE_IDENTIFIER = io.aura.verify.business;
```

### "API key not found"

1. Verify all three API key secrets are set correctly
2. Check that the .p8 key was base64-encoded without line breaks

### CocoaPods Issues

```bash
cd ios
pod deintegrate
pod cache clean --all
pod install --repo-update
```

## App Store Submission Checklist

- [ ] App icon (1024x1024 for App Store)
- [ ] Screenshots for all device sizes
- [ ] App description and keywords
- [ ] Privacy policy URL
- [ ] Support URL
- [ ] Age rating questionnaire
- [ ] Export compliance (ITSAppUsesNonExemptEncryption)

## Resources

- [Apple Developer Documentation](https://developer.apple.com/documentation/)
- [Fastlane Documentation](https://docs.fastlane.tools/)
- [Flutter iOS Deployment](https://docs.flutter.dev/deployment/ios)
- [App Store Connect Help](https://developer.apple.com/help/app-store-connect/)
