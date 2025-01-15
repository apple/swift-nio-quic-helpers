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
import XCTest

final class QUICStreamIDTests: XCTestCase {
    func testStreamType() throws {
        XCTAssertEqual(QUICStreamID(rawValue: 0).type, .clientInitiatedBidirectional)
        XCTAssertEqual(QUICStreamID(rawValue: 1).type, .serverInitiatedBidirectional)
        XCTAssertEqual(QUICStreamID(rawValue: 2).type, .clientInitiatedUnidirectional)
        XCTAssertEqual(QUICStreamID(rawValue: 3).type, .serverInitiatedUnidirectional)
    }

    func testComparable() {
        XCTAssertLessThan(QUICStreamID(rawValue: 0), QUICStreamID(rawValue: 1))
        XCTAssertLessThan(QUICStreamID(rawValue: 1), QUICStreamID(rawValue: 2))
        XCTAssertLessThan(QUICStreamID(rawValue: (2 << 61) - 2), QUICStreamID(rawValue: (2 << 61) - 1))
    }

    func testStrideable() {
        let arrayFromStride = Array(QUICStreamID(rawValue: 10)..<QUICStreamID(rawValue: 12))
        XCTAssertEqual(arrayFromStride, [QUICStreamID(rawValue: 10), QUICStreamID(rawValue: 11)])
    }

    func testUInt64FromQUICStreamID() {
        let uint = UInt64(QUICStreamID(rawValue: 100))
        XCTAssertEqual(uint, 100)
    }

    func testDescription() {
        let description = "\(QUICStreamID(rawValue: 100))"
        XCTAssertEqual(description, "100")
    }
}
