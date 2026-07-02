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

### Versioning

While the library is in the 0.x.x version range, you should adopt it using
the `.upToNextMinor(from: "0.1.0")` specifier. During this period, breaking
changes are intended to map to minor version bumps, so depending on the
library this way picks up smaller, non-breaking changes automatically while
protecting against API-breaking ones.
