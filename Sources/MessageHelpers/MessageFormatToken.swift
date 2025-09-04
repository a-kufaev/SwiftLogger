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

/// Represents supported formatting tokens
/// used in the logger's log message template.
///
/// Each token is denoted by the `$` symbol and replaced during formatting
/// with the corresponding value from the logger call context.
///
/// Template example:
/// ```
/// $ZHH:mm:ss.SSS$z $U [$L] <$T> $N.$F:$l [$C ($S)] - $M
/// ```
/// Possible result:
/// ```
/// 13:01:22.123 00:00:04.532 [INFO] <MainThread> AppDelegate.applicationDidFinishLaunching:42 [App (com.example.app)] -
/// Startup completed
/// ```
///
/// You can combine tokens in any order and add other text data between them.
/// Some of them, like `$D...$d` and `$Z...$z`, wrap user-defined date format.
enum MessageFormatToken: Character, CaseIterable {
    /// `$L` — log level (`DEBUG`, `INFO`, `WARNING`, `ERROR`, etc.)
    case level = "L"

    /// `$M` — message text passed to the logger
    case message = "M"

    /// `$S` — subsystem, e.g., `com.example.myapp` (used in os.Logger / os_log)
    case subsystem = "S"

    /// `$C` — log category, e.g., `Network`, `Auth`, `UI` (from os.Logger)
    case category = "C"

    /// `$T` — thread execution description (format depends on thread, see `ThreadFormatter`)
    case thread = "T"

    /// `$N` — filename without extension, e.g., `AppDelegate`
    case fileNameNoExt = "N"
    
    /// `$n` — full filename with extension, e.g., `AppDelegate.swift`
    case fileNameFull = "n"

    /// `$F` — function name from which the log was called (e.g., `applicationDidFinishLaunching`)
    case function = "F"

    /// `$l` — line number where the log was called
    case line = "l"

    /// `$U` — application uptime in `hh:mm:ss.msec` format since startup
    case uptime = "U"

    /// `$D...$d` — formatted date/time in local timezone.
    /// Format is specified between `$D` and `$d`, e.g.:
    /// `$Dyyyy-MM-dd HH:mm:ss$d` → `2025-03-28 14:52:01`
    case dateLocalStart = "D"
    /// Closing token for `$D...$d`
    case dateLocalEnd = "d"

    /// `$Z...$z` — formatted date/time in UTC.
    /// Format is specified between `$Z` and `$z`, e.g.:
    /// `$ZHH:mm:ss.SSS$z` → `10:52:01.123`
    case dateUTCStart = "Z"
    /// Closing token for `$Z...$z`
    case dateUTCEnd = "z"

    /// `$I` — insertion of arbitrary text without token interpretation (escaping beginning)
    case ignore = "I"
}
