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

/// Formats log messages according to a given template with `$`-token support.
/// Supports multiple markers such as `$L`, `$M`, `$T`, `$D...$d`, etc.
/// see `MessageFormatToken.swift`
public struct MessageFormatter: Sendable {
    
    private let startDate = Date()

    public init() {}
    
    /// Formats log string according to given template and context.
    public func format(
        _ msg: Any,
        level: LogLevel,
        subsystem: String,
        category: String,
        thread: String,
        format: String,
        file: String,
        function: String,
        line: Int
    ) -> String {
        var result = ""
        
        // Escape beginning so the first `$` symbol is not mistakenly processed.
        let tokens: [String] = ("$I" + format).components(separatedBy: "$")
        
        for token in tokens where !token.isEmpty {
            guard let tokenChar = token.first,
                  let formatToken = MessageFormatToken(rawValue: tokenChar) else {
                result += token
                continue
            }
            
            let remainder = token.dropFirst()
            
            switch formatToken {
            case .ignore:
                result += remainder
            case .level:
                result += levelString(for: level) + remainder
            case .message:
                result += "\(msg)" + remainder
            case .subsystem:
                result += subsystem + remainder
            case .category:
                result += category + remainder
            case .thread:
                result += thread + remainder
            case .fileNameNoExt:
                result += fileNameWithoutExtension(from: file) + remainder
            case .fileNameFull:
                result += fileName(from: file) + remainder
            case .function:
                result += function + remainder
            case .line:
                result += "\(line)" + remainder
            case .uptime:
                result += uptime + remainder
            case .dateLocalStart:
                result += formatDate(String(remainder), in: .current)
            case .dateLocalEnd:
                result += remainder
            case .dateUTCStart:
                result += formatDate(String(remainder), in: .utc)
            case .dateUTCEnd:
                result += remainder
            }
        }
        
        return result.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    
    // MARK: - Private helpers
    
    /// Returns uptime in `hh:mm:ss.msec` format
    private var uptime: String {
        let interval = Date().timeIntervalSince(startDate)
        let hours = Int(interval) / 3600
        let minutes = (Int(interval) / 60) % 60
        let seconds = Int(interval) % 60
        let milliseconds = Int((interval.truncatingRemainder(dividingBy: 1)) * 1000)
        
        return String(format: "%02d:%02d:%02d.%03d", hours, minutes, seconds, milliseconds)
    }
    
    /// Maps enum `LogLevel` to string representation
    private func levelString(for level: LogLevel) -> String {
        switch level {
        case .debug: "DEBUG"
        case .info: "INFO"
        case .warning: "WARNING"
        case .error: "ERROR"
        }
    }
    
    /// Returns filename with extension
    private func fileName(from path: String) -> String {
        URL(fileURLWithPath: path).lastPathComponent
    }
    
    /// Returns filename without extension
    private func fileNameWithoutExtension(from path: String) -> String {
        URL(fileURLWithPath: path).deletingPathExtension().lastPathComponent
    }
    
    /// Formats current date according to given template and timezone
    private func formatDate(_ format: String, in timeZone: TimeZone) -> String {
        let formatter = DateFormatter()
        formatter.timeZone = timeZone
        formatter.dateFormat = format
        return formatter.string(from: Date())
    }
}

// MARK: - TimeZone convenience

extension TimeZone {
    fileprivate static var utc: TimeZone {
        TimeZone(abbreviation: "UTC") ?? .current
    }
}
