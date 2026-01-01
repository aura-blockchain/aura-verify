# Aura Verify Business

Enterprise-grade verification app for Aura blockchain credentials. Designed for businesses (bars, stores, etc.) to verify customer age and identity credentials.

## Features

- QR code scanning with custom Aura-branded overlay
- Real-time age verification (21+, 18+)
- Clean, professional UI for non-technical users
- Support for both portrait and landscape orientations
- Large, clear verification status displays
- Detailed credential information display
- Verification history (coming soon)
- Settings and configuration (coming soon)

## Technology Stack

- **Flutter SDK**: 3.2.0+
- **mobile_scanner**: QR code scanning
- **go_router**: Navigation and routing
- **flutter_bloc**: State management (prepared for future use)
- **dio**: HTTP client for API calls
- **sqflite**: Local database for history
- **flutter_secure_storage**: Secure credential storage

## Project Structure

```
lib/
├── app/
│   ├── app.dart              # MaterialApp configuration
│   ├── routes.dart           # GoRouter configuration
│   └── theme.dart            # Aura brand theme
├── core/
│   └── config/
│       ├── app_config.dart   # App-wide configuration
│       └── network_config.dart # API endpoints
├── features/
│   ├── scanner/
│   │   └── presentation/
│   │       ├── scanner_screen.dart
│   │       └── scanner_overlay.dart
│   └── verification/
│       └── presentation/
│           ├── result_screen.dart
│           └── widgets/
│               ├── verification_badge.dart
│               └── attribute_card.dart
├── shared/
│   └── widgets/
│       ├── aura_app_bar.dart
│       └── loading_overlay.dart
└── main.dart                 # App entry point
```

## Getting Started

### Prerequisites

- Flutter SDK 3.2.0 or higher
- Dart SDK 3.2.0 or higher
- Android SDK (for Android development)
- Xcode (for iOS development)

### Installation

1. Clone the repository:
```bash
git clone <repository-url>
cd aura-verify-business
```

2. Install dependencies:
```bash
flutter pub get
```

3. Run the app:
```bash
flutter run
```

### Building for Production

#### Android
```bash
flutter build apk --release
# or for app bundle
flutter build appbundle --release
```

#### iOS
```bash
flutter build ios --release
```

## Configuration

### API Configuration

Update the API endpoints in `lib/core/config/network_config.dart`:

```dart
static const String productionBaseUrl = 'https://api.aura-blockchain.com';
```

### App Configuration

Customize app settings in `lib/core/config/app_config.dart`:

```dart
static const int legalDrinkingAge = 21;
static const int legalAdultAge = 18;
```

## Color Scheme

- **Primary Purple**: `#6B46C1` - Main brand color
- **Secondary Teal**: `#14B8A6` - Accent color
- **Success Green**: `#10B981` - Verified/success states
- **Error Red**: `#EF4444` - Failed/error states
- **Warning Orange**: `#F59E0B` - Warning states

## Usage

1. **Launch the app** - Opens directly to scanner screen
2. **Scan QR code** - Point camera at Aura credential QR code
3. **View results** - See verification status with clear visual feedback
4. **Age verification** - Prominently displays "21+" or "18+" status
5. **Review details** - View credential attributes if needed
6. **Scan next** - Return to scanner for next customer

## Features in Development

- [ ] Verification history persistence
- [ ] Detailed settings page
- [ ] Offline verification mode
- [ ] Custom verification rules
- [ ] Multi-language support
- [ ] Biometric authentication
- [ ] Analytics dashboard

## Security

- Secure storage for sensitive data
- HTTPS-only API communication
- No permanent storage of personal information (configurable)
- Session timeout protection

## License

Copyright (c) 2024 Aura Blockchain. All rights reserved.

## Support

For support, please contact support@aura-blockchain.com
