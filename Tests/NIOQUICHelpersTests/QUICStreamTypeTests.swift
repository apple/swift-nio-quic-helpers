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

import NIOQUICHelpers
import Testing

@Suite
struct QUICStreamTypeTests {
    static let streamIDCases: [(QUICStreamID, QUICStreamType)] = [
        // Each pair of bits in the two least significant positions maps to one type.
        (0, .clientInitiatedBidirectional),
        (1, .serverInitiatedBidirectional),
        (2, .clientInitiatedUnidirectional),
        (3, .serverInitiatedUnidirectional),
        // Only the two least significant bits determine the type.
        (400, .clientInitiatedBidirectional),
        (401, .serverInitiatedBidirectional),
        (402, .clientInitiatedUnidirectional),
        (403, .serverInitiatedUnidirectional),
        // Stream IDs are 62-bit; verify near the maximum.
        (QUICStreamID(rawValue: (1 << 62) - 4), .clientInitiatedBidirectional),
        (QUICStreamID(rawValue: (1 << 62) - 3), .serverInitiatedBidirectional),
        (QUICStreamID(rawValue: (1 << 62) - 2), .clientInitiatedUnidirectional),
        (QUICStreamID(rawValue: (1 << 62) - 1), .serverInitiatedUnidirectional),
    ]

    @Test(arguments: Self.streamIDCases)
    func initFromStreamID(streamID: QUICStreamID, expected: QUICStreamType) {
        #expect(QUICStreamType(streamID) == expected)
    }

    @Test
    func isClientInitiated() {
        #expect(QUICStreamType.clientInitiatedBidirectional.isClientInitiated)
        #expect(QUICStreamType.clientInitiatedUnidirectional.isClientInitiated)
        #expect(!QUICStreamType.serverInitiatedBidirectional.isClientInitiated)
        #expect(!QUICStreamType.serverInitiatedUnidirectional.isClientInitiated)
    }

    @Test
    func isServerInitiated() {
        #expect(!QUICStreamType.clientInitiatedBidirectional.isServerInitiated)
        #expect(!QUICStreamType.clientInitiatedUnidirectional.isServerInitiated)
        #expect(QUICStreamType.serverInitiatedBidirectional.isServerInitiated)
        #expect(QUICStreamType.serverInitiatedUnidirectional.isServerInitiated)
    }

    @Test
    func isBidirectional() {
        #expect(QUICStreamType.clientInitiatedBidirectional.isBidirectional)
        #expect(QUICStreamType.serverInitiatedBidirectional.isBidirectional)
        #expect(!QUICStreamType.clientInitiatedUnidirectional.isBidirectional)
        #expect(!QUICStreamType.serverInitiatedUnidirectional.isBidirectional)
    }

    @Test
    func isUnidirectional() {
        #expect(!QUICStreamType.clientInitiatedBidirectional.isUnidirectional)
        #expect(!QUICStreamType.serverInitiatedBidirectional.isUnidirectional)
        #expect(QUICStreamType.clientInitiatedUnidirectional.isUnidirectional)
        #expect(QUICStreamType.serverInitiatedUnidirectional.isUnidirectional)
    }
}
