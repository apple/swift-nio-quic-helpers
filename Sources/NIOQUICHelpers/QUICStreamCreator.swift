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

public struct QUICStreamInitializerParameters: Sendable {
    public var channel: any Channel
    public var streamID: QUICStreamID

    @inlinable
    public init(channel: any Channel, streamID: QUICStreamID) {
        self.channel = channel
        self.streamID = streamID
    }
}

/// Provides a way to create QUIC streams.
/// Implementations of QUIC should provide a way to get an instance of this on each connection, so users can make outbound streams.
public protocol QUICStreamCreator: Sendable {
    associatedtype Isolated: IsolatedQUICStreamCreator

    /// Creates a new bidirectional stream on the connection.
    ///
    /// - Parameter streamInitializer: A callback that will be invoked to allow you to configure the channel pipeline for the newly created stream channel.
    /// - Returns: A future which is fulfilled once the stream is active.
    func createBidirectionalStream<InitializerOutput: Sendable>(
        streamInitializer: @escaping @Sendable (QUICStreamInitializerParameters) -> EventLoopFuture<InitializerOutput>
    ) -> EventLoopFuture<InitializerOutput>

    /// Creates a new unidirectional stream on the connection.
    ///
    /// - Parameter streamInitializer: A callback that will be invoked to allow you to configure the channel pipeline for the newly created stream channel.
    /// - Returns: A future which is fulfilled once the stream is active.
    func createUnidirectionalStream<InitializerOutput: Sendable>(
        streamInitializer: @escaping @Sendable (QUICStreamInitializerParameters) -> EventLoopFuture<InitializerOutput>
    ) -> EventLoopFuture<InitializerOutput>

    /// Assumes the calling context is isolated to the event loop associated with the QUIC connection.
    func assumeIsolated() -> Isolated
}

public protocol IsolatedQUICStreamCreator {
    /// Creates a new bidirectional stream on the connection.
    ///
    /// - Warning: This function must only be called on the eventloop associated with this QUIC connection.
    ///
    /// - Parameter streamInitializer: A callback that will be invoked to allow you to configure the channel pipeline for the newly created stream channel.
    /// - Returns: A future which is fulfilled once the stream is active.
    func createBidirectionalStream<InitializerOutput: Sendable>(
        streamInitializer: @escaping (QUICStreamInitializerParameters) -> EventLoopFuture<InitializerOutput>
    ) -> EventLoopFuture<InitializerOutput>

    /// Creates a new unidirectional stream on the connection.
    ///
    /// - Warning: This function must only be called on the eventloop associated with this QUIC connection.
    ///
    /// - Parameter streamInitializer: A callback that will be invoked to allow you to configure the channel pipeline for the newly created stream channel.
    /// - Returns: A future which is fulfilled once the stream is active.
    func createUnidirectionalStream<InitializerOutput: Sendable>(
        streamInitializer: @escaping (QUICStreamInitializerParameters) -> EventLoopFuture<InitializerOutput>
    ) -> EventLoopFuture<InitializerOutput>
}
