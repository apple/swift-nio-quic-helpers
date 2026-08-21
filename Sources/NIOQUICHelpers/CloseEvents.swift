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

// This file defines types to be used by protocols above QUIC to inform the QUIC layer that they wish to close a connection or stream.

/// Send this as an outbound event on the QUIC connection channel to trigger a close of that connection.
/// QUIC implementations should listen for this event and send a CONNECTION\_CLOSE frame as defined in RFC 9000.
public struct QUICCloseConnectionEvent: Sendable {
    /// The application error code indicating the reason for closing this connection.
    public var code: QUICApplicationErrorCode

    /// Additional diagnostic information for the closure. This can be zero length if the sender chooses not to give details beyond the Error Code value. This SHOULD be a UTF-8 encoded string [RFC3629], though the frame does not carry information, such as language tags, that would aid comprehension by any entity other than the one that created the text.
    public var reasonPhrase: String?

    /// Create a new ``QUICCloseConnectionEvent``.
    /// - Parameters:
    ///   - code: The application error code indicating the reason for closing this connection.
    ///   - reasonPhrase: Additional diagnostic information for the closure.
    @inlinable
    public init(code: QUICApplicationErrorCode, reasonPhrase: String?) {
        self.code = code
        self.reasonPhrase = reasonPhrase
    }
}

/// Send this as an outbound event on a QUIC stream channel to trigger a close of the receiving part of  that stream.
/// QUIC implementations should listen for this event and send a STOP\_SENDING frame as defined in RFC 9000.
public struct QUICStopSendingEvent: Sendable {
    /// The application error code indicating the reason for closing this stream.
    public var code: QUICApplicationErrorCode

    /// Create a new ``QUICStopSendingEvent``.
    /// - Parameter code: The application error code indicating the reason for closing this stream.
    @inlinable
    public init(code: QUICApplicationErrorCode) {
        self.code = code
    }
}

/// Send this as an outbound event on a QUIC stream channel to trigger a close of the sending part of that stream.
/// QUIC implementations should listen for this event and send a RESET\_STREAM frame as defined in RFC 9000.
public struct QUICResetStreamEvent: Sendable {
    /// The application error code indicating the reason for closing this stream.
    public var code: QUICApplicationErrorCode

    /// Create a new ``QUICResetStreamEvent``.
    /// - Parameter code: The application error code indicating the reason for closing this stream.
    @inlinable
    public init(code: QUICApplicationErrorCode) {
        self.code = code
    }
}
