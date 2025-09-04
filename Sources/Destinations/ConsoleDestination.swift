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

import os

/// Destination implementation (`LogDestination`) that outputs log messages to system log (`os.Logger`).
///
/// Uses the formatting template provided during initialization and formats messages
/// via `MessageFormatter`. Messages are then sent to `os.Logger`, accessible in console and tools like
/// Console.app.
///
/// Typically used as console/system output during development or production.
public final class ConsoleDestination: LogDestination {
    
    private let formatter = MessageFormatter()
    private let format: String
    
    public private(set) nonisolated(unsafe) var isActive: Bool = false
    
    /// Initializes `ConsoleDestination` with the given formatting template.
    ///
    /// - Parameter format: Formatting template supporting `$M`, `$L`, `$T` and other tokens (see
    /// `MessageFormatToken`).
    public init(format: String) {
        self.format = format
    }
    
    /// Activates the log destination for console.
    ///
    /// For console output, preliminary initialization is not required,
    /// so the method simply sets the `isActive` flag to `true`.
    public func start() throws {
        isActive = true
    }
    
    /// Writes a message to system log via `os.Logger`, applying formatting.
    ///
    /// - Parameters:
    ///   - message: The log message itself (any value).
    ///   - level: Log level (`debug`, `info`, `warning`, `error`).
    ///   - subsystem: Subsystem identifier (usually `Bundle.identifier`).
    ///   - category: Log category (e.g., `Auth`, `Network`, `UI`).
    ///   - thread: Current thread information (formatted).
    ///   - file: Source file path.
    ///   - function: Function name from which the log was called.
    ///   - line: Call line number.
    public func write(
        _ message: Any,
        level: LogLevel,
        subsystem: String,
        category: String,
        thread: String,
        file: String,
        function: String,
        line: Int
    ) {
        let formattedMessage = formatter.format(
            message,
            level: level,
            subsystem: subsystem,
            category: category,
            thread: thread,
            format: format,
            file: file,
            function: function,
            line: line
        )
        let logger = os.Logger(subsystem: subsystem, category: category)
        logger.log(level: level.osLogType, "\(formattedMessage)")
    }
}

// MARK: - LogLevel+OSLogType

extension LogLevel {
    
    fileprivate var osLogType: OSLogType {
        switch self {
        case .debug:
            .debug
        case .info:
            .info
        case .warning:
            .error
        case .error:
            .fault
        }
    }
}
