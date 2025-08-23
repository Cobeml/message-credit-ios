# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

Privacy Credit Analyzer is an iOS app that performs privacy-preserving credit score analysis by processing iMessages using on-device AI inference. The project consists of two main components:

1. **message-credit**: Main SwiftUI iOS app with user interface
2. **PrivacyCreditAnalyzer**: Swift Package containing core data models and analysis logic

The app analyzes user messages to determine personality traits (Big Five) and trustworthiness scores, with all processing happening on-device to maintain privacy.

## Architecture

### Core Components

- **Main App (`message-credit/`)**: SwiftUI iOS app that provides the user interface
  - Target: iOS 17.0+
  - Bundle ID: `com.privacycreditanalyzer.app` (based on PrivacyCreditAnalyzer package)
  - Uses local Swift Package dependency for core models

- **Core Package (`PrivacyCreditAnalyzer/`)**: Swift Package with data models and analysis logic
  - Platform: iOS 17.0+
  - Contains all core data models: Message, PersonalityTraits, TrustworthinessScore, AnalysisResult, SignedResult
  - Comprehensive unit test suite (22 tests)

### Project Structure

```
message-credit/                    # Main iOS app
├── message-credit.xcodeproj/     # Xcode project file
└── message-credit/               # App source code
    ├── ContentView.swift         # Main UI with analysis interface
    ├── ShortcutsHelpView.swift   # iOS Shortcuts integration UI
    └── ShortcutsManager.swift    # Shortcuts management logic

PrivacyCreditAnalyzer/            # Core Swift Package
├── Package.swift                 # SPM configuration
├── Sources/PrivacyCreditAnalyzer/
│   └── Models/                   # Core data models
└── Tests/PrivacyCreditAnalyzerTests/  # Unit tests
```

## Development Commands

### Building and Testing

For the Swift Package (PrivacyCreditAnalyzer):
```bash
cd PrivacyCreditAnalyzer
swift build                       # Build the package
swift test                        # Run all unit tests (22 tests)
swift test --filter TestName      # Run specific test
swift build --configuration release  # Release build
```

For the iOS App (message-credit):
- Open `message-credit.xcodeproj` in Xcode
- Use Cmd+B to build
- Use Cmd+R to run in simulator
- Target: iPhone 15 or any iOS 17.0+ simulator

### Package Dependencies

The main app depends on the local PrivacyCreditAnalyzer package:
- Added as local Swift Package dependency in Xcode
- Path: `../PrivacyCreditAnalyzer` (relative to main app)
- No external dependencies currently (future: MLX-Swift, PostgresClientKit)

## Development Workflow

### Testing Strategy
- **Unit Tests**: All core data models have comprehensive test coverage
- **UI Testing**: Basic UI tests for main app interface
- **Integration Testing**: Test app with package integration

### Package Management
- PrivacyCreditAnalyzer is a local Swift Package
- When making changes to models, rebuild both package and app
- The app automatically picks up package changes when building

### iOS Shortcuts Integration
The app includes iOS Shortcuts for message import:
- Three performance tiers: Quick (200 messages), Standard (1000 messages), Deep (5000 messages)
- Custom URL scheme: `privacycredit://import?data=<base64_encoded_json>`
- Smart message filtering prioritizing financial conversations

## Implementation Status

### ✅ Completed (Task 1)
- iOS project structure with SwiftUI interface
- Complete data model implementation with validation
- Comprehensive unit test suite (all 22 tests passing)
- iOS Shortcuts integration framework
- Mock analysis results for UI development

### 🚧 Planned Implementation
- **Task 2**: Messages Export JSON parsing
- **Task 4**: MLX-Swift integration for on-device AI inference  
- **Task 5**: Background processing for large message volumes
- **Task 6**: CryptoKit signing for result verification
- **Backend**: PostgreSQL integration via PostgresClientKit

## Key Files and Locations

### Core Data Models (`PrivacyCreditAnalyzer/Sources/PrivacyCreditAnalyzer/Models/`)
- `Message.swift`: iMessage representation with validation
- `PersonalityTraits.swift`: Big Five personality traits scoring
- `TrustworthinessScore.swift`: Trustworthiness analysis with factors
- `AnalysisResult.swift`: Complete analysis result container
- `SignedResult.swift`: Cryptographically signed result for verification

### Main App (`message-credit/message-credit/`)
- `ContentView.swift`: Main analysis interface with text input and file picker
- `ShortcutsHelpView.swift`: User guide for iOS Shortcuts integration
- `ShortcutsManager.swift`: Handles URL scheme and shortcut data processing

### Test Files (`PrivacyCreditAnalyzer/Tests/PrivacyCreditAnalyzerTests/`)
- `DataModelTests.swift`: Core model validation and serialization tests
- All other test files: Component-specific unit tests

## Privacy and Security Considerations

- All message processing must happen on-device
- No raw message data should be transmitted to external servers
- Results are cryptographically signed for verification
- GDPR compliance is maintained throughout the architecture
- Use CryptoKit for all cryptographic operations when implemented