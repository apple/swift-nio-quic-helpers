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

/// An enum describing the stream type.
public enum QUICStreamType: Sendable, Hashable {
    /// Indicates that the stream is client initiated and bidirectional.
    case clientInitiatedBidirectional
    /// Indicates that the stream is client initiated and unidirectional.
    case clientInitiatedUnidirectional
    /// Indicates that the stream is server initiated and bidirectional.
    case serverInitiatedBidirectional
    /// Indicates that the stream is server initiated and unidirectional.
    case serverInitiatedUnidirectional

    /// Derive the stream type from the ID of a QUIC stream.
    ///
    /// - Parameter streamID: The ID to the stream to get the type of.
    @inlinable
    public init(_ streamID: QUICStreamID) {
        let isClientInitiated = (streamID.rawValue & 0x1) == 0
        let isBidirectional = (streamID.rawValue & 0x2) == 0

        switch (isClientInitiated, isBidirectional) {
        case (true, true):
            self = .clientInitiatedBidirectional
        case (true, false):
            self = .clientInitiatedUnidirectional
        case (false, true):
            self = .serverInitiatedBidirectional
        case (false, false):
            self = .serverInitiatedUnidirectional
        }
    }

    /// Returns whether the client initiated the stream.
    @inlinable
    public var isClientInitiated: Bool {
        switch self {
        case .clientInitiatedBidirectional, .clientInitiatedUnidirectional:
            return true
        case .serverInitiatedBidirectional, .serverInitiatedUnidirectional:
            return false
        }
    }

    /// Returns whether the server initiated the stream.
    @inlinable
    public var isServerInitiated: Bool {
        switch self {
        case .serverInitiatedBidirectional, .serverInitiatedUnidirectional:
            return true
        case .clientInitiatedBidirectional, .clientInitiatedUnidirectional:
            return false
        }
    }

    /// Returns whether the stream is unidirectional.
    @inlinable
    public var isUnidirectional: Bool {
        switch self {
        case .clientInitiatedUnidirectional, .serverInitiatedUnidirectional:
            return true
        case .clientInitiatedBidirectional, .serverInitiatedBidirectional:
            return false
        }
    }

    /// Returns whether the stream is bidirectional.
    @inlinable
    public var isBidirectional: Bool {
        switch self {
        case .clientInitiatedBidirectional, .serverInitiatedBidirectional:
            return true
        case .clientInitiatedUnidirectional, .serverInitiatedUnidirectional:
            return false
        }
    }
}
