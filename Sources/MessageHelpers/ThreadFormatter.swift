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

/// Responsible for formatting the current execution thread for logging.
enum ThreadFormatter {
    
    /// Formats a human-readable thread description.
    ///
    /// - MainThread → `MainThread`
    /// - Others → `Thread: 0x<address> - <queue_name>`
    static func formatThread(_ thread: Thread) -> String {
        if thread.isMainThread {
            "MainThread"
        } else {
            "Thread: \(trimAddress(of: thread)) - \(queueName(for: thread))"
        }
    }
    
    /// Returns trimmed thread address, like `0x600003e31b80`
    private static func trimAddress(of thread: Thread) -> String {
        let pointer = Unmanaged.passUnretained(thread).toOpaque()
        return String(format: "0x%lx", UInt(bitPattern: pointer))
    }

    /// Returns queue name or thread description
    private static func queueName(for thread: Thread) -> String {
        guard let label = String(validatingCString: __dispatch_queue_get_label(nil)) else {
            return thread.description
        }
        return label.isEmpty ? thread.description : label
    }
}
