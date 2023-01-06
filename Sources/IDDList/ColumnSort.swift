//
//  ColumnSort.swift
//  IDDList
//
//  Created by Klajd Deda on 01/05/23.
//  Copyright (C) 1997-2023 id-design, inc. All rights reserved.
//

import AppKit
import SwiftUI

public typealias ColumnSortCompare<RowValue> = (_ lhs: RowValue, _ rhs: RowValue) -> Bool

/// Models the column sort implementation for a particular List column
/// We wanted to use KeyPaths for this and avoid introducing an extra generic for the value
/// The solution here is type erasure. We collect the strong type upon init, but than we earse it
public struct ColumnSort<RowValue> where RowValue: Equatable {
    private let compare: ColumnSortCompare<RowValue>
    public var ascending = false
    public let columnID: NSUserInterfaceItemIdentifier

    public init(
        compare: @escaping ColumnSortCompare<RowValue>,
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
