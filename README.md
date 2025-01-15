# SwiftNIO QUIC Helpers

SwiftNIO QUIC Helpers provides types which support the integration of
[SwiftNIO QUIC][swift-nio-quic] and [SwiftNIO HTTP/3][swift-nio-http3].

> [!IMPORTANT]
> This package is still in active development and does not offer a stable API
> yet.

## Getting Started

### Prerequisites

- [Swift 6.3 and up](https://swift.org/install)
- macOS 26.0 and up or Linux (Ubuntu 22.04+)
- Xcode 26.0 and up (Apple platforms only)

### Building and testing

To build via the command line (for all platforms), run at the root of the
package:

```
swift build
```

To run all unit tests, run

```
swift test
```

Unit tests can also be run by filtering a specific class or function:

```
swift test --filter QUICStreamIDTests
swift test --filter QUICStreamIDTests.testDescription
```

[swift-nio-quic]: https://github.com/apple/swift-nio-quic
[swift-nio-http3]: https://github.com/apple/swift-nio-http3
