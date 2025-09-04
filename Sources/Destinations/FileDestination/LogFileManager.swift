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

/// Provides thread-safe access to the file system for writing logs.
/// Handles creation, opening, writing, and closing of log files using `DispatchQueue` for synchronization.
///
/// Thread safety is ensured through a serialized file access queue.
///
/// > Note: Class is marked as `@unchecked Sendable`, but access to internal states is only done through
/// `fileAccessQueue`, making it safe for use in multithreaded environments.
///
/// - Warning: Don't forget to call `closeFile()` when finishing work to properly flush buffers and close
/// the file descriptor.
final class LogFileManager: @unchecked Sendable {
    
    private let fileManager = FileManager.default
    
    private let fileUrl: URL
    private let fileAccessQueue: DispatchQueue
    
    private var fileHandle: FileHandle?
    
    /// Initializes the file manager specifying the target file path.
    ///
    /// - Parameter fileUrl: Path to the file where logging will be performed.
    init(fileUrl: URL) {
        let bundleIdentifier = Bundle.module.bundleIdentifier ?? "com.logger"
        let fileAccessQueueLabel = "\(bundleIdentifier).fileManager.\(fileUrl.lastPathComponent)"
        let fileAccessQueue = DispatchQueue(label: fileAccessQueueLabel)

        self.fileUrl = fileUrl
        self.fileAccessQueue = fileAccessQueue
    }
    
    /// Creates file and parent directory if they don't exist yet.
    @discardableResult
    func createFileIfNeeded() throws -> Bool {
        try fileAccessQueue.sync {
            // Create parent directory if needed
            let directory = fileUrl.deletingLastPathComponent()
            if !fileManager.fileExists(atPath: directory.path) {
                try fileManager.createDirectory(at: directory, withIntermediateDirectories: true)
            }

            // If file already exists — do nothing
            guard !fileManager.fileExists(atPath: fileUrl.path) else {
                return false
            }

            // Create file
            guard fileManager.createFile(atPath: fileUrl.path, contents: nil) else {
                throw URLError(.cannotCreateFile)
            }
            
            return true
        }
    }
    
    /// Opens file for writing and moves pointer to the end to avoid overwriting existing data.
    func openFile() throws {
        try fileAccessQueue.sync {
            let fileHandle = try FileHandle(forWritingTo: fileUrl)
            
            // seekToEnd is used to continue writing from the end of file
            try fileHandle.seekToEnd()
            self.fileHandle = fileHandle
        }
    }
    
    /// Writes data to file and synchronizes buffers.
    ///
    /// - Parameter data: Data that needs to be written.
    func write(_ data: Data) throws {
        try fileAccessQueue.sync { [weak self] in
            guard let fileHandle = self?.fileHandle else {
                throw URLError(.fileDoesNotExist)
            }

            try fileHandle.write(contentsOf: data)
            
            // synchronize helps ensure data is actually written to disk
            try fileHandle.synchronize()
        }
    }
    
    /// Closes file and synchronizes data before closing.
    func closeFile() throws {
        try fileAccessQueue.sync {
            guard let fileHandle else { return }
            // Call before closing is necessary to flush buffer to disk
            try fileHandle.synchronize()
            try fileHandle.close()
        }
    }
    
}
