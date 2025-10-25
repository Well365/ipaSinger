#!/usr/bin/env python3
"""
IPA Signer - A tool for signing iOS applications on macOS

This tool helps sign IPA files with developer certificates and provisioning profiles.
"""

import os
import sys
import subprocess
import argparse
import shutil
import zipfile
import tempfile
from pathlib import Path


class IPASigner:
    """Main class for IPA signing operations"""
    
    def __init__(self, verbose=False):
        self.verbose = verbose
        self.temp_dir = None
    
    def log(self, message):
        """Print log message if verbose mode is enabled"""
        if self.verbose:
            print(f"[INFO] {message}")
    
    def error(self, message):
        """Print error message"""
        print(f"[ERROR] {message}", file=sys.stderr)
    
    def check_macos(self):
        """Check if running on macOS"""
        if sys.platform != 'darwin':
            self.error("This tool must be run on macOS")
            return False
        return True
    
    def check_codesign_available(self):
        """Check if codesign tool is available"""
        try:
            result = subprocess.run(['which', 'codesign'], 
                                   capture_output=True, text=True)
            if result.returncode == 0:
                self.log("codesign tool found")
                return True
            else:
                self.error("codesign tool not found. Make sure Xcode Command Line Tools are installed.")
                return False
        except Exception as e:
            self.error(f"Error checking for codesign: {e}")
            return False
    
    def list_identities(self):
        """List available signing identities"""
        try:
            result = subprocess.run(
                ['security', 'find-identity', '-v', '-p', 'codesigning'],
                capture_output=True, text=True
            )
            if result.returncode == 0:
                print("Available signing identities:")
                print(result.stdout)
                return True
            else:
                self.error("Failed to list signing identities")
                return False
        except Exception as e:
            self.error(f"Error listing identities: {e}")
            return False
    
    def extract_ipa(self, ipa_path, extract_dir):
        """Extract IPA file to temporary directory"""
        self.log(f"Extracting IPA: {ipa_path}")
        try:
            with zipfile.ZipFile(ipa_path, 'r') as zip_ref:
                zip_ref.extractall(extract_dir)
            self.log(f"Extracted to: {extract_dir}")
            return True
        except Exception as e:
            self.error(f"Failed to extract IPA: {e}")
            return False
    
    def find_app_bundle(self, extract_dir):
        """Find .app bundle in extracted IPA"""
        payload_dir = os.path.join(extract_dir, 'Payload')
        if not os.path.exists(payload_dir):
            self.error("Payload directory not found in IPA")
            return None
        
        for item in os.listdir(payload_dir):
            if item.endswith('.app'):
                app_path = os.path.join(payload_dir, item)
                self.log(f"Found app bundle: {app_path}")
                return app_path
        
        self.error("No .app bundle found in Payload directory")
        return None
    
    def replace_provisioning_profile(self, app_path, mobileprovision_path):
        """Replace provisioning profile in app bundle"""
        if not mobileprovision_path:
            self.log("No provisioning profile specified, skipping")
            return True
        
        self.log(f"Replacing provisioning profile: {mobileprovision_path}")
        try:
            embedded_profile = os.path.join(app_path, 'embedded.mobileprovision')
            shutil.copy2(mobileprovision_path, embedded_profile)
            self.log("Provisioning profile replaced")
            return True
        except Exception as e:
            self.error(f"Failed to replace provisioning profile: {e}")
            return False
    
    def sign_app(self, app_path, identity, entitlements_path=None):
        """Sign the app bundle with specified identity"""
        self.log(f"Signing app with identity: {identity}")
        
        try:
            # Remove old signature
            self.log("Removing old signature")
            subprocess.run(['rm', '-rf', os.path.join(app_path, '_CodeSignature')],
                          check=False)
            
            # Build codesign command
            cmd = [
                'codesign',
                '-f',  # Force
                '-s', identity,  # Signing identity
            ]
            
            if entitlements_path:
                cmd.extend(['--entitlements', entitlements_path])
            
            # Add resource rules
            cmd.extend([
                '--generate-entitlement-der',
                app_path
            ])
            
            self.log(f"Running: {' '.join(cmd)}")
            result = subprocess.run(cmd, capture_output=True, text=True)
            
            if result.returncode == 0:
                self.log("App signed successfully")
                print(result.stdout)
                return True
            else:
                self.error(f"Failed to sign app: {result.stderr}")
                return False
        except Exception as e:
            self.error(f"Error during signing: {e}")
            return False
    
    def verify_signature(self, app_path):
        """Verify the app signature"""
        self.log(f"Verifying signature: {app_path}")
        try:
            result = subprocess.run(
                ['codesign', '-v', '-v', app_path],
                capture_output=True, text=True
            )
            if result.returncode == 0:
                self.log("Signature verification successful")
                print(result.stdout)
                return True
            else:
                self.error(f"Signature verification failed: {result.stderr}")
                return False
        except Exception as e:
            self.error(f"Error verifying signature: {e}")
            return False
    
    def repackage_ipa(self, extract_dir, output_path):
        """Repackage the signed app into IPA"""
        self.log(f"Repackaging IPA to: {output_path}")
        try:
            with zipfile.ZipFile(output_path, 'w', zipfile.ZIP_DEFLATED) as zipf:
                for root, dirs, files in os.walk(extract_dir):
                    for file in files:
                        file_path = os.path.join(root, file)
                        arcname = os.path.relpath(file_path, extract_dir)
                        zipf.write(file_path, arcname)
            
            self.log(f"IPA repackaged successfully: {output_path}")
            return True
        except Exception as e:
            self.error(f"Failed to repackage IPA: {e}")
            return False
    
    def sign_ipa(self, ipa_path, output_path, identity, mobileprovision_path=None, 
                 entitlements_path=None):
        """Main method to sign an IPA file"""
        # Check prerequisites
        if not self.check_macos():
            return False
        
        if not self.check_codesign_available():
            return False
        
        if not os.path.exists(ipa_path):
            self.error(f"IPA file not found: {ipa_path}")
            return False
        
        # Create temporary directory
        self.temp_dir = tempfile.mkdtemp(prefix='ipasigner_')
        self.log(f"Using temporary directory: {self.temp_dir}")
        
        try:
            # Extract IPA
            if not self.extract_ipa(ipa_path, self.temp_dir):
                return False
            
            # Find app bundle
            app_path = self.find_app_bundle(self.temp_dir)
            if not app_path:
                return False
            
            # Replace provisioning profile if provided
            if not self.replace_provisioning_profile(app_path, mobileprovision_path):
                return False
            
            # Sign the app
            if not self.sign_app(app_path, identity, entitlements_path):
                return False
            
            # Verify signature
            if not self.verify_signature(app_path):
                return False
            
            # Repackage IPA
            if not self.repackage_ipa(self.temp_dir, output_path):
                return False
            
            print(f"\n✓ Successfully signed IPA: {output_path}")
            return True
            
        finally:
            # Cleanup temporary directory
            if self.temp_dir and os.path.exists(self.temp_dir):
                self.log(f"Cleaning up temporary directory: {self.temp_dir}")
                shutil.rmtree(self.temp_dir)


def main():
    """Main entry point"""
    parser = argparse.ArgumentParser(
        description='IPA Signer - Sign iOS applications on macOS',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # List available signing identities
  %(prog)s --list-identities
  
  # Sign an IPA with a certificate
  %(prog)s -i MyApp.ipa -o MyApp-signed.ipa -c "iPhone Developer: John Doe"
  
  # Sign with provisioning profile
  %(prog)s -i MyApp.ipa -o MyApp-signed.ipa -c "iPhone Developer" -p profile.mobileprovision
  
  # Sign with entitlements
  %(prog)s -i MyApp.ipa -o MyApp-signed.ipa -c "iPhone Developer" -e entitlements.plist
        """
    )
    
    parser.add_argument('-i', '--input', help='Input IPA file path')
    parser.add_argument('-o', '--output', help='Output IPA file path')
    parser.add_argument('-c', '--certificate', help='Signing certificate identity (e.g., "iPhone Developer")')
    parser.add_argument('-p', '--provisioning-profile', help='Provisioning profile (.mobileprovision) file path')
    parser.add_argument('-e', '--entitlements', help='Entitlements (.plist) file path')
    parser.add_argument('-l', '--list-identities', action='store_true', 
                       help='List available signing identities')
    parser.add_argument('-v', '--verbose', action='store_true', help='Enable verbose output')
    
    args = parser.parse_args()
    
    signer = IPASigner(verbose=args.verbose)
    
    # Handle list identities
    if args.list_identities:
        sys.exit(0 if signer.list_identities() else 1)
    
    # Validate required arguments for signing
    if not args.input or not args.output or not args.certificate:
        parser.error("--input, --output, and --certificate are required for signing")
    
    # Perform signing
    success = signer.sign_ipa(
        ipa_path=args.input,
        output_path=args.output,
        identity=args.certificate,
        mobileprovision_path=args.provisioning_profile,
        entitlements_path=args.entitlements
    )
    
    sys.exit(0 if success else 1)


if __name__ == '__main__':
    main()
