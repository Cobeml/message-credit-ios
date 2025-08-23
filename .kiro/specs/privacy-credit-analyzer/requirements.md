# Requirements Document

## Introduction

This feature involves building a standalone iOS app in SwiftUI that performs privacy-preserving credit score analysis by processing iMessages on-device. The app extracts financial data from messages, analyzes personality traits and trustworthiness using an on-device AI model (Phi-3 Mini with prompt engineering), and outputs verifiable results while maintaining strict privacy standards where no raw data leaves the device. The app supports processing large volumes of messages through background processing and intelligent filtering.

## Requirements

### Requirement 1

**User Story:** As a user, I want to input my iMessages containing financial data, so that I can analyze my creditworthiness without compromising my privacy.

#### Acceptance Criteria

1. WHEN the user opens the app THEN the system SHALL display a text input field for manual message entry
2. WHEN the user selects file input THEN the system SHALL provide a file picker for Messages Export files
3. WHEN the user inputs messages THEN the system SHALL accept both text and JSON formats
4. WHEN the user provides a large message volume THEN the system SHALL offer processing options (all messages, loved ones only, or background processing)
5. WHEN processing all messages THEN the system SHALL run analysis in background to avoid blocking the UI

### Requirement 2

**User Story:** As a user, I want my messages to be processed on-device with AI analysis, so that my personal financial data never leaves my iPhone.

#### Acceptance Criteria

1. WHEN the user clicks "Analyze" THEN the system SHALL process all data locally using Phi-3 Mini base model via MLX-Swift with prompt engineering
2. WHEN processing large message volumes THEN the system SHALL run analysis in background without strict time constraints
3. WHEN analyzing messages THEN the system SHALL extract Big Five personality traits
4. WHEN analyzing messages THEN the system SHALL calculate a trustworthiness score
5. WHEN processing occurs THEN the system SHALL ensure no raw message data is transmitted off-device

### Requirement 3

**User Story:** As a user, I want to receive structured analysis results with cryptographic verification, so that I can trust the authenticity of my credit analysis.

#### Acceptance Criteria

1. WHEN analysis completes THEN the system SHALL output structured JSON containing personality traits
2. WHEN analysis completes THEN the system SHALL include trustworthiness score in the JSON output
3. WHEN analysis completes THEN the system SHALL include explanations for the analysis results
4. WHEN generating output THEN the system SHALL sign the JSON using CryptoKit for verifiability
5. WHEN signing occurs THEN the system SHALL hash input messages and model weights together
6. WHEN displaying results THEN the system SHALL show the signed JSON in the UI

### Requirement 4

**User Story:** As a user, I want my analysis results to be stored in a backend database, so that I can access my credit analysis history.

#### Acceptance Criteria

1. WHEN analysis completes THEN the system SHALL send only the signed JSON to PostgreSQL backend
2. WHEN sending data THEN the system SHALL use PostgresClientKit for database communication
3. WHEN the backend receives data THEN the system SHALL verify the cryptographic signature
4. IF signature verification fails THEN the system SHALL reject the data and log the attempt
5. WHEN data is successfully stored THEN the system SHALL confirm storage to the user

### Requirement 5

**User Story:** As a user, I want the app to comply with privacy regulations, so that I can use it confidently knowing my data is protected.

#### Acceptance Criteria

1. WHEN the app processes data THEN the system SHALL ensure GDPR compliance
2. WHEN the app runs THEN the system SHALL never transmit raw message content off-device
3. WHEN the app stores data THEN the system SHALL only store processed, signed results
4. WHEN the app handles data THEN the system SHALL implement privacy-by-design principles
5. WHEN requested THEN the system SHALL provide clear privacy policy information

### Requirement 6

**User Story:** As a user, I want intelligent message filtering options, so that I can process relevant messages efficiently without overwhelming the system.

#### Acceptance Criteria

1. WHEN the user has many messages THEN the system SHALL offer to filter messages from loved ones (family, close friends)
2. WHEN filtering by loved ones THEN the system SHALL identify contacts based on message frequency and relationship indicators
3. WHEN processing all messages THEN the system SHALL use background processing to handle large volumes
4. WHEN background processing runs THEN the system SHALL show progress updates and allow cancellation
5. WHEN message indexing occurs THEN the system SHALL prioritize messages with financial keywords and emotional content

### Requirement 7

**User Story:** As a developer, I want a simple debugging interface, so that I can monitor the backend processing and troubleshoot issues.

#### Acceptance Criteria

1. WHEN the app runs THEN the system SHALL display current processing status in the UI
2. WHEN backend operations occur THEN the system SHALL show connection status and response times
3. WHEN errors occur THEN the system SHALL display detailed error messages for debugging
4. WHEN analysis runs THEN the system SHALL show processing progress and timing information
5. WHEN data is sent THEN the system SHALL display confirmation of successful transmission