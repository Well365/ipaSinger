# Quick Start Guide

Get started with ipaSinger in 5 minutes!

## Prerequisites

- macOS (required)
- Python 3.6+ (included with macOS)
- Xcode Command Line Tools

## Step 1: Install Xcode Command Line Tools

```bash
xcode-select --install
```

## Step 2: Get ipaSinger

```bash
git clone https://github.com/Well365/ipaSinger.git
cd ipaSinger
chmod +x ipasigner.py
```

## Step 3: Find Your Signing Certificate

List available certificates:

```bash
./ipasigner.py --list-identities
```

You'll see output like:
```
1) ABC123... "iPhone Developer: Your Name (XXXXXXXXXX)"
2) DEF456... "iPhone Distribution: Company Name (YYYYYYYYYY)"
```

Copy the full name in quotes (e.g., `"iPhone Developer: Your Name (XXXXXXXXXX)"`).

## Step 4: Sign Your IPA

Basic signing:

```bash
./ipasigner.py -i MyApp.ipa -o MyApp-signed.ipa -c "iPhone Developer: Your Name (XXXXXXXXXX)"
```

With verbose output:

```bash
./ipasigner.py -i MyApp.ipa -o MyApp-signed.ipa -c "iPhone Developer: Your Name" -v
```

## Step 5: Install on Device

Install using Xcode:
1. Open Xcode
2. Window → Devices and Simulators
3. Select your device
4. Drag and drop the signed IPA

Or use command line (Xcode 15+):
```bash
xcrun devicectl device install app --device <device-id> MyApp-signed.ipa
```

## Common Options

### With Provisioning Profile

```bash
./ipasigner.py -i MyApp.ipa -o MyApp-signed.ipa \
  -c "iPhone Developer" \
  -p YourProfile.mobileprovision
```

### With Custom Entitlements

```bash
./ipasigner.py -i MyApp.ipa -o MyApp-signed.ipa \
  -c "iPhone Developer" \
  -e entitlements.plist
```

### All Together

```bash
./ipasigner.py -i MyApp.ipa -o MyApp-signed.ipa \
  -c "iPhone Developer: Your Name" \
  -p profile.mobileprovision \
  -e entitlements.plist \
  -v
```

## Troubleshooting

### Error: "codesign tool not found"
→ Install Xcode Command Line Tools (Step 1)

### Error: "No identities found"
→ Make sure you have a valid Apple Developer certificate installed
→ Check Keychain Access → My Certificates

### Error: "Signature verification failed"
→ Certificate and provisioning profile must match
→ Bundle ID must match provisioning profile

## Next Steps

- Read the [full README](README.md) for detailed documentation
- Check [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for common issues
- See [examples/](examples/) for more usage examples

## Need Help?

Open an issue on GitHub with:
- Your macOS version
- Python version (`python3 --version`)
- Xcode version
- Error message
- What you tried

Happy signing! 🎉
