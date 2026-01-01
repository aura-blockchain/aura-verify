# Aura Verify Business - Quick Start Guide

## Installation & Setup

### 1. Install Dependencies

```bash
cd /home/decri/blockchain-projects/third-party-verifier/aura-verify-business
flutter pub get
```

### 2. Run the App

**Option A: Basic Version (Simple scanner)**
```bash
flutter run -t lib/main.dart
```

**Option B: Full Enterprise Version (Recommended)**
```bash
flutter run -t lib/main_updated.dart
```

## First Time Login

**Default Credentials:**
- Username: `admin`
- Password: `admin123`

**Important:** Change the admin password after first login!

## Quick Feature Overview

### For Operators (Basic Users)

1. **Scan Credentials**
   - Dashboard → Scan Credential
   - Point camera at QR code
   - View instant verification result

2. **View History**
   - Dashboard → View History
   - See all past verifications
   - Filter by date or status

### For Managers

All operator features, plus:

1. **Batch Verification**
   - Dashboard → Batch Verify
   - Scan multiple credentials
   - Verify all at once

2. **Export Data**
   - History → Export button
   - Choose CSV or JSON format
   - Download to device

3. **View Reports**
   - Dashboard shows statistics
   - Success rates
   - Daily verification counts

### For Administrators

All manager features, plus:

1. **User Management**
   - Dashboard → Manage Users
   - Create/edit/delete users
   - Assign roles (admin/manager/operator)

2. **System Settings**
   - Dashboard → Settings
   - Network configuration
   - Security settings
   - Data retention policies

3. **Audit Log**
   - Dashboard → Audit Log
   - Complete action history
   - Track all user activities

## Common Tasks

### Create a New User

1. Login as admin
2. Go to Manage Users
3. Click "Add User"
4. Fill in:
   - Username
   - Password
   - Email
   - Display Name
   - Role
5. Click "Create"

### Change Network Settings

1. Go to Settings
2. Tap "Network"
3. Select:
   - **Mainnet** - Production use
   - **Testnet** - Testing
   - **Local** - Development
4. App will restart

### Export Verification History

1. Go to History
2. (Optional) Apply filters
3. Click export icon (top right)
4. Select format:
   - CSV for Excel
   - JSON for systems integration
5. File saved to Documents folder

### Clear Old Data

1. Go to Settings
2. Scroll to "Data & Privacy"
3. Click "Clear History"
4. Confirm action

### Enable Offline Mode

1. Go to Settings
2. Toggle "Offline Mode"
3. Credentials will be cached
4. Verification works without network

## Keyboard Shortcuts

None currently - touch/click interface only.

## Troubleshooting

### Can't Login
- Check username/password (case sensitive)
- Default is `admin` / `admin123`
- If locked out, reinstall app

### Camera Not Working
- Grant camera permissions
- Use physical device (not emulator)
- Check Settings → Permissions

### Verification Failing
- Check network connection
- Verify API endpoint in settings
- Try switching networks

### Data Not Saving
- Check storage permissions
- Ensure sufficient device storage
- Try clearing cache

## Tips & Best Practices

1. **Regular Backups**
   - Export history weekly
   - Keep compliance reports

2. **User Management**
   - Use strong passwords
   - Assign minimum required role
   - Disable inactive accounts

3. **Performance**
   - Clear old history (90+ days)
   - Keep offline cache small
   - Close unused apps

4. **Security**
   - Never share admin credentials
   - Log out when leaving device
   - Enable device lock screen

## Support

**Need Help?**
- Read: IMPLEMENTATION.md (detailed guide)
- Email: support@aura-blockchain.com
- Docs: https://docs.aura-blockchain.com

## Next Steps

1. Change admin password
2. Create user accounts for staff
3. Configure network settings
4. Test verification workflow
5. Set up data retention policy
6. Train staff on usage

## Version Info

**Current Version:** 1.0.0
**Build:** 1
**Last Updated:** 2024

---

**Important:** This is a production application. Always test thoroughly before deployment in live environments.
