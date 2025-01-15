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

// This file defines error types to be thrown by implementations of QUIC when a connection or stream is closed.

/// The remote peer sent a RESET\_STREAM frame.
/// QUIC implementations should throw this error when the remote peer has sent a RESET\_STREAM frame as defined in RFC 9000.
public struct QUICStreamResetError: Error {
    /// The application error code (RFC 9000 § 20.2) sent by the peer which indicates why the stream is being closed.
    public var code: QUICApplicationErrorCode

    /// Create a new ``QUICStreamResetError``.
    /// - Parameter code: The application error code sent by the remote peer.
    public init(code: QUICApplicationErrorCode) {
        self.code = code
    }
}

/// The remote peer sent a STOP\_SENDING frame.
/// QUIC implementations should throw this error when the remote peer has sent a STOP\_SENDING frame as defined in RFC 9000.
public struct QUICStopSendingError: Error {
    /// The application error code (RFC 9000 § 20.2) sent by the peer which indicates why the stream is being closed.
    public var code: QUICApplicationErrorCode

    /// Create a new ``QUICStopSendingError``.
    /// - Parameter code: The application error code sent by the remote peer.
    public init(code: QUICApplicationErrorCode) {
        self.code = code
    }
}

/// The remote peer sent a CONNECTION\_CLOSE frame.
/// QUIC implementations should throw this error when the remote peer has sent a CONNECTION\_CLOSE frame as defined in RFC 9000.
public struct QUICConnectionError: Error {
    /// The reason string sent by the remote peer.
    public var reason: String
    /// True if the error is at the application protocol level.
    public var isApplication: Bool
    /// If ``isApplication`` is `true` then this code is defined by the application protocol (see RFC 9000 § 20.2). Otherwise, it is defined by RFC 9000 § 20.1.
    public var code: UInt64

    /// Create a new ``QUICConnectionError``.
    /// - Parameters:
    ///   - reason: The reason string sent by the remote peer.
    ///   - isApplication: True if the error is at the application protocol level.
    ///   - code: If ``isApplication`` is `true` then this code is defined by the application protocol (see RFC 9000 § 20.2). Otherwise, it is defined by RFC 9000 § 20.1.
    public init(reason: String, isApplication: Bool, code: UInt64) {
        precondition(code <= QUICEncodableInteger.maxValue)
        self.reason = reason
        self.isApplication = isApplication
        self.code = code
    }
}
