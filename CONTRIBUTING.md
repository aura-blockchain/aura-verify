# Contributing to AURA Verify

Thank you for your interest in contributing to the AURA Verify mobile app!

## Getting Started

### Prerequisites

- Flutter 3.16+
- Dart 3.2+
- Android Studio or Xcode (for mobile builds)
- Chrome (for web builds)

### Development Setup

```bash
# Clone the repository
git clone https://github.com/aura-blockchain/aura-verify.git
cd aura-verify

# Get dependencies
flutter pub get

# Run on connected device/emulator
flutter run

# Run tests
flutter test
```

## How to Contribute

### Reporting Issues

1. Search existing issues first
2. Use issue templates provided
3. Include device info, Flutter version, and steps to reproduce

### Pull Requests

1. Fork the repository
2. Create a feature branch: `git checkout -b feature/your-feature`
3. Make your changes
4. Run tests: `flutter test`
5. Run analyzer: `flutter analyze`
6. Commit with clear messages
7. Push and open a PR

### Code Style

- Follow [Effective Dart](https://dart.dev/effective-dart) guidelines
- Use `flutter format` before committing
- Keep widgets small and focused
- Use meaningful names for variables and functions

### Commit Messages

```
type: short description

Longer description if needed.
```

Types: `feat`, `fix`, `docs`, `style`, `refactor`, `test`, `chore`

## Building

```bash
# Build for Android
flutter build apk

# Build for iOS
flutter build ios

# Build for web
flutter build web
```

## Questions?

- Open a GitHub Discussion
- Join [Discord](https://discord.gg/aurablockchain)
