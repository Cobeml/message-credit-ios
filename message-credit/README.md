# Privacy Credit Analyzer iOS App

This is the main iOS app for the Privacy Credit Analyzer project. It provides a SwiftUI interface for analyzing messages and displaying personality traits and trustworthiness scores.

## Project Structure

- **message-credit**: Main iOS app with SwiftUI interface
- **PrivacyCreditAnalyzer**: Local Swift package dependency containing core data models

## Features

### ✅ Currently Implemented
- **Text Input**: Manual message entry with multi-line text editor
- **File Import**: Basic file picker for Messages Export files (UI only)
- **Mock Analysis**: Simulated personality and trustworthiness analysis
- **Results Display**: Comprehensive visualization of analysis results
  - Personality traits with progress bars
  - Trustworthiness score with contributing factors
  - Processing metadata and timing information

### 🚧 Coming Next
- **Real Message Parsing**: Parse Messages Export JSON files (Task 2.1)
- **AI Inference**: MLX-Swift integration for on-device analysis (Task 4)
- **Background Processing**: Handle large message volumes (Task 5)
- **Cryptographic Signing**: Sign results for verification (Task 6)

## How to Run

1. **Open the project** in Xcode:
   ```bash
   open message-credit.xcodeproj
   ```

2. **Ensure the PrivacyCreditAnalyzer package is linked**:
   - The package should already be added as a local dependency
   - If not, go to File → Add Package Dependencies → Add Local → Select the `PrivacyCreditAnalyzer` folder

3. **Select a simulator**:
   - Choose iPhone 15 or any iOS 17.0+ simulator

4. **Run the app**:
   - Press Cmd+R or click the Run button
   - The app will launch in the simulator

## Testing the App

### Text Input Analysis
1. Enter some sample messages in the text field
2. Tap "Analyze Messages"
3. View the mock analysis results showing:
   - Big Five personality traits
   - Trustworthiness score with factors
   - Processing information

### File Import (Basic)
1. Tap "Import Messages" button
2. Select a JSON or text file
3. The filename will appear in the text field
4. Note: Actual parsing will be implemented in Task 2.1

## Dependencies

- **iOS 17.0+**: Required for SwiftUI features
- **PrivacyCreditAnalyzer**: Local Swift package with core data models
- **SwiftUI**: For the user interface
- **UniformTypeIdentifiers**: For file type handling

## Development Notes

- The app currently uses mock data for analysis results
- All core data models are fully implemented and tested
- The UI is designed to accommodate real analysis results
- File parsing functionality is stubbed out for future implementation

## Next Steps

To continue development, implement the tasks in order:
1. **Task 2**: Message input and parsing functionality
2. **Task 4**: MLX-Swift AI inference integration
3. **Task 5**: Background processing for large datasets
4. **Task 6**: Cryptographic signing and verification