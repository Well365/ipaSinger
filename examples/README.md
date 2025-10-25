# Examples

This directory contains example files and scripts to help you get started with ipaSigner.

## Example Entitlements File

See `example-entitlements.plist` for a sample entitlements file structure.

## Example Usage Scripts

### Basic Signing Script

Create a file `sign-app.sh`:

```bash
#!/bin/bash
# Basic IPA signing script

INPUT_IPA="YourApp.ipa"
OUTPUT_IPA="YourApp-signed.ipa"
CERTIFICATE="iPhone Developer: Your Name (XXXXXXXXXX)"

../ipasigner.py -i "$INPUT_IPA" -o "$OUTPUT_IPA" -c "$CERTIFICATE" -v
```

### Advanced Signing Script

Create a file `sign-with-profile.sh`:

```bash
#!/bin/bash
# Sign IPA with provisioning profile

INPUT_IPA="YourApp.ipa"
OUTPUT_IPA="YourApp-signed.ipa"
CERTIFICATE="iPhone Developer: Your Name (XXXXXXXXXX)"
PROFILE="YourProfile.mobileprovision"
ENTITLEMENTS="example-entitlements.plist"

../ipasigner.py -i "$INPUT_IPA" -o "$OUTPUT_IPA" \
  -c "$CERTIFICATE" \
  -p "$PROFILE" \
  -e "$ENTITLEMENTS" \
  -v
```

Make the scripts executable:
```bash
chmod +x sign-app.sh sign-with-profile.sh
```

## Finding Your Certificate Identity

Run this command to list all available signing identities:

```bash
../ipasigner.py --list-identities
```

Or use the security command directly:

```bash
security find-identity -v -p codesigning
```

Look for lines like:
```
1) XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXX "iPhone Developer: Your Name (XXXXXXXXXX)"
```

Use the full name in quotes as your certificate identity.
