# Troubleshooting Guide

This guide helps you solve common issues when using ipaSinger.

## Installation Issues

### Xcode Command Line Tools Not Found

**Error:** `codesign tool not found`

**Solution:**
```bash
xcode-select --install
```

If already installed, verify:
```bash
xcode-select -p
```

Should output something like:
```
/Library/Developer/CommandLineTools
```

### Python Version Issues

**Error:** Script fails with syntax errors

**Solution:** Ensure you're using Python 3.6 or later:
```bash
python3 --version
```

## Certificate and Identity Issues

### No Identities Found

**Error:** Running `--list-identities` shows no certificates

**Solutions:**

1. **Check Keychain Access:**
   - Open Keychain Access app
   - Look in "login" keychain under "My Certificates"
   - Valid certificates should have a private key (▶ icon)

2. **Import a certificate:**
   ```bash
   security import certificate.p12 -k ~/Library/Keychains/login.keychain
   ```

3. **Download from Apple Developer:**
   - Go to https://developer.apple.com/account/resources/certificates
   - Download your certificate
   - Double-click to install

### Certificate Identity String

**Error:** `errSecInternalComponent` or signing fails

**Solution:** Use the exact identity string from:
```bash
security find-identity -v -p codesigning
```

Common formats:
- `"iPhone Developer: John Doe (XXXXXXXXXX)"`
- `"iPhone Distribution: Company Name (YYYYYYYYYY)"`
- `"Apple Development: john@example.com (XXXXXXXXXX)"`

You can use partial matches, but full identity is recommended.

## Provisioning Profile Issues

### Profile Doesn't Match Certificate

**Error:** Signature verification fails after signing

**Solution:**
- Ensure the provisioning profile was created with the certificate you're using
- Check the profile's certificate UUIDs match your certificate
- Regenerate the provisioning profile if needed

### Bundle ID Mismatch

**Error:** Signature verification fails

**Solution:**
- The app's bundle ID must match the provisioning profile
- Check the app's `Info.plist` for `CFBundleIdentifier`
- Use a wildcard profile (e.g., `com.company.*`) if needed

### Expired Profile

**Error:** Verification fails or installation fails

**Solution:**
- Check profile expiration:
  ```bash
  security cms -D -i profile.mobileprovision
  ```
- Look for `<key>ExpirationDate</key>`
- Download a new profile from Apple Developer Portal

## Signing Issues

### Permission Denied

**Error:** Cannot read IPA file or write output

**Solution:**
```bash
chmod 644 input.ipa
chmod 755 /path/to/output/directory
```

### App Bundle Not Found

**Error:** `No .app bundle found in Payload directory`

**Solution:**
- Verify the IPA is valid
- Extract manually to check structure:
  ```bash
  unzip -l your-app.ipa
  ```
- Should contain `Payload/YourApp.app/`

### Code Signature Invalid

**Error:** Signature verification fails

**Common causes:**
1. Certificate and profile don't match
2. App was modified after signing
3. Entitlements don't match profile capabilities
4. Bundle ID mismatch

**Debug steps:**
```bash
# Extract IPA
unzip your-app.ipa
cd Payload/YourApp.app

# Check current signature
codesign -dvvv .

# Check provisioning profile
security cms -D -i embedded.mobileprovision

# Verify bundle ID
/usr/libexec/PlistBuddy -c "Print :CFBundleIdentifier" Info.plist
```

## Entitlements Issues

### Required Entitlements Missing

**Error:** App crashes or features don't work after installation

**Solution:**
1. Extract entitlements from original app:
   ```bash
   codesign -d --entitlements :- Payload/YourApp.app > entitlements.plist
   ```

2. Use these entitlements when re-signing:
   ```bash
   ipasigner.py -i app.ipa -o signed.ipa -c "iPhone Developer" -e entitlements.plist
   ```

### Entitlements Not Allowed

**Error:** Signing fails with entitlement errors

**Solution:**
- Ensure your provisioning profile includes the capabilities
- Remove unsupported entitlements
- Check App ID configuration in Apple Developer Portal

## Platform Issues

### Running on Non-macOS System

**Error:** `This tool must be run on macOS`

**Solution:**
- ipaSigner requires macOS and Apple's code signing tools
- Alternative: Use a macOS virtual machine
- Consider using CI/CD services with macOS runners (GitHub Actions, CircleCI)

## Installation Issues

### Cannot Install Signed IPA

**Error:** Installation fails on device

**Solutions:**

1. **Check device UDID:**
   - Device must be in provisioning profile
   - Get UDID from Finder (when device is connected) or Xcode

2. **Profile type mismatch:**
   - Development profiles: Device must be registered
   - Ad Hoc: Device must be in profile
   - Enterprise: No device restrictions

3. **Try different installation methods:**
   - Xcode: Window → Devices and Simulators
   - Apple Configurator 2
   - `xcrun devicectl device install app` (Xcode 15+)
   - `ideviceinstaller` (libimobiledevice)

## Debug Mode

Enable verbose output to see detailed information:

```bash
./ipasigner.py -i app.ipa -o signed.ipa -c "iPhone Developer" -v
```

This shows:
- Extraction progress
- File locations
- Signing commands
- Verification results

## Getting Help

If you're still stuck:

1. Check the [README](README.md) for basic usage
2. Look at [examples](examples/README.md)
3. Open an issue with:
   - macOS version
   - Python version
   - Xcode version
   - Full error message
   - Steps to reproduce
   - Output with `-v` flag

## Useful Commands

### Check Certificate Details
```bash
security find-certificate -c "iPhone Developer" -p | openssl x509 -text
```

### List All Certificates
```bash
security find-identity -v -p codesigning
```

### View Provisioning Profile
```bash
security cms -D -i profile.mobileprovision
```

### Check App Signature
```bash
codesign -dvvv Payload/YourApp.app
```

### Verify Signature
```bash
codesign -v -v Payload/YourApp.app
```

### Check Entitlements
```bash
codesign -d --entitlements :- Payload/YourApp.app
```
