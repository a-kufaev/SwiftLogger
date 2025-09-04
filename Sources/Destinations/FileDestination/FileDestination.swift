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

import Foundation

/// `FileDestination` — `LogDestination` implementation that writes log messages to a file.
///
/// Uses thread-safe `LogFileManager` for file system operations and `MessageFormatter`
/// for formatting messages before writing.
///
/// Supports custom string formatting and saves messages to the specified file.
public final class FileDestination: LogDestination {
    
    private let formatter = MessageFormatter()
    private let fileManager: LogFileManager
    private let format: String
    
    public private(set) nonisolated(unsafe) var isActive: Bool = false
    
    /// Initializes a new `FileDestination` instance.
    ///
    /// - Parameters:
    ///   - format: Log string format (e.g., template with level, file, function variables, etc.).
    ///   - fileUrl: URL specifying the path to the file where logs will be written.
    public init(
        format: String,
        fileUrl: URL
    ) {
        self.format = format
        fileManager = LogFileManager(fileUrl: fileUrl)
    }
    
    deinit {
        do {
            try fileManager.closeFile()
        } catch {
            assertionFailure("Failed to close file: \(error.localizedDescription)")
        }
    }
    
    /// Opens the file and prepares it for log writing.
    public func start() throws {
        try fileManager.createFileIfNeeded()
        try fileManager.openFile()
        isActive = true
    }
    
    /// Writes the formatted message to file.
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
        let message = formatter.format(
            message,
            level: level,
            subsystem: subsystem,
            category: category,
            thread: thread,
            format: format,
            file: file,
            function: function,
            line: line
        ) + "\n"
        
        guard let data = message.data(using: .utf8) else {
            assertionFailure("Failed to convert message to data")
            return
        }
        
        do {
            if try fileManager.createFileIfNeeded() {
                try fileManager.openFile()
            }
            
            try fileManager.write(data)
        } catch {
            assertionFailure("Error writing to file: \(error.localizedDescription)")
        }
    }
}
