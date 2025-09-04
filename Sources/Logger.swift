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


/// Logger responsible for managing logs and sending them to destinations.
///
/// `Logger` implements basic logging infrastructure:
/// - supports different log levels: `.debug`, `.info`, `.warning`, `.error`
/// - allows connecting multiple logging destinations (console, file, network, etc.)
/// - uses a queue for synchronous and thread-safe execution
///
/// - Warning: Before use, you must call `start()` and add at least one destination via
/// `addDestination(_)`.
///
/// ## Usage Example
///
/// ```swift
/// let logger = Logger()
/// logger.addDestination(ConsoleDestination(format: "$U [$L] $M"))
/// logger.start()
///
/// logger.info("Application started", subsystem: "com.example.app", category: "App")
/// logger.debug("UI State: .loading", subsystem: "com.example.app", category: "Splash Screen")
/// logger.warning("Access token expired", subsystem: "com.example.app", category: "Network")
/// logger.error("Database initialization failed", subsystem: "com.example.app", category: "Storage")
/// ```
///
/// ## Formatting Settings
/// Message format can be arbitrary, supporting the following tokens:
///
/// - `$M` – message
/// - `$L` – level (debug / info / warning / error)
/// - `$S` – subsystem (e.g., bundle identifier)
/// - `$C` – category (e.g., `Network`, `Auth`)
/// - `$T` – thread (MainThread, Thread: 0x...)
/// - `$N` – filename without extension
/// - `$F` – function name
/// - `$l` – line number
/// - `$U` – uptime since logger start
/// - `$D...$d` – local time in specified format
/// - `$Z...$z` – UTC time
///
/// ## Logging Levels
///
/// Levels are used for filtering and routing logs. For example:
///
/// - `.debug` — debugging, temporary values, states
/// - `.info` — user actions, system events
/// - `.warning` — non-critical failures, API errors
/// - `.error` — critical errors, service failures
///
/// ## Formatted Output Example
///
/// ```
/// 00:03:42.123 [INFO] Event: On tap confirm. Attributes:
/// - screen: Profile
/// - step: 2
/// ```
///
/// All calls are synchronized through a private `DispatchQueue` for thread safety and log sequencing.
public final class Logger: Sendable {
    
    // MARK: - Queue

    /// Unique logger queue label based on bundle ID
    private static var queueLabel: String {
        (Bundle.module.bundleIdentifier ?? "com.logger") + ".queue"
    }

    /// Queue for synchronizing state access and log sending
    private let queue = DispatchQueue(label: queueLabel)
    
    // MARK: - Destinations

    /// Registered log destinations (console, file, network, etc.)
    ///
    /// Stored in unsafe context, access occurs only through `queue`.
    private nonisolated(unsafe) var destinations: [any LogDestination] = []

    // MARK: - Logging Level

    /// Log level determining which messages will be processed.
    ///
    /// For example, if set to `.info`, then `debug` messages are ignored.
    /// Changes occur asynchronously through the queue.
    public var level: LogLevel {
        get { queue.sync { _level } }
        set { queue.async { [weak self] in self?._level = newValue } }
    }

    /// Internal storage of current log level
    private nonisolated(unsafe) var _level: LogLevel = .info
    
    // MARK: - Activity

    /// Flag indicating whether the logger is active
    public var isActive: Bool {
        queue.sync { _isActive }
    }

    /// Internal activity state storage
    private nonisolated(unsafe) var _isActive = false
    
    // MARK: - Start Message
    
    /// Logger startup message.
    ///
    /// Includes list of destination types and active logging level.
    private var startedEventMessage: String {
        """
        Logger has started with properties:
        - Destinations: \(destinations.map { "\(type(of: $0.self)) (\($0.isActive ? "active" : "NOT active"))" })
        - Logging level: \(_level)
        """
    }

    // MARK: - Initialization

    /// Creates a new logger instance.
    /// After creation, you must call `start()` and register destinations via `addDestination(_:)`.
    public init() {}

    // MARK: - Configuration

    /// Adds a new log destination (e.g., console, file, network).
    ///
    /// Called before or after `start()`. Destinations are not removed.
    ///
    /// - Parameter destination: Object implementing `LogDestination`.
    public func addDestination(_ destination: any LogDestination) {
        queue.async { [weak self] in
            self?.destinations.append(destination)
        }
    }

    /// Activates the logger. Without calling this method, logs will not be processed.
    ///
    /// Repeated calls are ignored.
    public func start() {
        queue.async { [weak self] in
            guard let self, !_isActive else { return }
            
            _isActive = true
            
            let bundleIdentifier = Bundle.module.bundleIdentifier ?? "unknown"
            
            for destination in destinations {
                do {
                    try destination.start()
                } catch {
                    log(
                        "Destination is not started, \(error.localizedDescription)",
                        level: .error,
                        subsystem: bundleIdentifier,
                        category: "\(type(of: destination.self))",
                        thread: ThreadFormatter.formatThread(.current)
                    )
                }
            }
            
            let startedEventMessage = startedEventMessage
            log(
                startedEventMessage,
                level: .info,
                subsystem: bundleIdentifier,
                category: "Logger",
                thread: ThreadFormatter.formatThread(.current)
            )
        }
    }
    
    /// Logs a message with `.debug` level.
    ///
    /// The message is passed as `@autoclosure`, allowing passing any values without prior
    /// transformation.
    /// These can be strings, numbers, arrays, dictionaries, structures, etc.
    ///
    /// ### Usage Examples:
    ///
    /// ```swift
    /// logger.debug("Data loading completed")
    /// ```
    ///
    /// ```swift
    /// logger.debug(userID) // Int
    /// ```
    ///
    /// ```swift
    /// logger.debug(["id": 42, "role": "admin"])
    /// ```
    ///
    /// ```swift
    /// struct State: CustomStringConvertible {
    ///     let isLoading: Bool
    ///     var description: String { "State(isLoading: \(isLoading))" }
    /// }
    /// logger.debug(State(isLoading: true))
    /// ```
    ///
    /// - Parameters:
    ///   - message: Message to be logged. Can be of any type — `String`, `Int`, `Error`, `Encodable`,
    /// etc.
    ///   Thanks to `@autoclosure`, the message is computed only when needed (e.g., if the log
    ///   level allows it).
    ///   - subsystem: Subsystem name — typically `Bundle.identifier`. Also used in `os.Logger`.
    ///   - category: Category reflecting logging context — e.g., `UI`, `Auth`, `Network`.
    ///   - file: Source file path. Automatically inserted at call site.
    ///   - function: Function name. Automatically inserted at call site.
    ///   - line: Line number. Automatically inserted at call site.
    public func debug(
        _ message: @escaping @Sendable @autoclosure () -> Any,
        subsystem: String,
        category: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        addToQueue(
            message,
            level: .debug,
            subsystem: subsystem,
            category: category,
            thread: ThreadFormatter.formatThread(.current),
            file: file,
            function: function,
            line: line
        )
    }
    
    /// Logs a message with `.info` level.
    ///
    /// The message is passed as `@autoclosure`, allowing passing any values without prior
    /// transformation.
    /// These can be strings, numbers, arrays, dictionaries, structures, etc.
    ///
    /// ### Usage Examples:
    ///
    /// ```swift
    /// logger.info("User tapped 'Continue' button", subsystem: "com.example.app", category: "UI")
    /// ```
    ///
    /// ```swift
    /// logger.info(userID, subsystem: "com.example.app", category: "Auth")
    /// // userID: Int or UUID — will be converted to string
    /// ```
    ///
    /// ```swift
    /// logger.info(["screen": "profile", "action": "opened"], subsystem: "com.example.app", category: "Analytics")
    /// // Array or dictionary will also be converted to string
    /// ```
    ///
    /// ```swift
    /// struct Order: Encodable, CustomStringConvertible {
    ///     let id: String
    ///     let amount: Double
    ///     var description: String { "Order(id: \(id), amount: \(amount))" }
    /// }
    /// let order = Order(id: "123", amount: 99.9)
    /// logger.info(order, subsystem: "com.example.app", category: "Checkout")
    /// ```
    ///
    /// - Parameters:
    ///   - message: Message to be logged. Can be of any type — `String`, `Int`, `Error`, `Encodable`,
    ///   etc. Thanks to `@autoclosure`, the message is computed only when needed (e.g., if the log
    ///   level allows it).
    ///   - subsystem: Subsystem name — typically `Bundle.identifier`. Also used in `os.Logger`.
    ///   - category: Category reflecting logging context — e.g., `UI`, `Auth`, `Network`.
    ///   - file: Source file path. Automatically inserted at call site.
    ///   - function: Function name. Automatically inserted at call site.
    ///   - line: Line number. Automatically inserted at call site.
    public func info(
        _ message: @escaping @Sendable @autoclosure () -> Any,
        subsystem: String,
        category: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        addToQueue(
            message,
            level: .info,
            subsystem: subsystem,
            category: category,
            thread: ThreadFormatter.formatThread(.current),
            file: file,
            function: function,
            line: line
        )
    }
    
    /// Logs a message with `.warning` level.
    ///
    /// The message is passed as `@autoclosure`, allowing passing any values without prior
    /// transformation.
    /// These can be strings, numbers, arrays, dictionaries, structures, etc.
    ///
    /// ### Usage Examples:
    ///
    /// ```swift
    /// // Backend error (e.g., 404 or 400)
    /// logger.warning("Failed to load product: 404 Not Found", subsystem: "com.example.app", category: "Network")
    /// ```
    ///
    /// ```swift
    /// // Data validation issue
    /// logger.warning("Invalid email entered: \(email)", subsystem: "com.example.app", category: "Form")
    /// ```
    ///
    /// ```swift
    /// // Request timeout
    /// logger.warning("Timeout while fetching user profile", subsystem: "com.example.app", category:
    /// "Network")
    /// ```
    ///
    /// ```swift
    /// // Missing expected data
    /// logger.warning("Response missing required field `user_id`", subsystem: "com.example.app", category:
    /// "Parsing")
    /// ```
    ///
    /// ```swift
    /// struct Order: Encodable, CustomStringConvertible {
    ///     let id: String
    ///     let amount: Double
    ///     var description: String { "Order(id: \(id), amount: \(amount))" }
    /// }
    /// let order = Order(id: "123", amount: 99.9)
    /// logger.info(order, subsystem: "com.example.app", category: "Checkout")
    /// ```
    ///
    /// - Parameters:
    ///   - message: Message to be logged. Can be of any type — `String`, `Int`, `Error`, `Encodable`,
    ///   etc. Thanks to `@autoclosure`, the message is computed only when needed (e.g., if the log
    ///   level allows it).
    ///   - subsystem: Subsystem name — typically `Bundle.identifier`. Also used in `os.Logger`.
    ///   - category: Category reflecting logging context — e.g., `UI`, `Auth`, `Network`.
    ///   - file: Source file path. Automatically inserted at call site.
    ///   - function: Function name. Automatically inserted at call site.
    ///   - line: Line number. Automatically inserted at call site.
    public func warning(
        _ message: @escaping @Sendable @autoclosure () -> Any,
        subsystem: String,
        category: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        addToQueue(
            message,
            level: .warning,
            subsystem: subsystem,
            category: category,
            thread: ThreadFormatter.formatThread(.current),
            file: file,
            function: function,
            line: line
        )
    }
    
    /// Logs a message with `.error` level.
    ///
    /// The message is passed as `@autoclosure`, allowing passing any values without prior
    /// transformation.
    /// These can be strings, numbers, arrays, dictionaries, structures, etc.
    ///
    /// ### Usage Examples:
    ///
    /// ```swift
    /// // Database initialization error
    /// logger.error("Failed to initialize storage: \(error.localizedDescription)", subsystem:
    /// "com.example.app", category: "Storage")
    /// ```
    ///
    /// ```swift
    /// // Business logic error
    ///  logger.error("Payment failed: invalid order status", subsystem: "com.example.app", category: "Checkout")
    /// ```
    ///
    /// ```swift
    /// // Critical internal API error
    /// logger.error(apiError, subsystem: "com.example.app", category: "Network")
    /// ```
    ///
    /// ```swift
    /// // Unexpected exception
    /// logger.error("Unexpected nil while parsing server response", subsystem: "com.example.app", category: "Parsing")
    /// ```
    ///
    /// - Parameters:
    ///   - message: Message to be logged. Can be of any type — `String`, `Int`, `Error`, `Encodable`,
    ///   etc. Thanks to `@autoclosure`, the message is computed only when needed (e.g., if the log
    ///   level allows it).
    ///   - subsystem: Subsystem name — typically `Bundle.identifier`. Also used in `os.Logger`.
    ///   - category: Category reflecting logging context — e.g., `UI`, `Auth`, `Network`.
    ///   - file: Source file path. Automatically inserted at call site.
    ///   - function: Function name. Automatically inserted at call site.
    ///   - line: Line number. Automatically inserted at call site.
    public func error(
        _ message: @escaping @Sendable @autoclosure () -> Any,
        subsystem: String,
        category: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        addToQueue(
            message,
            level: .error,
            subsystem: subsystem,
            category: category,
            thread: ThreadFormatter.formatThread(.current),
            file: file,
            function: function,
            line: line
        )
    }
    
    /// Adds a log message to the logger's queue.
    ///
    /// Used by all public methods (`info`, `debug`, `error`, etc.).
    private func addToQueue(
        _ message: @escaping @Sendable @autoclosure () -> Any,
        level: LogLevel,
        subsystem: String,
        category: String,
        thread: String,
        file: String,
        function: String,
        line: Int
    ) {
        queue.async { [weak self] in
            self?.log(
                message(),
                level: level,
                subsystem: subsystem,
                category: category,
                thread: thread,
                file: file,
                function: function,
                line: line
            )
        }
    }
    
    // MARK: - Internal log sending method
    
    /// Internal method called from the logger queue that sends logs to `destinations`.
    ///
    /// Performs log level and activity checks.
    private func log(
        _ message: @escaping @autoclosure () -> Any,
        level: LogLevel,
        subsystem: String,
        category: String,
        thread: String,
        file: String = #file,
        function: String = #function,
        line: Int = #line
    ) {
        guard _isActive, _level.rawValue <= level.rawValue else { return }
        
        for destination in destinations.filter(\.isActive) {
            destination.write(
                message(),
                level: level,
                subsystem: subsystem,
                category: category,
                thread: thread,
                file: file,
                function: function,
                line: line
            )
        }
    }
}

private class BundleFinder {}
extension Bundle {
    static let module = Bundle(for: BundleFinder.self)
}

