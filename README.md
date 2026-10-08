# SwiftSurf

<p align="center">
  <strong>A focused, native browser for the macOS menu bar.</strong><br>
  Search, browse, and get back to your work without opening another full-size browser window.
</p>

[![CI](https://github.com/zfeder/swiftsurf/actions/workflows/ci.yml/badge.svg)](https://github.com/zfeder/swiftsurf/actions/workflows/ci.yml)
[![Latest release](https://img.shields.io/github/v/release/zfeder/swiftsurf?display_name=tag&sort=semver)](https://github.com/zfeder/swiftsurf/releases/latest)
[![Downloads](https://img.shields.io/github/downloads/zfeder/swiftsurf/total)](https://github.com/zfeder/swiftsurf/releases)

> **Download SwiftSurf:** [get the latest DMG from GitHub Releases](https://github.com/zfeder/swiftsurf/releases/latest)

## Why SwiftSurf?

SwiftSurf is a compact `WKWebView` browser that stays one click away in the
menu bar. It combines a fast popup workflow with the familiar controls you
expect from a desktop browser, while keeping its footprint deliberately small.

## Highlights

- **Instant access** from the macOS menu bar
- **Responsive popup** with a native bottom-right resize handle
- **Multiple tabs** with independent navigation state
- **Modern web rendering** using WebKit and a desktop Safari-compatible user agent
- **Search or navigate** from one intelligent address bar
- **Back, forward, reload, stop**, and trackpad navigation gestures
- **Bookmarks and recent pages** stored locally
- **Private browsing** with a non-persistent WebKit data store
- **Native downloads** with the macOS save panel
- **Keyboard shortcuts** for the address bar, tabs, reload, and history
- **Persistent window size** and configurable home page
- **Native error states** with retry actions
- **Camera, microphone, and location permissions** requested by websites only when approved

## Install

### Packaged app

Download the latest **[SwiftSurf.dmg from GitHub Releases](https://github.com/zfeder/swiftsurf/releases/latest)**,
open it, and drag **SwiftSurf** into the **Applications** folder. On first
launch, macOS may ask you to confirm that you want to open an app downloaded
from the internet.

The installer is generated automatically by GitHub Actions whenever a version
tag such as `v1.0.0` is pushed. You do not need Xcode to install a published
release.

### Build from source

Requirements:

- macOS 14.5 or later
- Xcode 15 or later
- Apple Silicon or Intel Mac

```bash
git clone https://github.com/zfeder/swiftsurf.git
cd swiftsurf
xcodebuild -project swiftsurf.xcodeproj \
  -scheme swiftsurf \
  -configuration Release \
  -destination 'platform=macOS' \
  build
```

The built app is placed in Xcode's DerivedData products directory.

## Create an installer DMG

The repository includes a repeatable packaging script:

```bash
./scripts/package-dmg.sh
```

It creates `dist/SwiftSurf.dmg`, containing the app and an Applications
shortcut for drag-and-drop installation.

## Publishing a release

Create and push a version tag:

```bash
git tag v1.0.0
git push origin v1.0.0
```

GitHub Actions builds the Release configuration on a macOS runner and attaches
`SwiftSurf.dmg` to a GitHub Release. The latest installer is always available
at the Releases page above.

## Keyboard shortcuts

| Shortcut | Action |
| --- | --- |
| `⌘L` | Focus the address bar |
| `⌘T` | Open a new tab |
| `⌘W` | Close the current tab |
| `⌘R` | Reload the current page |
| `⇧⌘Y` | Show browsing history |

## Privacy

Normal browsing uses WebKit's standard local website data store so logins and
preferences work as expected. Private tabs use a non-persistent store and are
not added to SwiftSurf history. Use **Clear browsing data** in the tab menu to
remove normal WebKit website data and local history.

## License

SwiftSurf is released under the [MIT License](LICENSE). See
[CONTRIBUTING.md](CONTRIBUTING.md) for development and contribution
guidelines.
