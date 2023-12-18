//
//  TableView.swift
//  IDDList
//
//  Created by Klajd Deda on 01/05/23.
//  Copyright (C) 1997-2023 id-design, inc. All rights reserved.
//

import AppKit
import SwiftUI
import Log4swift

public class TableView<RowValue>: NSTableView
where RowValue: Identifiable, RowValue: Equatable
{
    public var axes: Axis.Set = [.horizontal, .vertical]

    init(columns: [Column<RowValue>]) {
        super.init(frame: .zero)

        // column setup
        columns
            .map(NSTableColumn.init)
            .forEach(self.addTableColumn)

        if columns.count == 1 {
            // since we have just one column we want it to fill the width of the table view
            var last = self.tableColumns[0]
            last.resizingMask = [.autoresizingMask]
            self.sizeLastColumnToFit()

            last = self.tableColumns[0]
            Log4swift[Self.self].debug("width: '\(last.width)'")
        } else {
            /**
             this will attempt to resize each column uniformly
             a column is resizable if it has a Column.WidthType of .limits
             see: Column+NSTableColumn.swift

             the sizing will stretch/compress each sizable column till they reach the min or max width
             so be judicial with your SwiftUI Column.frame call
             */
            self.columnAutoresizingStyle = .uniformColumnAutoresizingStyle
        }

        self.translatesAutoresizingMaskIntoConstraints = false
        self.sortDescriptors = columns.compactMap(\.sortDescriptor)
        self.rowHeight = 22.0

        Log4swift[Self.self].debug("created: '\(self.sortDescriptors)'")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - NSView Overrides -

    // overriding this allows the scroll axes to be constrained
    public override func adjustScroll(_ newVisible: NSRect) -> NSRect {
        if axes == [.horizontal, .vertical] {
            return super.adjustScroll(newVisible)
        }

        var newRect = newVisible
        if !axes.contains(.horizontal) {
            newRect.origin.x = bounds.origin.x
        }

        if !axes.contains(.vertical) {
            newRect.origin.y = bounds.origin.y
        }

        return newRect
    }
}

// MARK: - TableView Convenience -

extension TableView {
    /**
     Reload just the visible cells.
     */
    internal func reloadVisibleRows() {
        let visibleRows = rows(in: visibleRect)
        let updatedRowIndexes = (0 ..< visibleRows.length).map { visibleRows.location + $0 }

        // Log4swift[Self.self].info("tag: '\(self.tag)' detected changes in general ...")
        reloadData(forRowIndexes: IndexSet(updatedRowIndexes), columnIndexes: IndexSet(0 ..< tableColumns.count))
    }
}

// MARK: - TableView Workaround -

extension TableView {
    /**
     this means we have only moves, no inserts or removals
     without this precaution the table view will animate this in a weird almost rotation looking animation
     for tables with large number of rows this will look as if the screen goes blank for a second
     but for a small table with a dozen or so items it become apparent
     Klajd Deda, December 14, 2023
     */
    internal func reloadTableView(insertions: Int, removals: Int) -> Bool {
        guard insertions != removals
        else {
            self.reloadData()
            return false
        }
        return true
    }
}
