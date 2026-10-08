# Contributing to SwiftSurf

Thanks for your interest in SwiftSurf. Bug reports, ideas, documentation, and
code contributions are welcome.

## Before opening an issue

- Search existing issues first.
- For a bug, include macOS and SwiftSurf versions plus reproducible steps.
- Remove credentials, private URLs, and personal information from logs and
  screenshots.

## Development setup

1. Install Xcode 15 or later on macOS 14.5 or later.
2. Clone the repository and open `swiftsurf.xcodeproj`.
3. Run the `swiftsurf` scheme.
4. Run the focused tests before opening a pull request:

```bash
xcodebuild \
  -project swiftsurf.xcodeproj \
  -scheme swiftsurf \
  -destination 'platform=macOS' \
  CODE_SIGNING_ALLOWED=NO \
  test
```

## Pull requests

- Keep changes focused and explain the user-facing impact.
- Update the README when behavior or installation changes.
- Add or update tests when fixing a regression.
- Do not include secrets, local Xcode state, or generated `dist/` files.
- Make sure the GitHub Actions check passes.

By contributing, you agree that your work may be distributed under the
project's eventual open-source license.
