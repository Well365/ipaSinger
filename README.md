# ipaSinger

A command-line tool for signing iOS application (IPA) files on macOS. This tool automates the process of re-signing IPA files with your own developer certificates and provisioning profiles.

## 🚀 Quick Start

New to ipaSinger? Check out the [Quick Start Guide](QUICKSTART.md) to get up and running in 5 minutes!

## Features

- ✅ Sign IPA files with your Apple Developer certificates
- ✅ Replace provisioning profiles
- ✅ Support for custom entitlements
- ✅ List available signing identities
- ✅ Verify code signatures
- ✅ Simple command-line interface

## Requirements

- **macOS** (required for Apple's code signing tools)
- **Python 3.6+** (included with macOS)
- **Xcode Command Line Tools** (for `codesign` utility)

### Installing Xcode Command Line Tools

If you don't have Xcode Command Line Tools installed:

```bash
xcode-select --install
```

## Installation

1. Clone this repository:
```bash
git clone https://github.com/Well365/ipaSinger.git
cd ipaSinger
```

2. Make the script executable:
```bash
chmod +x ipasigner.py
```

3. (Optional) Create a symlink to use it from anywhere:
```bash
sudo ln -s $(pwd)/ipasigner.py /usr/local/bin/ipasigner
```

## Usage

### List Available Signing Identities

Before signing, you can list all available signing certificates:

```bash
./ipasigner.py --list-identities
```

### Sign an IPA File

Basic usage:

```bash
./ipasigner.py -i input.ipa -o output.ipa -c "iPhone Developer: Your Name (XXXXXXXXXX)"
```

### Advanced Options

**Sign with a provisioning profile:**

```bash
./ipasigner.py -i input.ipa -o output-signed.ipa \
  -c "iPhone Developer" \
  -p YourProfile.mobileprovision
```

**Sign with custom entitlements:**

```bash
./ipasigner.py -i input.ipa -o output-signed.ipa \
  -c "iPhone Developer" \
  -e entitlements.plist
```

**Sign with everything (certificate, profile, and entitlements):**

```bash
./ipasigner.py -i input.ipa -o output-signed.ipa \
  -c "iPhone Developer: Your Name" \
  -p YourProfile.mobileprovision \
  -e entitlements.plist \
  -v  # verbose mode
```

### Command-Line Arguments

| Argument | Short | Description |
|----------|-------|-------------|
| `--input` | `-i` | Input IPA file path (required for signing) |
| `--output` | `-o` | Output IPA file path (required for signing) |
| `--certificate` | `-c` | Signing certificate identity (required for signing) |
| `--provisioning-profile` | `-p` | Provisioning profile (.mobileprovision) file path (optional) |
| `--entitlements` | `-e` | Entitlements (.plist) file path (optional) |
| `--list-identities` | `-l` | List available signing identities |
| `--verbose` | `-v` | Enable verbose output |
| `--help` | `-h` | Show help message |

## How It Works

1. **Extract**: Unzips the IPA file to a temporary directory
2. **Replace**: Replaces the provisioning profile if specified
3. **Sign**: Signs the app bundle with the specified certificate and entitlements
4. **Verify**: Verifies the code signature
5. **Repackage**: Zips the signed app bundle back into an IPA file

## Common Use Cases

### Re-signing an App for Development

If you have an IPA file and want to install it on your device:

1. Get your signing certificate identity:
   ```bash
   ./ipasigner.py -l
   ```

2. Export your provisioning profile from Xcode or Apple Developer Portal

3. Sign the IPA:
   ```bash
   ./ipasigner.py -i MyApp.ipa -o MyApp-signed.ipa \
     -c "iPhone Developer: Your Name" \
     -p YourProfile.mobileprovision
   ```

4. Install using Xcode, Apple Configurator, or other tools

### Enterprise Distribution

For enterprise distribution, use your enterprise certificate:

```bash
./ipasigner.py -i MyApp.ipa -o MyApp-enterprise.ipa \
  -c "iPhone Distribution: Your Company Name" \
  -p EnterpriseProfile.mobileprovision
```

## Troubleshooting

### "codesign tool not found"

Install Xcode Command Line Tools:
```bash
xcode-select --install
```

### "No identities found"

Make sure you have valid Apple Developer certificates installed in your Keychain. You can check in:
- Keychain Access app → My Certificates

Or import a certificate:
```bash
security import certificate.p12 -k ~/Library/Keychains/login.keychain
```

### "Signature verification failed"

This usually means:
- The certificate doesn't match the provisioning profile
- The bundle ID in the app doesn't match the provisioning profile
- The certificate has expired

### "This tool must be run on macOS"

ipaSigner requires macOS because it uses Apple's `codesign` tool, which is only available on macOS.

## Security Notes

- Keep your certificates and private keys secure
- Never commit `.p12` files, certificates, or provisioning profiles to version control
- The `.gitignore` file is configured to exclude these sensitive files

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is open source and available under the MIT License.

## Disclaimer

This tool is for legitimate development and testing purposes. Make sure you have the right to re-sign any IPA files you work with, and always comply with Apple's Developer Program License Agreement.
