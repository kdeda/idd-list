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
    var tagID: String = ""
    @Binding private var makeFirstResponder: Bool

    /**
     Default value does nothing.
     You can set this value during the implementation of your .introspect
     ```
     .introspect { tableView, scrollView in
         tableView.intercellSpacing = .init(width: 10, height: 0)
         tableView.usesAlternatingRowBackgroundColors = true
         tableView.doubleClick = {
             store.send(.doubleClick($0))
         }
     }
     ```
     */
    public var doubleClick: (_ selectedRowIndexes: IndexSet) -> Void = { _ in }

    init(
        columns: [Column<RowValue>],
        makeFirstResponder: Binding<Bool> = .constant(false)
    ) {
        self._makeFirstResponder = makeFirstResponder
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
            Log4swift[Self.self].trace("width: '\(last.width)'")
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

        self.sortDescriptors = columns.compactMap(\.sortDescriptor)
        self.rowHeight = 22.0
        self.doubleAction = #selector(doubleActionIMP(_:))

        Log4swift[Self.self].trace("created: '\(self.sortDescriptors)'")
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Private -

    fileprivate func rowIDs(_ indexes: IndexSet) -> [RowValue.ID] {
        let rowIDs = indexes
            .map { dataSource?.tableView?(self, objectValueFor: nil, row: $0) }
            .compactMap { $0 as? RowValue }
            .map(\.id)

        return rowIDs
    }

    // MARK: - NSView Overrides -

    /**
     Push changes back into the model
     */
    public override func selectRowIndexes(_ indexes: IndexSet, byExtendingSelection extend: Bool) {
        Log4swift[Self.self].debug("tagID: '\(tagID)' will select, rowIDs: '\(rowIDs(indexes))'")
        super.selectRowIndexes(indexes, byExtendingSelection: extend)

        Log4swift[Self.self].debug("tagID: '\(tagID)' did select, rowIDs: '\(rowIDs(self.selectedRowIndexes))'")
        let notification = Notification(name: NSTableView.selectionDidChangeNotification, object: self, userInfo: nil)
        self.delegate?.tableViewSelectionDidChange?(notification)
    }

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

    /**
     This handles the push from the UI to the model
     We get here usually by the ui engine to tell us we are now focused
     */
    public override func becomeFirstResponder() -> Bool {
        Log4swift[Self.self].debug("tagID: '\(tagID)' makeFirstResponder was: '\(self.makeFirstResponder)'")

        let rv = super.becomeFirstResponder()
        if rv {
            Log4swift[Self.self].debug("tagID: '\(tagID)' makeFirstResponder: '\(true)'")
            if !self.makeFirstResponder {
                // avoid pushing the binding more than needed
                self.makeFirstResponder = true
            }
        }
        return rv
    }

    /**
     This handles the push from the UI to the model
     We get here usually by the ui engine to tell us we are not focused anymore
     */
    public override func resignFirstResponder() -> Bool {
        Log4swift[Self.self].debug("tagID: '\(tagID)' makeFirstResponder was: '\(self.makeFirstResponder)'")

        let rv = super.resignFirstResponder()
        if rv {
            Log4swift[Self.self].debug("tagID: '\(tagID)' makeFirstResponder: '\(false)'")
            if self.makeFirstResponder {
                // avoid pushing the binding more than needed
                self.makeFirstResponder = false
            }
        }
        return rv
    }

    @objc private func doubleActionIMP(_ sender: Any) {
        doubleClick(self.selectedRowIndexes)
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

        // Log4swift[Self.self].info("tagID: '\(self.tag)' detected changes in general ...")
        reloadData(forRowIndexes: IndexSet(updatedRowIndexes), columnIndexes: IndexSet(0 ..< tableColumns.count))
    }
}
