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

/// Log destination protocol (`LogDestination`) defining the exit point for log messages.
///
/// Concrete implementations can redirect messages to:
/// - console (`ConsoleDestination`)
/// - file (`FileDestination`)
/// - network / crash reporter / telemetry (`NetworkDestination`)
/// - memory (`BufferedDestination`)
///
/// The `write(...)` method accepts detailed call context, including thread, file, and function.
/// This enables maximum flexibility in formatting and routing logs.
public protocol LogDestination: Sendable {
    
    var isActive: Bool { get }
    
    func start() throws
    
    func write(
        _ message: Any,
        level: LogLevel,
        subsystem: String,
        category: String,
        thread: String,
        file: String,
        function: String,
        line: Int
    )
}

