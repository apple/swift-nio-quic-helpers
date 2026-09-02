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

@available(anyAppleOS 26, *)
extension QUICStreamIDDictionary {
    /// A view of the stream IDs in the dictionary.
    ///
    /// The order of IDs has no semantic meaning.
    @inlinable
    public var ids: IDs {
        IDs(self)
    }

    /// A view of the values in the dictionary.
    ///
    /// The order of values has no semantic meaning.
    @inlinable
    public var values: Values {
        Values(self)
    }

    /// A view of the stream IDs in a ``QUICStreamIDDictionary``.
    public struct IDs: Sequence {
        @usableFromInline let _dictionary: QUICStreamIDDictionary<Value>

        @inlinable
        init(_ dictionary: QUICStreamIDDictionary<Value>) {
            self._dictionary = dictionary
        }

        /// The number of stream IDs in the view.
        @inlinable
        public var count: Int {
            self._dictionary.count
        }

        /// Whether the view is empty.
        @inlinable
        public var isEmpty: Bool {
            self._dictionary.isEmpty
        }

        /// Returns whether the view contains the given stream ID.
        @inlinable
        public func contains(_ id: QUICStreamID) -> Bool {
            if self._dictionary._caches[self._dictionary._cacheIndex(of: id)].contains(id) {
                return true
            } else {
                return self._dictionary._overflowIndex(of: id) != nil
            }
        }

        @inlinable
        public func makeIterator() -> Iterator {
            Iterator(self._dictionary.makeIterator())
        }

        public struct Iterator: IteratorProtocol {
            @usableFromInline var _iterator: QUICStreamIDDictionary<Value>.Iterator

            @inlinable
            init(_ iterator: QUICStreamIDDictionary<Value>.Iterator) {
                self._iterator = iterator
            }

            @inlinable
            public mutating func next() -> QUICStreamID? {
                self._iterator.next()?.id
            }
        }
    }

    /// A view of the values in a ``QUICStreamIDDictionary``.
    public struct Values: Sequence {
        @usableFromInline let _dictionary: QUICStreamIDDictionary<Value>

        @inlinable
        init(_ dictionary: QUICStreamIDDictionary<Value>) {
            self._dictionary = dictionary
        }

        /// The number of values in the view.
        @inlinable
        public var count: Int {
            self._dictionary.count
        }

        /// Whether the view is empty.
        @inlinable
        public var isEmpty: Bool {
            self._dictionary.isEmpty
        }

        @inlinable
        public func makeIterator() -> Iterator {
            Iterator(self._dictionary.makeIterator())
        }

        public struct Iterator: IteratorProtocol {
            @usableFromInline var _iterator: QUICStreamIDDictionary<Value>.Iterator

            @inlinable
            init(_ iterator: QUICStreamIDDictionary<Value>.Iterator) {
                self._iterator = iterator
            }

            @inlinable
            public mutating func next() -> Value? {
                self._iterator.next()?.value
            }
        }
    }
}
