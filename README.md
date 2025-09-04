# SwiftLogger

A modern, thread-safe logging library for Swift with support for multiple destinations, flexible formatting, and privacy-focused features.

## Features

- 🚀 **Thread-safe logging** with DispatchQueue synchronization
- 📱 **Multiple destinations** - Console, File, and extensible architecture
- 🎨 **Flexible formatting** with template-based message formatting
- 🔒 **Privacy-first** with `@Redacted` property wrapper for sensitive data
- 📊 **Multiple log levels** - debug, info, warning, error
- 🛠 **Easy integration** with Swift Package Manager
- 🏃‍♂️ **High performance** with @autoclosure for lazy evaluation

## Installation

### Swift Package Manager

Add SwiftLogger to your project using Xcode or by adding it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/a-kufaev/SwiftLogger.git", from: "1.0.0")
]
```

## Quick Start

```swift
import SwiftLogger

// Create and configure logger
let logger = Logger()
logger.addDestination(ConsoleDestination(format: "$U [$L] $M"))
logger.start()

// Log messages
logger.info("Application started", subsystem: "com.example.app", category: "App")
logger.debug("UI State: .loading", subsystem: "com.example.app", category: "UI")
logger.warning("Access token expired", subsystem: "com.example.app", category: "Network")
logger.error("Database initialization failed", subsystem: "com.example.app", category: "Storage")
```

## Philosophy

SwiftLogger follows the **Unix philosophy**: "Do one thing and do it well."

**🎯 Focused Core** - Essential logging infrastructure without bloat  
**🔧 Infinite Extensibility** - Create custom destinations via `LogDestination` protocol  
**⚡ Performance First** - Modern Swift concurrency with lazy evaluation  
**🔒 Privacy by Design** - Automatic data redaction with `@Redacted`

## Format Tokens

SwiftLogger supports flexible message formatting with the following tokens:

| Token | Description | Example |
|-------|-------------|---------|
| `$M` | Message | User tapped button |
| `$L` | Level | INFO, DEBUG, WARNING, ERROR |
| `$S` | Subsystem | com.example.app |
| `$C` | Category | Network, Auth, UI |
| `$T` | Thread | MainThread, Thread: 0x... |
| `$N` | Filename (no extension) | AppDelegate |
| `$F` | Function name | viewDidLoad |
| `$l` | Line number | 42 |
| `$U` | Uptime | 00:03:42.123 |
| `$D...$d` | Local time | 2025-01-03 14:52:01 |
| `$Z...$z` | UTC time | 10:52:01.123 |

### Format Examples

```swift
// Simple format
"[$L] $M"
// Output: [INFO] User logged in

// Detailed format with time and location
"$ZHH:mm:ss$z [$L] $N.$F:$l - $M"
// Output: 14:52:01 [INFO] AppDelegate.applicationDidFinishLaunching:42 - App started

// Production format with uptime
"$U [$L] <$C> $M"
// Output: 00:03:42.123 [INFO] <Network> API request completed
```

## Destinations

### Console Destination

Logs to system console using `os.Logger`:

```swift
let consoleDestination = ConsoleDestination(format: "$U [$L] $M")
logger.addDestination(consoleDestination)
```

### File Destination

Logs to a specified file:

```swift
let documentsPath = FileManager.default.urls(for: .documentDirectory, 
                                           in: .userDomainMask).first!
let logFileURL = documentsPath.appendingPathComponent("app.log")
let fileDestination = FileDestination(format: "$ZHH:mm:ss$z [$L] $M", 
                                    fileUrl: logFileURL)
logger.addDestination(fileDestination)
```

### Custom Destinations

Create custom destinations by implementing the `LogDestination` protocol:

```swift
public protocol LogDestination: Sendable {
    var isActive: Bool { get }
    func start() throws
    func write(_ message: Any, level: LogLevel, subsystem: String, 
               category: String, thread: String, file: String, 
               function: String, line: Int)
}
```

Examples: network logging, database storage, analytics integration, file rotation, crash reporting, or any custom logic your app needs.

## Privacy & Security

SwiftLogger includes a `@Redacted` property wrapper to automatically hide sensitive data in production builds:

```swift
struct LoginRequest: Encodable {
    let username: String
    @Redacted var password: String
}

let request = LoginRequest(username: "john", password: "secret123")
logger.debug(request, subsystem: "com.example.app", category: "Auth")

// Debug build output: {"username": "john", "password": "secret123"}
// Release build output: {"username": "john", "password": "<redacted>"}
```

## Log Levels

| Level | Usage | Example |
|-------|-------|---------|
| `debug` | Development debugging, temporary values | State changes, API responses |
| `info` | Standard application workflow | User actions, system events |
| `warning` | Non-critical errors that don't block functionality | API errors (404, 400), network timeouts |
| `error` | Critical errors that disrupt functionality | Database failures, service crashes |

## Performance

SwiftLogger is designed for high performance:

- **Lazy evaluation** with `@autoclosure` - messages are only formatted when needed
- **Thread-safe** operations using dedicated DispatchQueue
- **Efficient filtering** - logs below the current level are ignored early
- **Minimal overhead** when logging is disabled

## Advanced Usage

### Multiple Destinations

```swift
let logger = Logger()

// Add console logging for development
logger.addDestination(ConsoleDestination(format: "[$L] $M"))

// Add file logging for persistence
let fileURL = getDocumentsDirectory().appendingPathComponent("debug.log")
logger.addDestination(FileDestination(format: "$ZHH:mm:ss$z [$L] $N:$l $M", 
                                    fileUrl: fileURL))

// Set minimum log level
logger.level = .info

logger.start()
```

### Thread Information

SwiftLogger automatically captures and formats thread information:

```swift
// On main thread: "MainThread"
// On background thread: "Thread: 0x600003e31b80 - com.apple.root.background-qos"
```

## Requirements

- iOS 14.0+
- Swift 6.0+
- Xcode 16.0+

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

SwiftLogger is available under the MIT license. See the [LICENSE](https://github.com/a-kufaev/SwiftLogger/blob/main/LICENSE) file for more info.

