//===----------------------------------------------------------------------===//
//
// This source file is part of the SwiftNIO open source project
//
// Copyright (c) 2026 Apple Inc. and the SwiftNIO project authors
// Licensed under Apache License v2.0
//
// See LICENSE.txt for license information
// See CONTRIBUTORS.txt for the list of SwiftNIO project authors
//
// SPDX-License-Identifier: Apache-2.0
//
//===----------------------------------------------------------------------===//

/// An application-defined error code carried in QUIC STOP\_SENDING,
/// RESET\_STREAM, and CONNECTION\_CLOSE frames.
///
/// Unlike transport error codes (RFC 9000 § 20.1), application error codes
/// are opaque to the QUIC transport and their meaning is defined entirely
/// by the application protocol (e.g. HTTP/3). See RFC 9000 § 20.2.
public struct QUICApplicationErrorCode: Hashable, Sendable, CustomStringConvertible {
    /// The raw error code value. Must be less than 2^62.
    public let rawValue: UInt64

    /// Create a new ``QUICApplicationErrorCode``.
    /// - Parameter rawValue: The application protocol error code. Must be less than 2^62.
    /// - Returns: `nil` if `rawValue` exceeds the maximum QUIC variable-length integer value.
    @inlinable
    public init?(_ rawValue: UInt64) {
        if rawValue <= QUICEncodableInteger.maxValue {
            self.rawValue = rawValue
        } else {
            return nil
        }
    }

    @inlinable
    public var description: String {
        String(self.rawValue)
    }
}
