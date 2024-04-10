//
//  ColumnSort.swift
//  IDDList
//
//  Created by Klajd Deda on 01/05/23.
//  Copyright (C) 1997-2023 id-design, inc. All rights reserved.
//

import AppKit
import SwiftUI

public typealias ColumnSortCompare<RowValue> = @Sendable (_ lhs: RowValue, _ rhs: RowValue) -> Bool

/// Models the column sort implementation for a particular List column
/// We wanted to use KeyPaths for this and avoid introducing an extra generic for the value
/// The solution here is type erasure. We collect the strong type upon init, but than we earse it
public struct ColumnSort<RowValue> where RowValue: Equatable, RowValue: Sendable {
    internal var compare: ColumnSortCompare<RowValue>
    public var ascending = false
    public let columnID: NSUserInterfaceItemIdentifier

    public init(
        compare: @escaping ColumnSortCompare<RowValue> = { _, _ in true },
        ascending: Bool = false,
        columnID: String = ""
    ) {
        self.compare = compare
        self.ascending = ascending
        self.columnID = NSUserInterfaceItemIdentifier(rawValue: columnID)
    }

    public var key: String {
        columnID.rawValue
    }

    public func comparator(_ lhs: RowValue, _ rhs: RowValue) -> Bool {
        return ascending ? compare(lhs, rhs) : compare(rhs, lhs)
    }
}

extension ColumnSort: Equatable {
    /// We are doing this to play nice with TCA
    /// There are no easy ways to implement Equatable with function variables
    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.columnID == rhs.columnID
        && lhs.ascending == rhs.ascending
    }
}

extension ColumnSort: Sendable {
}

/**
 Helper struct to save/load a column sort meta data from UserDefaults

 Example Declaration
 ```
 final class struct Foo {
   /// The default sort we start at
   @BindingState var columnSort: ColumnSort<TableNode> = .init(ascending: false, columnID: "On Disk")
   /// The value we use to read/write this in user defaults
   @UserDefaultsValue(ColumnSortPersistence(ascending: false, columnID: "On Disk"), forKey: "Foo.savedColumnSort") var columnSortPersistence: ColumnSortPersistence

   init() {
     // when we are initialized we will pluck the last value saved
     self.columnSort = .init(persistence: self.columnSortPersistence)
   }

   /// save the changes, so we can remember it for the next application launch
   func setColumnSort(_ newValue: ColumnSort<TableNode>) {
     columnSort = newValue
     columnSortPersistence = newValue.persistence
   }
 }
 ```
 */
public struct ColumnSortPersistence: Equatable, Codable, Sendable {
    public let ascending: Bool
    public let columnID: String

    public init(
        ascending: Bool = false,
        columnID: String
    ) {
        self.ascending = ascending
        self.columnID = columnID
    }
}

extension ColumnSort {
    public init(persistence: ColumnSortPersistence) {
        self.init(ascending: persistence.ascending, columnID: persistence.columnID)
    }

    public var persistence: ColumnSortPersistence {
        ColumnSortPersistence(ascending: self.ascending, columnID: self.columnID.rawValue)
    }
}
