// swift-tools-version:6.3
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

import PackageDescription

let swiftSettings: [SwiftSetting] = [
    .enableExperimentalFeature("AnyAppleOSAvailability")
]

let package = Package(
    name: "swift-nio-quic-helpers",
    products: [
        .library(name: "NIOQUICHelpers", targets: ["NIOQUICHelpers"])
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.79.0")
    ],
    targets: [
        .target(
            name: "NIOQUICHelpers",
            dependencies: [
                .product(name: "NIOCore", package: "swift-nio")
            ],
            swiftSettings: swiftSettings
        ),
        .testTarget(
            name: "NIOQUICHelpersTests",
            dependencies: [
                .target(name: "NIOQUICHelpers")
            ],
            swiftSettings: swiftSettings
        ),
    ]
)
