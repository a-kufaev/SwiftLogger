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

/// Property wrapper `@Redacted` hides values when encoding (`Encodable`) in production builds.
///
/// Can be applied to any type conforming to `Encodable` and `RedactedValueConvertible`.
/// This is especially useful when logging `Encodable` models with private fields.
///
/// ### Example:
/// ```swift
/// struct LoginRequest: Encodable {
///     @Redacted var password: String
/// }
/// ```
///
/// In debug build:
/// ```json
/// { "password": "my-secret-password" }
/// ```
///
/// In release build:
/// ```json
/// { "password": "<redacted>" }
/// ```
@propertyWrapper
public struct Redacted<T: Encodable & RedactedValueConvertible>: Encodable {

    /// Original property value.
    public var wrappedValue: T

    public init(wrappedValue: T) {
        self.wrappedValue = wrappedValue
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(wrappedValue.redacted)
    }
}

// Decodable support if type T implements it
extension Redacted: Decodable where T: Decodable {
    
    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        wrappedValue = try container.decode(T.self)
    }
}

// Sendable support if type T implements it
extension Redacted: Sendable where T: Sendable {}

// MARK: — So @Redacted var x: String? decodes safely

extension KeyedDecodingContainer {
    
    /// Swift Codable bug: when using @propertyWrapper over Optional composition
    /// compiler synthesizes `decode(_:forKey:)` via hard `decode(_:)`,
    /// causing JSON null or missing keys to trigger keyNotFound/valueNotFound
    /// before reaching the wrapper's `init(from:)`.
    ///
    /// Bug discussion - https://forums.swift.org/t/using-property-wrappers-with-codable/2980
    ///
    /// Solution: override `decode(_:forKey:)` specifically for `Redacted<Wrapped?>`,
    /// to use safe `decodeIfPresent(_:)` and return `wrappedValue == nil` without crashes
    /// in case of null/missing keys.
    public func decode<Wrapped>(
        _ type: Redacted<Wrapped?>.Type,
        forKey key: Key
    ) throws -> Redacted<Wrapped?> where Wrapped: Decodable {
        // 1) if key exists and is not null → standard path via decodeIfPresent
        if let wrapper = try decodeIfPresent(type, forKey: key) {
            return wrapper
        } else {
            // 2) otherwise (null or keyNotFound) — return wrapper with nil
            return Redacted<Wrapped?>(wrappedValue: nil)
        }
    }
    
}
