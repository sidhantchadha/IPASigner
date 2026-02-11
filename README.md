# IPASigner

A native macOS application for re-signing iOS IPA files with new provisioning profiles and signing certificates. This tool simplifies the process of changing code signing identities for iOS applications.

## Features

- 🎯 Simple GUI interface for IPA re-signing
- 🔐 Automatic bundle ID update from provisioning profile
- 📝 Real-time console output for debugging
- 🔑 Automatic signing identity detection from keychain
- 📦 Framework and embedded binary support
- 🎨 Native macOS app built with SwiftUI

## Requirements

- macOS 15.2 (Sequoia) or later
- Xcode 16.0 or later (for building from source)
- Valid iOS signing certificate in keychain
- iOS provisioning profile (.mobileprovision file)

## Installation

### Option 1: Run Pre-built App

1. Download the latest release from the repository
2. Open `IPASigner.app`
3. If you see a security warning, go to System Settings > Privacy & Security and click "Open Anyway"

### Option 2: Build from Source

1. Clone the repository:
```bash
git clone https://github.com/sidhantchadha/IPASigner.git
cd IPASigner
```

2. Open the project in Xcode:
```bash
open IPASigner.xcodeproj
```

3. Build and run the project:
   - Select your development team in project settings
   - Press `Cmd + R` to build and run
   - Or build for release: `Product > Archive`

### Option 3: Command Line Build

```bash
# Clone the repository
git clone https://github.com/sidhantchadha/IPASigner.git
cd IPASigner

# Build the project
xcodebuild -project IPASigner.xcodeproj \
           -scheme IPASigner \
           -configuration Release \
           build

# The app will be in the build directory
open build/Release/IPASigner.app
```

## Usage

### Step 1: Launch IPASigner

Open the IPASigner application. You'll see a simple interface with:
- IPA file selector
- Provisioning profile selector
- Signing identity dropdown
- Resign button
- Console output area

### Step 2: Select IPA File

1. Click "Select IPA File"
2. Navigate to your `.ipa` file
3. Click "Open"

### Step 3: Select Provisioning Profile

1. Click "Select Provisioning Profile"
2. Choose your `.mobileprovision` file
3. Click "Open"

> **Note:** The app will automatically extract the bundle ID from the provisioning profile and update the IPA accordingly.

### Step 4: Choose Signing Identity

1. The dropdown will automatically populate with available signing certificates
2. Select the appropriate certificate (e.g., "iPhone Distribution: YOUR COMPANY")

> **Tip:** Only certificates matching "iPhone", "Apple", "Developer", or "Distribution" are shown.

### Step 5: Re-sign the IPA

1. Click the "Re-sign IPA" button
2. Monitor the console output for progress
3. When prompted, choose where to save the re-signed IPA
4. The re-signed file will be saved with your chosen name

## What Happens During Re-signing

1. **Extraction**: The IPA is unzipped to a temporary directory
2. **Profile Replacement**: The embedded provisioning profile is replaced
3. **Bundle ID Update**: The app's bundle identifier is updated to match the provisioning profile
4. **Entitlements Extraction**: Entitlements are extracted from the provisioning profile
5. **Code Signing**: All frameworks and the main app bundle are re-signed
6. **Repackaging**: The app is zipped back into an IPA file

## Console Output Indicators

- 📝 Profile extraction and processing
- 📱 Provisioning profile loaded
- 🔑 Entitlements found
- 📋 Application identifier detected
- 🔄 Bundle ID extraction
- 📄 Info.plist location
- ✅ Successful operations
- ⚠️ Warnings (non-critical issues)
- ❌ Errors (operation failed)

## Troubleshooting

### "Signing identity not found"
- Ensure your signing certificate is installed in Keychain Access
- Verify the certificate is valid and not expired
- Check that the certificate matches the provisioning profile

### "App not found inside Payload"
- Verify the IPA file is not corrupted
- Ensure it's a valid iOS application package

### "Failed to extract entitlements"
- Check that the provisioning profile is valid
- Ensure the profile hasn't expired
- Verify the profile is for iOS app distribution

### Bundle ID Not Updating
- The app now automatically updates the bundle ID from the provisioning profile
- Check console output for the extracted bundle ID
- Verify the provisioning profile contains the correct application identifier

### Security Warning on First Launch
1. Go to System Settings > Privacy & Security
2. Scroll down to Security section
3. Click "Open Anyway" next to IPASigner
4. Enter your password when prompted

## Security & Privacy

- IPASigner runs in a sandboxed environment
- Only accesses files you explicitly select
- No network connections are made
- All processing happens locally on your machine

## Technical Details

### Build Configuration
- **Language**: Swift 5.0
- **UI Framework**: SwiftUI
- **Minimum macOS**: 15.2
- **Architecture**: Universal (Intel + Apple Silicon)

### Entitlements
- `com.apple.security.app-sandbox`: Enabled
- `com.apple.security.files.downloads.read-write`: For accessing Downloads folder
- `com.apple.security.files.user-selected.read-write`: For file dialogs

### System Tools Used
- `/usr/bin/security`: Certificate management and profile parsing
- `/usr/bin/unzip`: IPA extraction
- `/usr/bin/zip`: IPA packaging
- `/usr/bin/codesign`: Code signing

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## Known Limitations

- Requires macOS 15.2 or later
- Only supports iOS IPA files
- Signing certificate must be in the system keychain
- Cannot sign with certificates requiring password/PIN entry

## License

This project is provided as-is for educational and development purposes.

## Author

Created by Sidhant Chadha

## Version History

- **1.0** (2025-04-16): Initial release
  - Basic IPA re-signing functionality
  - Automatic bundle ID update from provisioning profile
  - GUI interface with console output
  - Support for framework signing

## Support

For issues, questions, or suggestions, please open an issue on the GitHub repository.

---

**Note**: This tool is intended for legitimate development and testing purposes only. Ensure you have the right to re-sign any IPA files you process with this tool.
