# App Debugging Guide

## 🔍 What I've Added for Debugging

### 1. **Comprehensive Logging Chain**
The app now logs every initialization step:

```
🚀 App main initialization started           <- App launch
📱 Environment: iOS Simulator               <- Environment detection  
💾 Available memory: 8.0 GB                <- System info
🔧 RootView initialization started          <- RootView init
🔍 RootView body evaluated - users count: 0 <- Core Data check
📋 Showing SignInView - no users found      <- Which view is shown
🚀 ContentView initialization started       <- ContentView init (if shown)
📱 ContentView.onAppear called              <- View appearance
🔧 Initializing PresetDataManager...        <- Component init
✅ PresetDataManager initialized             <- Success confirmation
```

### 2. **Safe Initialization**
- Converted `@StateObject presetManager` to `@State presetManager?` with lazy loading
- Added early crash detection in all main views
- Protected all presetManager usage with nil checks

### 3. **Breakpoint Analysis**
The breakpoint you saw suggests the crash is happening during SwiftUI property wrapper initialization:
```
property wrapper backing initializer of ContentView.selectedFileInfo
```

This could be caused by:
1. **Memory pressure** during initialization
2. **Core Data conflicts** 
3. **Complex property initialization chain**

## 🚀 Next Steps

### Immediate Testing:
1. **Run the app** and watch the console
2. **Look for the logging chain** - it will show exactly where it stops
3. **If no logs appear**, the crash is happening even earlier

### If Still No Logs:
The crash might be happening during the property wrapper initialization itself. Try this minimal version:

**Replace ContentView init with:**
```swift
init() {
    print("🚀 ContentView init - Step 1")
    // Don't call CrashDetector yet - it might be causing the issue
}
```

### If Logs Appear But Stop:
The logs will show exactly where the crash occurs, like:
- "✅ PresetDataManager initialized" ← Last successful step
- Missing next log ← Crash point identified

## 🔧 Debugging Commands

In Xcode console, after crash:
```
(lldb) po selectedFileInfo
(lldb) po presetManager  
(lldb) bt
```

## 📱 Environment Check

The app should now clearly show which environment it's running in and provide detailed initialization tracking.

Run the app and let me know:
1. **What logs do you see?** (if any)
2. **Where do the logs stop?** (last successful message)
3. **Any different error messages?**

This will pinpoint the exact cause of the crash.