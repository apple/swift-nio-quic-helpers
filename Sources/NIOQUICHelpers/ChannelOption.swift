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

extension ChannelOptions.Types {
    /// Get the ID of the current QUIC stream.
    /// Implementations of QUIC should make this option available on their stream channels.
    public struct QUICStreamIDChannelOption: ChannelOption, Sendable {
        public typealias Value = UInt64
    }
}

extension ChannelOption where Self == ChannelOptions.Types.QUICStreamIDChannelOption {
    /// Get the ID of the current QUIC stream.
    /// Implementations of QUIC should make this option available on their stream channels.
    public static var quicStreamID: Self { .init() }
}

extension ChannelOptions.Types {
    /// Opt in to half-closure semantics for received STOP_SENDING frames.
    ///
    /// When set to `true`, a received STOP_SENDING only half-closes the outbound (write) side
    /// of the stream. The inbound (read) side remains open and a ``QUICStopSendingEvent`` is
    /// fired as a user inbound event so the application can react.
    ///
    /// When `false` (the default), a received STOP_SENDING closes the entire channel with
    /// a ``QUICStopSendingError``, which is the safe default for applications that don't
    /// handle half-closure.
    public struct HalfCloseOnStopSendingChannelOption: ChannelOption, Sendable {
        public typealias Value = Bool
        public init() {}
    }
}

extension ChannelOption where Self == ChannelOptions.Types.HalfCloseOnStopSendingChannelOption {
    /// Opt in to half-closure semantics for received STOP_SENDING frames.
    public static var halfCloseOnStopSending: Self { .init() }
}

extension ChannelOptions.Types {
    /// The current round-trip time estimate of the QUIC connection. Implementations of QUIC should make this option
    /// available on connection channels.
    public struct RTTEstimateChannelOption: ChannelOption, Sendable {
        public typealias Value = TimeAmount
    }
}

extension ChannelOption where Self == ChannelOptions.Types.RTTEstimateChannelOption {
    /// The current round-trip time estimate of the QUIC connection. Implementations of QUIC should make this option
    /// available on connection channels.
    public static var rttEstimate: Self { .init() }
}
