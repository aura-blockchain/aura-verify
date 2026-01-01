# Aura Verify Business App - Implementation Guide

## Overview

The Aura Verify Business App is a production-ready, enterprise-grade Flutter application for verifying Aura blockchain credentials. It includes comprehensive features for authentication, verification, audit logging, and compliance reporting.

## Features Implemented

### 1. Authentication & User Management

**Location:** `/lib/features/auth/`

- **Multi-user login system** with secure password hashing (SHA-256)
- **Role-based access control (RBAC)** with three roles:
  - **Admin**: Full system access
  - **Manager**: Can manage users and view reports
  - **Operator**: Can verify credentials only
- **Secure session management** with automatic timeout (60 minutes)
- **Default credentials**: `admin` / `admin123`

**Key Files:**
- `lib/features/auth/domain/user.dart` - User model
- `lib/features/auth/domain/user_role.dart` - Role definitions and permissions
- `lib/features/auth/data/auth_repository.dart` - Authentication logic
- `lib/features/auth/presentation/bloc/auth_bloc.dart` - State management
- `lib/features/auth/presentation/login_screen.dart` - Login UI

### 2. Dashboard

**Location:** `/lib/features/dashboard/`

- **Statistics overview** showing today's scans, verified count, failed count
- **Role-based navigation** - only shows actions the user has permission for
- **Quick action cards** for common tasks
- **User profile display** with role and last login time

**Key Files:**
- `lib/features/dashboard/presentation/dashboard_screen.dart`

### 3. Verification Features

**Location:** `/lib/features/verification/` and `/lib/features/scanner/`

**Standard Verification:**
- QR code scanning with custom overlay
- Real-time verification via Aura blockchain
- Age verification (18+ and 21+)
- Detailed credential display
- Verification history tracking

**Batch Verification:**
- Scan multiple QR codes sequentially
- Queue management
- Bulk verification processing
- Export batch results

**Key Files:**
- `lib/features/scanner/presentation/scanner_screen.dart` - QR scanner
- `lib/features/verification/bloc/verification_bloc.dart` - Verification logic
- `lib/features/verification/presentation/result_screen.dart` - Results display
- `lib/features/batch/presentation/batch_verification_screen.dart` - Batch operations

### 4. Audit & Compliance

**Location:** `/lib/features/audit/`

- **Comprehensive audit logging** for all system actions
- **Database persistence** using SQLite
- **Searchable audit trail** with filters
- **Audit actions tracked:**
  - User login/logout
  - Credential verifications
  - User management
  - Settings changes
  - Data exports

**Key Files:**
- `lib/features/audit/domain/audit_entry.dart` - Audit model
- `lib/features/audit/data/audit_repository.dart` - Database operations

### 5. Verification History

**Location:** `/lib/features/history/`

- **Persistent storage** of all verifications
- **Search and filter** capabilities
- **Date range filtering**
- **Statistics tracking** (success rate, counts)
- **Grouping by date** for better organization

**Key Files:**
- `lib/features/history/domain/verification_record.dart` - Record model
- `lib/features/history/data/history_repository.dart` - Database operations
- `lib/features/history/presentation/history_screen.dart` - UI with filters

### 6. Export Functionality

**Location:** `/lib/core/services/export_service.dart`

**Supported formats:**
- **CSV** - For spreadsheet applications
- **JSON** - For data processing and APIs
- **TXT** - Compliance reports in text format

**Export capabilities:**
- Verification history export
- Audit log export
- Compliance report generation
- Date range filtering for exports

### 7. Settings & Configuration

**Location:** `/lib/features/settings/`

**Network Configuration:**
- Mainnet (Production)
- Testnet (Testing)
- Local (Development)

**Verification Settings:**
- Default age verification (18+ or 21+)
- Auto-scan mode
- Sound and vibration feedback

**Data Management:**
- History retention period (7, 14, 30, 90, 365 days)
- Cache synchronization
- Clear history

**Key Files:**
- `lib/features/settings/presentation/settings_screen.dart`

### 8. Offline Mode

**Location:** `/lib/core/services/offline_cache_service.dart`

- **Credential caching** for offline verification
- **Automatic expiration** management
- **Cache statistics** tracking
- **Background synchronization** support
- **Fallback verification** when network unavailable

### 9. UI/UX

**Material Design 3:**
- Professional color scheme (Purple primary, Teal secondary)
- Consistent spacing and typography
- Responsive layouts for all screen sizes
- **Dark theme support** for low-light environments

**Key Files:**
- `lib/app/theme.dart` - Complete theme configuration

## Project Structure

```
lib/
├── app/
│   ├── app.dart                    # Main app configuration
│   ├── routes.dart                 # Original routing
│   ├── routes_updated.dart         # Enhanced routing with auth
│   └── theme.dart                  # Light & dark themes
├── core/
│   ├── config/
│   │   ├── app_config.dart         # App-wide settings
│   │   └── network_config.dart     # API endpoints
│   └── services/
│       ├── aura_verification_service.dart  # Blockchain verification
│       ├── export_service.dart             # Data export
│       └── offline_cache_service.dart      # Offline support
├── features/
│   ├── auth/
│   │   ├── data/
│   │   │   └── auth_repository.dart        # Auth operations
│   │   ├── domain/
│   │   │   ├── user.dart                   # User model
│   │   │   └── user_role.dart              # Roles & permissions
│   │   └── presentation/
│   │       ├── bloc/
│   │       │   └── auth_bloc.dart          # Auth state management
│   │       └── login_screen.dart           # Login UI
│   ├── dashboard/
│   │   └── presentation/
│   │       └── dashboard_screen.dart       # Main dashboard
│   ├── scanner/
│   │   └── presentation/
│   │       ├── scanner_screen.dart         # QR scanner
│   │       └── scanner_overlay.dart        # Custom overlay
│   ├── verification/
│   │   ├── bloc/
│   │   │   └── verification_bloc.dart      # Verification logic
│   │   └── presentation/
│   │       ├── result_screen.dart          # Results display
│   │       └── widgets/                    # Custom widgets
│   ├── batch/
│   │   └── presentation/
│   │       └── batch_verification_screen.dart  # Batch operations
│   ├── history/
│   │   ├── data/
│   │   │   └── history_repository.dart     # History DB operations
│   │   ├── domain/
│   │   │   └── verification_record.dart    # Record model
│   │   └── presentation/
│   │       └── history_screen.dart         # History UI with filters
│   ├── audit/
│   │   ├── data/
│   │   │   └── audit_repository.dart       # Audit DB operations
│   │   └── domain/
│   │       └── audit_entry.dart            # Audit model
│   └── settings/
│       └── presentation/
│           └── settings_screen.dart        # Settings UI
├── shared/
│   └── widgets/                            # Reusable widgets
├── main.dart                               # Original entry point
└── main_updated.dart                       # Enhanced entry point
```

## Getting Started

### Prerequisites

- Flutter SDK 3.2.0 or higher
- Dart SDK 3.2.0 or higher
- Android SDK or Xcode

### Installation

1. **Navigate to the project directory:**
```bash
cd /home/decri/blockchain-projects/third-party-verifier/aura-verify-business
```

2. **Install dependencies:**
```bash
flutter pub get
```

3. **Run the app:**

**With basic features (original):**
```bash
flutter run -t lib/main.dart
```

**With full enterprise features (recommended):**
```bash
flutter run -t lib/main_updated.dart
```

### Building for Production

**Android:**
```bash
flutter build apk --release -t lib/main_updated.dart
# or for app bundle
flutter build appbundle --release -t lib/main_updated.dart
```

**iOS:**
```bash
flutter build ios --release -t lib/main_updated.dart
```

## Usage Guide

### First Login

1. Launch the app
2. Use default credentials:
   - Username: `admin`
   - Password: `admin123`
3. You'll be taken to the dashboard

### Creating Users (Admin only)

1. Go to Dashboard → Manage Users
2. Click "Add User"
3. Enter details and assign role
4. User can now log in with their credentials

### Verifying Credentials

**Single Verification:**
1. Dashboard → Scan Credential
2. Point camera at QR code
3. View verification result
4. Return to scanner or dashboard

**Batch Verification:**
1. Dashboard → Batch Verify
2. Scan multiple QR codes
3. Click "Verify All"
4. View results and export if needed

### Viewing History

1. Dashboard → View History
2. Use filters to find specific verifications:
   - Filter by status (Verified/Failed)
   - Filter by age verification (18+/21+)
   - Filter by date range
3. Click any entry for details

### Exporting Data

**From History:**
1. Go to History
2. Apply filters if needed
3. Click export icon
4. Choose format (CSV/JSON)

**Compliance Report:**
1. Go to Settings
2. Select date range
3. Generate compliance report

### Managing Settings

1. Dashboard → Settings
2. Configure:
   - Network (mainnet/testnet)
   - Default age verification
   - Auto-scan mode
   - History retention
   - Theme (light/dark)

## Security Features

1. **Password Hashing:** SHA-256 with salt
2. **Secure Storage:** Flutter Secure Storage for credentials
3. **Session Management:** 60-minute timeout with automatic logout
4. **RBAC:** Granular permission control
5. **Audit Trail:** Complete action logging
6. **Network Security:** HTTPS-only API communication

## Database Schema

### Users (Secure Storage)
- Stored in encrypted Flutter Secure Storage
- Password hashes stored separately from user data

### Verification History (SQLite)
```sql
CREATE TABLE verification_history (
  id TEXT PRIMARY KEY,
  holder_did TEXT NOT NULL,
  is_valid INTEGER NOT NULL,
  verified_at TEXT NOT NULL,
  verified_by TEXT NOT NULL,
  verified_by_username TEXT NOT NULL,
  result_type TEXT NOT NULL,
  error_message TEXT,
  network_latency_ms INTEGER NOT NULL,
  attributes TEXT
)
```

### Audit Log (SQLite)
```sql
CREATE TABLE audit_log (
  id TEXT PRIMARY KEY,
  user_id TEXT NOT NULL,
  username TEXT NOT NULL,
  action TEXT NOT NULL,
  description TEXT NOT NULL,
  metadata TEXT,
  timestamp TEXT NOT NULL,
  ip_address TEXT,
  device_info TEXT
)
```

### Offline Cache (SQLite)
```sql
CREATE TABLE offline_cache (
  holder_did TEXT PRIMARY KEY,
  verification_data TEXT NOT NULL,
  cached_at TEXT NOT NULL,
  expires_at TEXT NOT NULL,
  is_valid INTEGER NOT NULL
)
```

## API Integration

The app integrates with Aura blockchain via REST API:

**Endpoint:** `https://api.aura.network/aura/vcregistry/v1beta1/verify_presentation`

**Request:**
```json
{
  "qr_code_data": "string",
  "verifier_address": "string (optional)"
}
```

**Response:**
```json
{
  "is_valid": boolean,
  "holder_did": "string",
  "verified_at": "ISO8601 datetime",
  "vc_details": [/* array of credentials */],
  "attributes": {
    "is_over_18": boolean,
    "is_over_21": boolean,
    /* other attributes */
  }
}
```

## Customization

### Changing Network

Edit `lib/core/config/network_config.dart`:
```dart
static const String productionBaseUrl = 'https://your-api.com';
```

### Modifying Age Thresholds

Edit `lib/core/config/app_config.dart`:
```dart
static const int legalDrinkingAge = 21;
static const int legalAdultAge = 18;
```

### Customizing Theme

Edit `lib/app/theme.dart`:
```dart
static const Color primaryPurple = Color(0xFF6B46C1); // Change color
```

## Testing

### Running Tests

```bash
flutter test
```

### Test Coverage

```bash
flutter test --coverage
```

## Performance Optimization

1. **Image Optimization:** Use cached network images
2. **Database Indexing:** Indexes on frequently queried fields
3. **Lazy Loading:** Pagination for history and audit logs
4. **Cache Management:** Automatic cleanup of expired entries
5. **Network Optimization:** Request timeouts and retry logic

## Troubleshooting

### Camera Not Working
- Check permissions in AndroidManifest.xml and Info.plist
- Ensure physical device (emulators may not support camera)

### Database Errors
- Clear app data and reinstall
- Check SQLite version compatibility

### Network Errors
- Verify API endpoint configuration
- Check network connectivity
- Ensure firewall allows HTTPS connections

## Future Enhancements

- Biometric authentication
- Push notifications
- Multi-language support
- Advanced analytics dashboard
- POS system integration
- Webhook support
- Offline-first architecture
- Real-time sync across devices

## Support

For issues or questions:
- Email: support@aura-blockchain.com
- Documentation: https://docs.aura-blockchain.com

## License

Copyright (c) 2024 Aura Blockchain. All rights reserved.
