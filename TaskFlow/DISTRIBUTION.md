# TaskFlow Distribution Guide

This guide explains how to properly sign and notarize TaskFlow for distribution to other Mac users.

## Why This Is Needed

When users download TaskFlow from outside the Mac App Store, macOS Gatekeeper checks if the app is:
1. **Code signed** with a Developer ID certificate
2. **Notarized** by Apple (scanned for malware)

Without these, users see: *"Apple could not verify TaskFlow is free of malware"*

## Prerequisites

### 1. Apple Developer Program Membership
- Cost: $99/year
- Sign up at: https://developer.apple.com/programs/
- Required for Developer ID certificates and notarization

### 2. Create Certificates
In your Apple Developer account:

1. Go to **Certificates, Identifiers & Profiles**
2. Click **+** to create a new certificate
3. Select **Developer ID Application** → Continue
4. Follow the instructions to create a Certificate Signing Request (CSR)
5. Download and double-click to install in Keychain
6. Repeat for **Developer ID Installer** (needed for DMG signing)

### 3. Create App-Specific Password
For notarization, you need an app-specific password:

1. Go to https://appleid.apple.com
2. Sign in → Security → App-Specific Passwords
3. Click **+** to generate a password
4. Save this password securely

### 4. Find Your Team ID
Your Team ID is a 10-character identifier:
- Find it at: https://developer.apple.com/account → Membership Details
- Or run: `security find-identity -v -p codesigning`

## Building for Distribution

### Set Environment Variables

```bash
# Your Developer ID certificate name (find with: security find-identity -v -p codesigning)
export DEVELOPER_ID="Developer ID Application: Your Name (TEAMID)"

# Your Apple ID email
export APPLE_ID="your@email.com"

# Your 10-character Team ID
export APPLE_TEAM_ID="ABCD123456"

# App-specific password (or store in keychain - see below)
export NOTARIZE_PASSWORD="xxxx-xxxx-xxxx-xxxx"
```

### Store Password in Keychain (Recommended)

Instead of setting `NOTARIZE_PASSWORD` as an environment variable:

```bash
xcrun notarytool store-credentials "TaskFlow-Notarize" \
    --apple-id "your@email.com" \
    --team-id "ABCD123456" \
    --password "xxxx-xxxx-xxxx-xxxx"
```

Then modify the build script to use `--keychain-profile "TaskFlow-Notarize"` instead of individual credentials.

### Build Commands

```bash
cd <repo>/TaskFlow

# Development build (ad-hoc signing - will show Gatekeeper warning)
./build-app.sh

# Signed build (no Gatekeeper warning if user approves once)
./build-app.sh --sign

# Signed + Notarized build (no Gatekeeper warning at all)
./build-app.sh --notarize

# Create distributable DMG
./build-app.sh --notarize --dmg
```

## Verification

After building, verify the signature and notarization:

```bash
# Check code signature
codesign --verify --verbose=2 TaskFlow.app

# Check notarization status
spctl --assess --verbose=2 TaskFlow.app

# Should output: "TaskFlow.app: accepted"
# source=Notarized Developer ID
```

## Troubleshooting

### "No identity found"
Your Developer ID certificate isn't installed. Download it from Apple Developer portal and double-click to install.

### "The signature is invalid"
The app was modified after signing. Rebuild and sign again.

### Notarization fails with "Invalid signature"
Ensure you're using `--options runtime` (hardened runtime) when signing. The build script does this automatically.

### Notarization fails with "The software is not signed"
Make sure the entitlements file exists and is valid.

### "Team ID does not match"
Your APPLE_TEAM_ID doesn't match the certificate. Check your Team ID at developer.apple.com.

## Entitlements

The app uses `TaskFlow.entitlements` for required permissions:
- Screen Recording (for screenshot capture)
- Accessibility (for keyboard shortcuts)
- Network access (for Ollama API)

## Distribution Checklist

- [ ] Apple Developer Program membership active
- [ ] Developer ID Application certificate installed
- [ ] Developer ID Installer certificate installed (for DMG)
- [ ] App-specific password created
- [ ] Environment variables set (or keychain profile created)
- [ ] Build with `./build-app.sh --notarize --dmg`
- [ ] Verify with `spctl --assess --verbose=2 TaskFlow.app`
- [ ] Test DMG on a different Mac

## Quick Reference

| Build Type | Command | Gatekeeper Result |
|------------|---------|-------------------|
| Development | `./build-app.sh` | ❌ "Cannot verify" warning |
| Signed | `./build-app.sh --sign` | ⚠️ Warning, but can approve |
| Notarized | `./build-app.sh --notarize` | ✅ No warning |
| DMG | `./build-app.sh --notarize --dmg` | ✅ Ready for distribution |
