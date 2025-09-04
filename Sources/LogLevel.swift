//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftLogger open source project
//
// Copyright (c) 2025 Artem Kufaev
// Licensed under MIT License
//
// See https://github.com/a-kufaev/SwiftLogger/blob/main/LICENSE for license information
//
//===----------------------------------------------------------------------===//

/// Log level defining the criticality and purpose of a message.
///
/// Used for filtering, routing, and formatting logs.
/// The higher the level, the more serious the message is considered.
///
/// Example level hierarchy:
/// - `debug` → debugging messages
/// - `info` → normal lifecycle and actions
/// - `warning` → warnings, partial failures
/// - `error` → critical errors disrupting functionality
public enum LogLevel: Int, Sendable {
    /// `debug` — messages intended for development only.
    ///
    /// Used for:
    /// - logic debugging
    /// - intermediate value logging
    /// - profiling and UI inspection
    ///
    /// Example:
    /// - `Received response: { ... }`
    /// - `Loading state: .loading`
    /// - `Received event from service: { ... }`
    case debug = 0
    
    /// `info` — standard messages about application workflow.
    ///
    /// Used for:
    /// - user actions (taps, navigation)
    /// - business logic (order submission, session start)
    /// - system events (app launch, environment setup)
    ///
    /// Example:
    /// - `User tapped "Continue"`
    /// - `Application started with configuration: Production`
    /// - `Screen A opened`
    case info = 1
    
    /// `warning` — warnings and errors that don't block application functionality.
    ///
    /// Used for:
    /// - server errors (e.g., 400 or 404)
    /// - network issues (timeouts, cancellations)
    /// - missing expected data
    ///
    /// Example:
    /// - `Authorization error: invalid password`
    /// - `Product not found (404)`
    case warning = 2
    
    /// `error` — critical errors that disrupt application or feature functionality.
    ///
    /// Used for:
    /// - service failures
    /// - inability to continue execution
    /// - unexpected exceptions and logic errors
    ///
    /// Example:
    /// - `Storage initialization error: CoreData failure`
    /// - `Server response: 500 Internal Server Error`
    ///
    /// > Fatal crashes are not logged at this level, but are handled by crash collection tools (e.g.,
    /// Crashlytics).
    case error = 3
}
