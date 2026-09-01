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

/// A cache of values keyed by `QUICStreamID`. See ``QUICStreamIDDictionary``.
///
/// Slots are indexed by the numeric part of a stream ID (i.e. `rawValue >> 2`) modulo the capacity
/// of the cache, which is always a power of two so that the modulo can be done by masking.
@usableFromInline
struct QUICStreamIDCache<Value> {
    @usableFromInline
    struct Slot {
        @usableFromInline var _rawKey: UInt64
        @usableFromInline var _value: Optional<Value>

        @inlinable
        var rawKey: UInt64 { self._rawKey }

        @inlinable
        var value: Value? { self._value }

        @inlinable
        init(key: QUICStreamID, value: Value) {
            self._rawKey = key.rawValue
            self._value = value
        }

        @inlinable
        init() {
            self._rawKey = .max  // Not a valid QUICStreamID
            self._value = nil
        }

        @inlinable
        var isEmpty: Bool {
            self._rawKey == .max
        }

        @inlinable
        func containsKey(_ key: QUICStreamID) -> Bool {
            self._rawKey == key.rawValue
        }

        @inlinable
        func value(forKey key: QUICStreamID) -> Value? {
            self._rawKey == key.rawValue ? self._value : nil
        }

        @inlinable
        mutating func removeValue(forKey key: QUICStreamID) -> Value? {
            var value: Value? = nil

            if self._rawKey == key.rawValue {
                self._rawKey = .max
                swap(&value, &self._value)
            }

            return value
        }
    }

    /// The underlying slots in the cache.
    @usableFromInline var _slots: [Slot]

    /// A mask applied to the numeric part of a stream ID (i.e. top 62 bits) to get its slot index.
    /// Stored rather than recomputed to avoid the `Int` to `UInt64` conversion on every lookup.
    @usableFromInline var _mask: UInt64

    /// The value of `count` at which the cache doubles in size.
    @usableFromInline var _nextGrowthCount: Int

    /// The utilisation threshold above which the cache will double in size.
    @usableFromInline let _threshold: Double

    @usableFromInline var _count: Int

    /// The number of elements currently stored in the cache.
    @inlinable
    var count: Int { self._count }

    /// The number of elements that can be stored in the cache.
    @inlinable
    var capacity: Int { self._slots.count }

    /// Whether the cache is empty.
    @inlinable
    var isEmpty: Bool { self._count == 0 }

    @inlinable
    init(capacity: Int, threshold: Double) {
        precondition((0.0...1.0).contains(threshold))
        let capacity = capacity.nextPowerOfTwo
        self._slots = Array(repeating: Slot(), count: capacity)
        self._mask = UInt64(capacity - 1)
        self._threshold = threshold
        self._nextGrowthCount = capacity.scaled(by: threshold)
        self._count = 0
    }

    /// Index of the slot for the given stream ID.
    @inlinable
    func slotIndex(of key: QUICStreamID) -> Int {
        // Drop the type bits and then mask. The mask can be used instead of '%' as the capacity is
        // guaranteed to be a power of two (and the mask is just `capacity - 1`).
        Int((key.rawValue >> 2) & self._mask)
    }

    /// Returns the value for the given stream ID, if it exists in the cache.
    @inlinable
    subscript(key: QUICStreamID) -> Value? {
        let index = self.slotIndex(of: key)
        return self._slots[index].value(forKey: key)
    }

    /// Returns whether the cache contains the given stream ID.
    @inlinable
    func contains(_ key: QUICStreamID) -> Bool {
        self._slots[self.slotIndex(of: key)].containsKey(key)
    }

    @usableFromInline
    enum UpdateResult {
        /// The value was inserted into an empty slot.
        case inserted
        /// The value replaced a value for the same stream ID.
        case replaced(Value)
        /// The value was inserted but evicted a value for a different stream ID.
        case evicted(key: QUICStreamID, value: Value)
    }

    /// Updates the value stored for the given stream ID.
    ///
    /// - Parameters:
    ///   - value: The value to store.
    ///   - key: The ID of the stream.
    /// - Returns: Whether the value was inserted, replaced an existed value, or evicted a value
    ///   for another stream.
    @discardableResult
    @inlinable
    mutating func updateValue(_ value: Value, forKey key: QUICStreamID) -> UpdateResult {
        let index = self.slotIndex(of: key)

        var slot = Slot(key: key, value: value)
        swap(&self._slots[index], &slot)

        if let previous = slot.value {
            if slot.containsKey(key) {
                return .replaced(previous)
            } else {
                assert(!slot.isEmpty)
                return .evicted(key: QUICStreamID(rawValue: slot.rawKey), value: previous)
            }
        } else {
            assert(slot.isEmpty)
            self._count &+= 1
            if self._count >= self._nextGrowthCount {
                self._doubleCapacity()
            }
            return .inserted
        }
    }

    /// Removes the value associated with the given ID, if one exists.
    @discardableResult
    @inlinable
    mutating func removeValue(forKey key: QUICStreamID) -> Value? {
        let index = self.slotIndex(of: key)

        if let value = self._slots[index].removeValue(forKey: key) {
            self._count &-= 1
            return value
        } else {
            return nil
        }
    }

    /// Remove all values in the cache.
    @inlinable
    mutating func removeAll() {
        if self.isEmpty { return }

        self._count = 0
        for index in self._slots.indices {
            self._slots[index] = Slot()
        }
    }

    @inlinable
    @inline(never)
    mutating func _doubleCapacity() {
        // Compute the new capacity, mask and growth count.
        let oldCapacity = self.capacity
        let capacity = oldCapacity * 2
        self._mask = UInt64(capacity - 1)
        self._nextGrowthCount = capacity.scaled(by: self._threshold)

        // Add the new empty slots.
        self._slots.append(contentsOf: repeatElement(Slot(), count: oldCapacity))

        // Doubling capacity effectively splits each slot into two. One slots maintains its place
        // and the other entry either moves by `oldCapacity` slots. This is determined by the bit
        // for the `oldCapacity` (only one bit, because it was a power of two). All of the new slots
        // are vacant.
        let bit = UInt64(oldCapacity)
        for index in 0..<oldCapacity {
            if !self._slots[index].isEmpty && (self._slots[index].rawKey >> 2 & bit) != 0 {
                self._slots.swapAt(index, index | oldCapacity)
            }
        }
    }
}

extension QUICStreamIDCache: Sequence {
    @usableFromInline
    typealias Element = (key: QUICStreamID, value: Value)

    @inlinable
    func makeIterator() -> Iterator {
        Iterator(self._slots.makeIterator())
    }

    @usableFromInline
    struct Iterator: IteratorProtocol {
        @usableFromInline
        var _iterator: [QUICStreamIDCache<Value>.Slot].Iterator

        @inlinable
        init(_ iterator: [QUICStreamIDCache<Value>.Slot].Iterator) {
            self._iterator = iterator
        }

        @inlinable
        mutating func next() -> (key: QUICStreamID, value: Value)? {
            while let slot = self._iterator.next() {
                if let value = slot.value {
                    return (QUICStreamID(rawValue: slot.rawKey), value)
                }
            }
            return nil
        }
    }
}

extension Int {
    @inlinable
    var nextPowerOfTwo: Int {
        precondition(self > 0)
        if self.nonzeroBitCount == 1 {
            return self
        } else {
            return 1 << (Int.bitWidth - self.leadingZeroBitCount)
        }
    }

    @inlinable
    func scaled(by factor: Double) -> Int {
        let scaled = (Double(self) * factor).rounded(.up)
        return Swift.max(1, Int(scaled))
    }
}
