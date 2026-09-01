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

/// A specialized dictionary where QUIC stream IDs are used as keys.
///
/// The dictionary takes advantage of the layout of stream IDs and how they are used in a QUIC
/// connection to provide significantly faster operations than a regular dictionary keyed by stream
/// ID by avoiding hashing in the majority of cases.
///
/// It works by maintaining a cache per stream type which is indexed by the stream ID's numeric bytes
/// (i.e. `rawStreamID >> 2`) modulo the capacity of the cache at the time. Any collisions (in other
/// words, long-lived streams) get evicted and stored into overflow storage.
///
/// Each cache is separately sized and doubles in capacity when its load factor (ratio of occupied
/// slots to capacity) exceeds a threshold. This is naturally bounded by the connection's limit on
/// concurrent streams.
///
/// Overflow storage has two tiers: when there are no more than 32 elements in overflow storage an
/// array is used and a linear scan is used to find the appropriate element. For 33 elements and
/// above a regular dictionary is used. Only one storage tier is used at any one time.
@available(anyAppleOS 26, *)
public struct QUICStreamIDDictionary<Value> {
    /// Caches keyed by the "type bits" of a QUIC stream ID (i.e. `rawValue & 0b11`).
    @usableFromInline var _caches: InlineArray<4, QUICStreamIDCache<Value>>

    @usableFromInline
    struct OverflowEntry {
        @usableFromInline var id: QUICStreamID
        @usableFromInline var value: Value

        @inlinable
        init(id: QUICStreamID, value: Value) {
            self.id = id
            self.value = value
        }
    }

    /// Array of overflow values. Used when the number of overflow values is low.
    ///
    /// Values are moved to the overflow dictionary when `overflowArrayCapacity` are stored. The
    /// order of elements has no semantic meaning.
    ///
    /// Note: Empty when `_overflowDictionary` is non-empty.
    @usableFromInline var _overflowArray: [OverflowEntry]

    /// Dictionary of overflow values.
    ///
    /// Note: Empty when `_overflowArray` is non-empty.
    @usableFromInline var _overflowDictionary: [QUICStreamID: Value]

    /// Number of items in overflow storage.
    ///
    /// Avoids loading a value from the array/dictionary's heap storage on the hot-path.
    @usableFromInline var _overflowCount: Int

    /// The number of values held in `_overflowArray` before switching to `_overflowDictionary`.
    @inlinable
    static var overflowArrayCapacity: Int { 32 }

    /// Returns the cache index to use for a given stream ID.
    @inlinable
    func _cacheIndex(of id: QUICStreamID) -> Int {
        // Bottom two bits are the type bits.
        Int(id.rawValue & 0b11)
    }

    /// Returns the number of elements in the dictionary.
    @inlinable
    public var count: Int {
        var total = self._overflowCount
        total += self._caches[0].count
        total += self._caches[1].count
        total += self._caches[2].count
        total += self._caches[3].count
        return total
    }

    /// Returns whether the dictionary is empty.
    @inlinable
    public var isEmpty: Bool {
        self.count == 0
    }

    /// Create a new dictionary keyed by QUIC stream IDs.
    ///
    /// - Parameters:
    ///   - initialCacheCapacity: The initial capacity of each cache, rounded up to the next power
    ///     of two. Defaults to 16.
    ///   - cacheGrowthThreshold: The utilisation threshold above which a cache will grow, defaults
    ///     to 0.6.
    @inlinable
    public init(initialCacheCapacity: Int = 16, cacheGrowthThreshold: Double = 0.6) {
        self._caches = [
            QUICStreamIDCache(capacity: initialCacheCapacity, threshold: cacheGrowthThreshold),
            QUICStreamIDCache(capacity: initialCacheCapacity, threshold: cacheGrowthThreshold),
            QUICStreamIDCache(capacity: initialCacheCapacity, threshold: cacheGrowthThreshold),
            QUICStreamIDCache(capacity: initialCacheCapacity, threshold: cacheGrowthThreshold),
        ]
        self._overflowArray = []
        self._overflowDictionary = [:]
        self._overflowCount = 0
    }

    /// Returns whether the dictionary contains a value for the given stream ID.
    @inlinable
    public func contains(_ id: QUICStreamID) -> Bool {
        if self._caches[self._cacheIndex(of: id)].contains(id) {
            return true
        } else {
            return self._overflowIndex(of: id) != nil
        }
    }

    /// Returns or updates the value associated with a given ID.
    @inlinable
    public subscript(id: QUICStreamID) -> Value? {
        get {
            if let value = self._caches[self._cacheIndex(of: id)][id] {
                return value
            } else if let position = self._overflowIndex(of: id) {
                return self._overflowValue(at: position)
            } else {
                return nil
            }
        }
        set {
            if let newValue {
                self.updateValue(newValue, forID: id)
            } else {
                self.removeValue(forID: id)
            }
        }
    }

    /// Returns or updates the value associated with a given ID.
    ///
    /// - Parameters:
    ///   - id: The stream ID.
    ///   - defaultValue: The value to use if the dictionary has no value for the given ID.
    @inlinable
    public subscript(
        id: QUICStreamID,
        default defaultValue: @autoclosure () -> Value
    ) -> Value {
        get {
            self[id] ?? defaultValue()
        }
        set {
            self.updateValue(newValue, forID: id)
        }
    }

    /// Updates the value for a given ID, returning the previously set value.
    ///
    /// - Parameters:
    ///   - value: The new value.
    ///   - id: The stream ID to update.
    /// - Returns: The value previously set for the given ID.
    @discardableResult
    @inlinable
    public mutating func updateValue(_ value: Value, forID id: QUICStreamID) -> Value? {
        let previous: Value?

        if self._overflowCount == 0 || self._caches[self._cacheIndex(of: id)].contains(id) {
            // Fast-path: no-overflow values.
            previous = self._insert(value, forID: id)
        } else if let position = self._overflowIndex(of: id) {
            // Value was in the overflow storage.
            previous = self._overflowValue(at: position)
            self._setOverflowValue(value, at: position)
        } else {
            // Value wasn't in overflow.
            previous = self._insert(value, forID: id)
        }

        return previous
    }

    /// Removes the value associated with the given ID.
    @discardableResult
    @inlinable
    public mutating func removeValue(forID id: QUICStreamID) -> Value? {
        if let removed = self._caches[self._cacheIndex(of: id)].removeValue(forID: id) {
            return removed
        } else if self._overflowCount == 0 {
            return nil
        } else {
            return self._removeOverflowValue(forID: id)
        }
    }

    /// Insert a value to the cache, moving evicted values into the overflow storage.
    @inlinable
    mutating func _insert(_ value: Value, forID id: QUICStreamID) -> Value? {
        switch self._caches[self._cacheIndex(of: id)].updateValue(value, forID: id) {
        case .replaced(let previous):
            return previous
        case .inserted:
            return nil
        case .evicted(let evictedID, let evictedValue):
            self._insertOverflow(evictedValue, forID: evictedID)
            return nil
        }
    }

    /// Returns whether the given ID is held in a cache rather than the overflow storage.
    func _testOnly_isCached(_ id: QUICStreamID) -> Bool {
        self._caches[self._cacheIndex(of: id)].contains(id)
    }

    /// Returns whether the given ID is held in the linearly scanned part of the overflow storage.
    func _testOnly_isInOverflowArray(_ id: QUICStreamID) -> Bool {
        switch self._overflowIndex(of: id) {
        case .array:
            return true
        case .dictionary, .none:
            return false
        }
    }

    /// Removes all values.
    @inlinable
    public mutating func removeAll() {
        for index in self._caches.indices {
            self._caches[index].removeAll()
        }
        self._overflowArray.removeAll(keepingCapacity: true)
        self._overflowDictionary.removeAll()
        self._overflowCount = 0
    }
}

@available(anyAppleOS 26, *)
extension QUICStreamIDDictionary {
    @usableFromInline
    enum OverflowIndex {
        case array(Int)
        case dictionary(Dictionary<QUICStreamID, Value>.Index)
    }

    @inlinable
    func _overflowIndex(of id: QUICStreamID) -> OverflowIndex? {
        if self._overflowDictionary.isEmpty {
            for index in self._overflowArray.indices {
                if self._overflowArray[index].id == id {
                    return .array(index)
                }
            }
            return nil
        } else if let index = self._overflowDictionary.index(forKey: id) {
            return .dictionary(index)
        } else {
            return nil
        }
    }

    @inlinable
    func _overflowValue(at position: OverflowIndex) -> Value {
        switch position {
        case .array(let index):
            return self._overflowArray[index].value
        case .dictionary(let index):
            return self._overflowDictionary.values[index]
        }
    }

    @inlinable
    @inline(never)
    mutating func _setOverflowValue(_ value: Value, at position: OverflowIndex) {
        switch position {
        case .array(let index):
            self._overflowArray[index].value = value
        case .dictionary(let index):
            self._overflowDictionary.values[index] = value
        }
    }

    @inlinable
    @inline(never)
    mutating func _insertOverflow(_ value: Value, forID id: QUICStreamID) {
        if self._overflowDictionary.isEmpty {
            if self._overflowArray.count < Self.overflowArrayCapacity {
                if self._overflowArray.isEmpty {
                    self._overflowArray.reserveCapacity(Self.overflowArrayCapacity)
                }
                self._overflowArray.append(OverflowEntry(id: id, value: value))
            } else {
                self._switchOverflowToDictionary(inserting: value, forID: id)
            }
        } else {
            self._overflowDictionary[id] = value
        }
        self._overflowCount &+= 1
    }

    @inlinable
    @inline(never)
    mutating func _switchOverflowToDictionary(
        inserting value: Value,
        forID id: QUICStreamID
    ) {
        self._overflowDictionary.reserveCapacity(self._overflowArray.count + 1)
        for entry in self._overflowArray {
            self._overflowDictionary[entry.id] = entry.value
        }
        self._overflowDictionary[id] = value
        self._overflowArray.removeAll(keepingCapacity: true)
    }

    @inlinable
    @inline(never)
    mutating func _removeOverflowValue(forID id: QUICStreamID) -> Value? {
        switch self._overflowIndex(of: id) {
        case .array(let index):
            self._overflowCount &-= 1
            // Order has no meaning: swap with the final element to make removal O(1).
            let lastIndex = self._overflowArray.index(before: self._overflowArray.endIndex)
            self._overflowArray.swapAt(index, lastIndex)
            return self._overflowArray.removeLast().value

        case .dictionary(let index):
            self._overflowCount &-= 1
            return self._overflowDictionary.remove(at: index).value

        case .none:
            return nil
        }
    }
}

@available(anyAppleOS 26, *)
extension QUICStreamIDDictionary: Sequence {
    public typealias Element = (QUICStreamID, Value)

    @inlinable
    public func makeIterator() -> Iterator {
        Iterator(storage: self)
    }

    public struct Iterator: IteratorProtocol {
        @usableFromInline let _storage: QUICStreamIDDictionary<Value>
        @usableFromInline var _state: State

        @usableFromInline
        enum State {
            case iteratingCache(Int, QUICStreamIDCache<Value>.Iterator)
            case iteratingOverflowArray([OverflowEntry].Iterator)
            case iteratingOverflowDictionary([QUICStreamID: Value].Iterator)
            case finished
        }

        @inlinable
        init(storage: QUICStreamIDDictionary<Value>) {
            let index = storage._caches.startIndex
            self._state = .iteratingCache(index, storage._caches[index].makeIterator())
            self._storage = storage
        }

        @inlinable
        public mutating func next() -> (QUICStreamID, Value)? {
            while true {
                switch self._state {
                case .iteratingCache(let index, var iterator):
                    self._state = .finished

                    if let value = iterator.next() {
                        self._state = .iteratingCache(index, iterator)
                        return value
                    } else {
                        let nextIndex = self._storage._caches.index(after: index)

                        if nextIndex == self._storage._caches.endIndex {
                            let iterator = self._storage._overflowArray.makeIterator()
                            self._state = .iteratingOverflowArray(iterator)
                        } else {
                            // Next cache.
                            let nextIterator = self._storage._caches[nextIndex].makeIterator()
                            self._state = .iteratingCache(nextIndex, nextIterator)
                        }
                    }

                case .iteratingOverflowArray(var iterator):
                    self._state = .finished

                    if let entry = iterator.next() {
                        self._state = .iteratingOverflowArray(iterator)
                        return (entry.id, entry.value)
                    } else {
                        let iterator = self._storage._overflowDictionary.makeIterator()
                        self._state = .iteratingOverflowDictionary(iterator)
                    }

                case .iteratingOverflowDictionary(var iterator):
                    self._state = .finished

                    if let value = iterator.next() {
                        self._state = .iteratingOverflowDictionary(iterator)
                        return value
                    } else {
                        self._state = .finished
                    }

                case .finished:
                    return nil
                }
            }
        }
    }
}
