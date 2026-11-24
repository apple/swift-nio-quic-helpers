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

import NIOCore

/// This is an inbound event that QUIC sends to inform about changes to the active path. The event is fired
/// on the connection channel if either the `remoteAddress` changed or the path was validated. The initial
/// path is always considered validated, so no event is fired when the connection is established.
///
/// The active path is the one on which the highest-numbered non-probing packet was received, see RFC 9000 § 9.3.
public struct QUICPathUpdateEvent: Sendable, Hashable {
    /// The remote address of the path.
    public var remoteAddress: SocketAddress
    /// Validation status of this path.
    public var isValidated: Bool

    /// Create a new ``QUICPathUpdateEvent``.
    /// - Parameter remoteAddress: The peer's address on this path.
    /// - Parameter isValidated: The validation status.
    @inlinable
    public init(
        remoteAddress: SocketAddress,
        isValidated: Bool
    ) {
        self.remoteAddress = remoteAddress
        self.isValidated = isValidated
    }
}
