# iOS Shortcuts for Privacy Credit Analyzer

This directory contains iOS Shortcuts that streamline message import from iMessages for faster credit analysis.

## Available Shortcuts

### 1. Quick Analysis (PrivacyCreditAnalyzer-Quick.shortcut)
- **Messages**: ~200 messages from the last 7 days
- **Processing Time**: ~30 seconds
- **Memory Usage**: ~5MB
- **Best For**: Daily check-ins, recent financial activity, low battery situations

### 2. Standard Analysis (PrivacyCreditAnalyzer-Standard.shortcut)
- **Messages**: ~1,000 messages from the last 30 days
- **Processing Time**: ~2-3 minutes
- **Memory Usage**: ~15-25MB
- **Best For**: Monthly reviews, credit monitoring, general use

### 3. Deep Analysis (PrivacyCreditAnalyzer-Deep.shortcut)
- **Messages**: ~5,000 messages from the last 90 days
- **Processing Time**: ~5-10 minutes
- **Memory Usage**: ~50-75MB
- **Best For**: Loan applications, major financial decisions, comprehensive reports

## Installation Instructions

### Step 1: Download and Install
1. Open the Shortcuts app on your iPhone
2. Tap the "+" button to create a new shortcut
3. Import one of the `.shortcut` files from this directory
4. Alternatively, use the in-app installation flow in Privacy Credit Analyzer

### Step 2: Grant Permissions
1. Run the shortcut for the first time
2. Grant permission to access Messages when prompted
3. Allow the shortcut to share data with Privacy Credit Analyzer
4. Confirm privacy consent (all processing happens on-device)

### Step 3: Test Connection
1. Run the shortcut with a small dataset first
2. Verify that the Privacy Credit Analyzer app opens automatically
3. Check that messages appear in the input field
4. Confirm the analysis runs successfully

## How It Works

### Smart Message Filtering
The shortcuts automatically prioritize:
- **Financial conversations**: Messages containing money, payment, loan, bank, credit, etc.
- **Recent messages**: Newer messages are weighted higher
- **High-frequency contacts**: Close relationships (family, friends)
- **Conversation diversity**: Samples across different contacts

### Data Limits and Sampling
- **Maximum per conversation**: 1,000 messages
- **Maximum total**: 5,000 messages (Deep analysis)
- **Maximum data size**: 10MB
- **Smart sampling**: When limits are exceeded, the shortcut intelligently samples to maintain analysis quality

### Privacy Protection
- ✅ All processing happens on your device
- ✅ No raw message data is transmitted to servers
- ✅ Only processed analysis results are shared (if you choose)
- ✅ Messages are not stored permanently
- ✅ Full GDPR compliance

## Troubleshooting

### Shortcut Not Found
- Open Shortcuts app and search for "Privacy Credit Analyzer"
- Reinstall using the link in the main app
- Ensure you're signed in to the same Apple ID
- Try restarting the Shortcuts app

### Permission Denied
- Open Settings > Privacy & Security > Shortcuts
- Find "Privacy Credit Analyzer" and enable permissions
- Run the shortcut and grant access when prompted
- Try running the shortcut again

### Connection Failed
- Ensure Privacy Credit Analyzer app is installed and up to date
- Check that the URL scheme is correctly configured
- Close and reopen both apps
- Restart your device if the issue persists

### Data Limit Exceeded
- Select fewer conversations or a shorter time range
- Use the Quick analysis option (200 messages, 7 days)
- Focus on conversations with financial content
- The app will automatically sample large datasets

### Processing Timeout
- Select a smaller dataset (fewer messages or shorter time range)
- Close other apps to free up memory
- Ensure your device has sufficient battery
- Try the Quick analysis option for faster processing

## Performance Tips

### For Best Results
- **Battery**: Ensure at least 50% battery for Deep analysis
- **Memory**: Close other apps before running large analyses
- **Network**: No internet connection required (all on-device)
- **Storage**: Ensure at least 1GB free space for temporary processing

### Choosing the Right Analysis
- **Daily monitoring**: Quick Analysis (7 days, 200 messages)
- **Monthly review**: Standard Analysis (30 days, 1,000 messages)
- **Loan applications**: Deep Analysis (90 days, 5,000 messages)
- **Emergency situations**: Quick Analysis for immediate insights

## Technical Details

### Data Format
The shortcuts export data in JSON format with the following structure:
```json
{
  "messages": [
    {
      "id": "uuid",
      "content": "message text",
      "timestamp": "2025-08-23T17:00:00Z",
      "sender": "contact name",
      "recipient": "recipient name",
      "isFromUser": true
    }
  ],
  "extractionDate": "2025-08-23T17:00:00Z",
  "performanceTier": "quick|standard|deep",
  "version": "1.0.0"
}
```

### URL Scheme
The shortcuts communicate with the main app using the custom URL scheme:
```
privacycredit://import?data=<base64_encoded_json>
```

### Security Features
- **Data validation**: All incoming data is validated for size and format
- **Sampling algorithms**: Smart reduction of large datasets
- **Error handling**: Graceful handling of malformed data
- **Privacy indicators**: Clear status of data processing

## Support

If you encounter issues not covered in this guide:
1. Check the in-app troubleshooting section
2. Ensure your iOS version is compatible (iOS 14.0+)
3. Verify that Shortcuts app is up to date
4. Contact support with your device model and iOS version

## Version History

### v1.0.0 (Current)
- Initial release with three performance tiers
- Smart message filtering and sampling
- Privacy-compliant data extraction
- Comprehensive error handling and user guidance