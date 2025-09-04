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

// MARK: - Compiler flag

#if RELEASE
    private let isReleaseBuild = true
#else
    private let isReleaseBuild = false
#endif

// MARK: - RedactedValueConvertible

/// Protocol defining behavior of a value that can be redacted during logging or
/// encoding.
///
/// Types implementing this protocol can return a string representation where the original value is hidden.
/// This allows safe logging of sensitive data in production builds.
///
/// In debug builds, the value will be displayed in full.
public protocol RedactedValueConvertible {
    /// Returns either the value itself or `<redacted>`, depending on the build.
    var redacted: String { get }
}

// MARK: - Extensions

extension String: RedactedValueConvertible {
    public var redacted: String {
        isReleaseBuild ? "<redacted>" : self
    }
}

extension Int: RedactedValueConvertible {
    public var redacted: String {
        String(self).redacted
    }
}

extension UUID: RedactedValueConvertible {
    public var redacted: String {
        uuidString.redacted
    }
}

extension Optional: RedactedValueConvertible where Wrapped: RedactedValueConvertible {
    public var redacted: String {
        switch self {
        case let .some(value): value.redacted
        case .none: "nil"
        }
    }
}
