# ESHOT Tracker

A production-ready iOS application for tracking ESHOT buses in real time in İzmir, Turkey. Built with SwiftUI, MapKit, and İzmir Open Data Portal APIs.

![iOS 15+](https://img.shields.io/badge/iOS-15%2B-blue)
![Swift 5](https://img.shields.io/badge/Swift-5-orange)
![License](https://img.shields.io/badge/license-GPL--3.0-green)

## Features

- 🚌 **Live Bus Tracking** - Real-time bus locations on an interactive map
- 🔍 **Search** - Find buses by line number or stop name
- ⏱️ **Arrival Times** - Estimated arrival times for buses at stops
- 🌙 **Dark Mode** - Full dark mode support
- 🌍 **Localization** - Turkish and English languages
- 📴 **Offline Support** - Cached data when offline
- 🏗️ **MVVM Architecture** - Clean, maintainable code structure

## Requirements

- iOS 15.0+
- Xcode 15.0+
- Swift 5.0+

## Data Source

This app uses the **İzmir Open Data Portal** (İzmir Açık Veri Portalı) ESHOT APIs:
- `https://openapi.izmir.bel.tr/api/eshot/`

## Project Structure

```
ESHOTTracker/
├── ESHOTTrackerApp.swift      # App entry point
├── ContentView.swift          # Main content view
├── Info.plist                 # App configuration
├── Models/
│   ├── BusVehicle.swift       # Bus vehicle model
│   ├── BusStop.swift          # Bus stop model
│   ├── BusLine.swift          # Bus line model
│   ├── Arrival.swift          # Arrival information
│   └── DecodingHelpers.swift  # JSON decoding utilities
├── Views/
│   └── MapScreen.swift        # Main map interface
├── ViewModels/
│   └── BusTrackingViewModel.swift  # Business logic
├── Services/
│   ├── ESHOTAPIClient.swift   # API networking
│   ├── CacheStore.swift       # Offline caching
│   └── NetworkMonitor.swift   # Connection monitoring
└── Resources/
    ├── Assets.xcassets/       # App icons & colors
    ├── en.lproj/              # English strings
    └── tr.lproj/              # Turkish strings
```

## Building

### Local Development

1. Open `ESHOTTracker.xcodeproj` in Xcode
2. Select a simulator or device
3. Press **Cmd + R** to build and run

### Release Build (Unsigned)

The project is configured for unsigned builds suitable for sideloading.

## CI/CD - Unsigned IPA Releases

This project uses GitHub Actions to automatically build and release unsigned IPAs.

### Triggering a Release

```bash
git tag v1.0.0
git push --tags
```

This will:
1. Build the app on `macos-latest`
2. Create an unsigned IPA package
3. Upload it to GitHub Releases

### Downloading the IPA

1. Go to the [**Releases**](../../releases) page
2. Download `ESHOT-Tracker-unsigned.ipa`

### Installing the IPA

> ⚠️ **Important**: This is an unsigned IPA. It is NOT signed with an Apple Developer certificate and cannot be installed directly.

Use one of these sideloading tools:

| Tool | Platform | Link |
|------|----------|------|
| **AltStore** | macOS/Windows | [altstore.io](https://altstore.io/) |
| **Sideloadly** | macOS/Windows | [sideloadly.io](https://sideloadly.io/) |

#### Using AltStore

1. Install AltStore on your computer and iOS device
2. Download the `.ipa` file from Releases
3. Open AltStore on your device
4. Tap **+** and select the downloaded IPA
5. The app will be installed and signed with your Apple ID

> **Note**: Free Apple IDs require re-signing every 7 days.

## Architecture

The app follows the **MVVM (Model-View-ViewModel)** pattern:

- **Models**: Data structures for API responses (`BusVehicle`, `BusStop`, etc.)
- **Views**: SwiftUI views (`MapScreen`, `ContentView`)
- **ViewModels**: Business logic and state management (`BusTrackingViewModel`)
- **Services**: API client, caching, and network monitoring

## Technologies

- **SwiftUI** - Declarative UI framework
- **MapKit** - Map display and annotations
- **URLSession** - Async/await networking
- **Codable** - JSON parsing
- **NWPathMonitor** - Network connectivity

## License

This project is licensed under the GNU General Public License v3.0 - see the [LICENSE](LICENSE) file for details.
