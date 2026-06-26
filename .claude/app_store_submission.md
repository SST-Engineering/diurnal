# Diurnal — App Store Submission Guide

## 1. Apple Developer Programme
- Enrol at https://developer.apple.com — £99/year
- Required for certificates, provisioning profiles, and App Store Connect access

## 2. Xcode Project Settings

**Identity**
- Bundle Identifier: `co.sweetthunder.diurnal` (must be unique — register in Developer portal first)
- Version: `1.0`
- Build: `1`

**Signing & Capabilities**
- Set Team to your Apple Developer account
- Enable "Automatically manage signing"
- Add iCloud capability + CloudKit if sync is added later

**Deployment Target**
- macOS 14+
- iOS 17+

**App Category**
- Productivity (set in the Info tab)

## 3. App Store Connect

1. Go to https://appstoreconnect.apple.com
2. My Apps → + → New App
3. Fill in: name (Diurnal), primary language, bundle ID, SKU
4. Complete listing: description, keywords, screenshots, support URL, privacy policy URL

## 4. Screenshots Required

| Platform | Size |
|---|---|
| iPhone 6.9" | 1320×2868 |
| iPhone 6.5" | 1242×2688 |
| iPad 13" | 2064×2752 |
| iPad 12.9" | 2048×2732 |
| Mac | 1280×800 minimum |

Take screenshots in Xcode Simulator (⌘S) or on a real device.

## 5. Archive & Upload

1. Product → Archive (scheme must target a device, not simulator)
2. Xcode Organizer → Distribute App → App Store Connect → Upload
3. Xcode validates and uploads the build

## 6. Submit for Review

1. Select uploaded build in App Store Connect
2. Answer export compliance question (almost always No)
3. Fill in Privacy Nutrition Labels (SwiftData is on-device — minimal data collected)
4. Click Submit for Review

Review typically takes 1–2 days for a new app.

## Checklist Before Submitting

- [ ] Joined Apple Developer Programme (£99/year)
- [ ] Bundle ID registered in Developer portal
- [ ] Privacy Policy URL created and hosted (GitHub Pages works)
- [ ] All screenshot sizes prepared
- [ ] App icon 1024px PNG in appiconset ✅
- [ ] Tested on real device (not just simulator)
- [ ] Privacy manifest file added (now required by Apple)
- [ ] Minimum iOS/macOS deployment target confirmed in project settings
- [ ] SwiftData persistence verified ✅

## Next Steps When Ready

When the Developer Programme is set up, ask Claude to help with:
- Register the bundle ID `co.sweetthunder.diurnal` in the portal
- Set up entitlements for iCloud/CloudKit if sync is wanted
- Create the privacy manifest file (`PrivacyInfo.xcprivacy`) — now required by Apple
- Generate the required screenshot sizes
