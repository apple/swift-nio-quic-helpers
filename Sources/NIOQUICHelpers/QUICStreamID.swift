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

/// A single QUIC stream ID.
///
/// Streams are identified within a connection by a numeric value, referred to as the stream ID.
/// A stream ID is a 62-bit integer (0 to 2^62-1) that is unique for all streams on a connection.
/// Stream IDs are encoded as variable-length integers.
/// A QUIC endpoint **MUST NOT** reuse a stream ID within a connection.
///
/// The least significant bit (0x1) of the stream ID identifies the initiator of the stream.
/// Client-initiated streams have even-numbered stream IDs (with the bit set to 0),
/// and server-initiated streams have odd-numbered stream IDs (with the bit set to 1).
///
/// The second least significant bit (0x2) of the stream ID distinguishes between
/// bidirectional streams (with the bit set to 0) and unidirectional streams (with the bit set to 1).
///
/// Within each type, streams are created with numerically increasing stream IDs.
/// A stream ID that is used out of order results in all streams of that type with lower-numbered stream IDs also being opened.
/// The first bidirectional stream opened by the client has a stream ID of 0.
public struct QUICStreamID: Hashable, Sendable, RawRepresentable {
    public let rawValue: UInt64

    @available(*, deprecated, renamed: "QUICStreamType")
    public typealias StreamType = QUICStreamType

    /// The type of the stream.
    public var type: QUICStreamType {
        QUICStreamType(self)
    }

    /// Create a `QUICStreamID` for a specific integer value.
    public init(rawValue: UInt64) {
        precondition(rawValue <= QUICEncodableInteger.maxValue)
        self.rawValue = rawValue
    }
}

extension QUICStreamID: Comparable {}

extension QUICStreamID: Strideable {
    public func distance(to other: QUICStreamID) -> Int {
        self.rawValue.distance(to: other.rawValue)
    }

    public func advanced(by n: Int) -> QUICStreamID {
        Self(rawValue: self.rawValue.advanced(by: n))
    }
}

extension UInt64 {
    /// Create a `UInt64` from a specific `QUICStreamID`.
    public init(_ quicStreamID: QUICStreamID) {
        self = quicStreamID.rawValue
    }
}

extension QUICStreamID: CustomStringConvertible {
    public var description: String {
        String(describing: self.rawValue)
    }
}

extension QUICStreamID: ExpressibleByIntegerLiteral {
    public typealias IntegerLiteralType = RawValue

    public init(integerLiteral value: RawValue) {
        self.init(rawValue: value)
    }
}
