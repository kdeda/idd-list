//
//  Column.swift
//  IDDList
//
//  Created by Klajd Deda on 01/05/23.
//  Copyright (C) 1997-2025 id-design, inc. All rights reserved.
//

import AppKit
import SwiftUI
import Log4swift

public struct Column<RowValue>: Equatable
where RowValue: Identifiable, RowValue: Equatable
{
    public static func == (lhs: Column<RowValue>, rhs: Column<RowValue>) -> Bool {
        lhs.title == rhs.title
        && lhs.id == rhs.id
        && lhs.isVisible == rhs.isVisible
        && lhs.alignment == rhs.alignment
        && lhs.width == rhs.width
        && lhs.columnSort == rhs.columnSort
    }

    enum WidthType: Equatable {
        case fixed(CGFloat)
        case limits(min: CGFloat?, ideal: CGFloat?, max: CGFloat?)

        var frame: (minWidth: CGFloat?, idealWidth: CGFloat?, maxWidth: CGFloat?) {
            switch self {
            case let .fixed(value):            return (minWidth: value, idealWidth: .none, maxWidth: .none)
            case let .limits(min, ideal, max): return (minWidth: min, idealWidth: ideal, maxWidth: max)
            }
        }
    }

    var title: String
    let id: NSUserInterfaceItemIdentifier
    var isVisible: Bool = true
    var isBrowserColumn: Bool = false
    var alignment: Alignment = .leading

    var width: WidthType = .fixed(10)
    var columnSort: ColumnSort<RowValue>
    var cellView: (_ item: RowValue) -> any View

    // MARK: - Introspection -

    public typealias IntrospectBlock = (
        _ tableColumn: NSTableColumn
    ) -> Void

    internal var introspectBlocks: [IntrospectBlock] = []

    // MARK: - Init -

    public init(
        _ title: String,
        id: String = UUID().uuidString,
        cellView: @escaping (_ item: RowValue) -> any View
    ) {
        self.title = title
        self.id = NSUserInterfaceItemIdentifier(rawValue: id)
        // we will create this as an empty instance
        // use the .columnSort modifier to stick a real instance here
        self.columnSort = .init(compare: { _, _ in false }, ascending: false, columnID: "")
        self.cellView = cellView
    }

    public var sortDescriptor: NSSortDescriptor? {
        return columnSort.key.isEmpty
        ? .none
        : NSSortDescriptor.init(columnSort)
    }
}

// MARK: - View Modifiers -

extension Column {
    /// A generic introspection block that allows direct access to the table column object.
    public func introspect(
        _ block: @escaping IntrospectBlock
    ) -> Self {
        var copy = self

        copy.introspectBlocks.append(block)
        return copy
    }

    /// Fixed width
    public func frame(width: CGFloat, alignment: Alignment = .leading) -> Self {
        var copy = self

        copy.width = .fixed(width)
        copy.alignment = alignment
        return copy
    }

    /// We just want to mutate the frame sizes
    public func frame(minWidth: CGFloat = 100, ideal: CGFloat? = nil, maxWidth: CGFloat = 100, alignment: Alignment = .leading) -> Self {
        var copy = self

        copy.width = .limits(min: minWidth, ideal: ideal, max: maxWidth)
        copy.alignment = alignment
        return copy
    }

    public func visible(_ state: Bool) -> Self {
        var copy = self

        copy.isVisible = state
        return copy
    }

    public func columnSort(
        compare: @escaping ColumnSortCompare<RowValue>
    ) -> Self {
        var copy = self

        copy.columnSort = .init(compare: compare, ascending: false, columnID: self.id.rawValue)
        return copy
    }

    /// Slight mutation to adjust the constraints of the cell
    public func makeBrowserColumn() -> Self {
        var copy = self

        copy.isBrowserColumn = true
        return copy
    }
}

extension NSSortDescriptor {
    /**
     Return a fake instance to make AppKit happy
     */
    convenience init<RowValue>(_ columnSort: ColumnSort<RowValue>) {
        // Log4swift[Self.self].info("column: '\(columnSort)'")

        self.init(key: columnSort.key, ascending: columnSort.ascending)
    }
}

/**
 Ideally I wanted this to be a generic where Element is of type TableColumn<RowValue>
 but we can't easily do that right now
 https://forums.swift.org/t/extension-on-array-where-element-is-generic-type/10225/3
 */
extension Array {
    func updateColumnSorts<RowValue>(
        _ initialSelection: Binding<ColumnSort<RowValue>>
    ) -> Array where Element == Column<RowValue>
    {
        /**
         Preserve the state of the column sort. The user has just given us the initialSelection
         which is the truth. The corresponding column sort should reflect that.
         There should be one item typically here under initialSelection.

         This assures the view's initial render to perfectly match the initial state.
         Later on as the columns are sorted up or down, the values will be pushed back into the initialSelection binding and kept in sync.
         */
        let update = self
            .map { column in
                guard column.columnSort.columnID == initialSelection.wrappedValue.columnID
                else { return column }
                   
                var copy = column
                copy.columnSort.ascending = initialSelection.wrappedValue.ascending
                return copy
            }
        return update
    }
}
