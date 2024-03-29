//
//  IDDList.swift
//  IDDList
//
//  Created by Klajd Deda on 01/05/23.
//  Copyright (C) 1997-2023 id-design, inc. All rights reserved.
//

import AppKit
import SwiftUI
import IDDSwift
import Log4swift
import DifferenceKit

public struct IDDList<RowValue>: NSViewRepresentable
where RowValue: Equatable, RowValue: Identifiable, RowValue: Hashable
{
    enum SelectionType {
        case single
        case multiple
    }

    private var rows: [TableRowValue<RowValue>]
    private var selectionType: SelectionType
    @Binding private var singleSelection: RowValue.ID?
    @Binding private var multipleSelection: Set<RowValue.ID>

    /**
     We can sort by one column at a time
     */
    @Binding private var columnSort: ColumnSort<RowValue>
    /**
     A mechanism by which we can make this view first responder.
     It will come handy when one has to nagivate between a few tables, say on a column browser view :-)
     This is an optional binding so it will not affect older users of this code or people that do not care about this.
     Right now the only user of this is the WhatSize v8 column browser view.
     */
    @Binding private var makeFirstResponder: Bool
    @State public var columns: [Column<RowValue>]
    @State private var tableFrame: CGRect = .zero
    var tagID: String = ""

    private var selectedRows: IndexSet {
        let indexArray: [Int] = {
            switch selectionType {
            case .single:
                if let rowIndex = rows.firstIndex(where: { $0.id == singleSelection }) {
                    return [rowIndex]
                }
                return []
            case .multiple:
                return rows.enumerated()
                    .filter { multipleSelection.contains($0.element.id) }
                    .map { $0.offset }
            }
        }()

        return IndexSet(indexArray)
    }

    private func buildTableView() -> TableView<RowValue> {
        let rv = TableView<RowValue>(columns: columns)

        rv.allowsMultipleSelection = selectionType == .multiple
        // data source
        rv.axes = [.horizontal, .vertical]
        rv.sortDescriptors = [columnSort].compactMap(NSSortDescriptor.init)
        rv.tagID = tagID

        return rv
    }

    private func buildScrollView(tableView: TableView<RowValue>) -> TableScrollView<RowValue> {
        let rv = TableScrollView<RowValue>(tableView: tableView)

        rv.translatesAutoresizingMaskIntoConstraints = false // has no effect?
        // we want the gutters to always show
        rv.autohidesScrollers = false
        rv.hasVerticalScroller = true
        rv.hasHorizontalScroller = false

        // prevent glitchy behavior when axes are constrained
        rv.verticalScrollElasticity = .automatic // scrollAxes.contains(.vertical) ? .automatic : .none
        rv.horizontalScrollElasticity = .none // scrollAxes.contains(.horizontal) ? .automatic : .none

        rv.documentView = tableView
        return rv
    }

    // MARK: - Introspection -
    
    public typealias IntrospectBlock = (
        _ tableView: TableView<RowValue>,
        _ scrollView: TableScrollView<RowValue>
    ) -> Void
    
    internal var introspectBlocks: [IntrospectBlock] = []
    
    // MARK: - Init -

    /**
     This can be called often.
     We should not push any changes back through the bindings for example.
     */
    public init(
        _ rows: [RowValue],
        singleSelection: Binding<RowValue.ID?>,
        columnSort: Binding<ColumnSort<RowValue>> = .constant(.init()),
        makeFirstResponder: Binding<Bool> = .constant(false),
        @ColumnBuilder<RowValue> columns: () -> [Column<RowValue>]
    ) {
        self.rows = rows.map(TableRowValue.init(rowValue:))
        self.selectionType = .single
        self._singleSelection = singleSelection
        self._multipleSelection = .constant(Set())
        self._columnSort = columnSort
        self._makeFirstResponder = makeFirstResponder

        let updatedColumns = columns().updateColumnSorts(columnSort)
        self._columns = State(initialValue: updatedColumns)

        // Log4swift[Self.self].info("")
    }

    /**
     This can be called often.
     We should not push any changes back through the bindings for example.
     */
    public init(
        _ rows: [RowValue],
        multipleSelection: Binding<Set<RowValue.ID>>,
        columnSort: Binding<ColumnSort<RowValue>> = .constant(.init()),
        makeFirstResponder: Binding<Bool> = .constant(false),
        @ColumnBuilder<RowValue> columns: () -> [Column<RowValue>]
    ) {
        self.rows = rows.map(TableRowValue.init(rowValue:))
        self.selectionType = .multiple
        self._singleSelection = .constant(.none)
        self._multipleSelection = multipleSelection
        self._columnSort = columnSort
        self._makeFirstResponder = makeFirstResponder

        let updatedColumns = columns().updateColumnSorts(columnSort)
        self._columns = State(initialValue: updatedColumns)

        // Log4swift[Self.self].info("")
    }

    public func tag(_ tagID: String) -> Self {
        var copy = self

        copy.tagID = tagID
        return copy
    }

    // MARK: - NSViewRepresentable overrides -

    /**
     Gets called once per view "identity"
     */
    public func makeNSView(context: Context) -> TableScrollView<RowValue> {
        let tableView = buildTableView()
        let scrollView = buildScrollView(tableView: tableView)

        tableView.delegate = context.coordinator
        tableView.dataSource = context.coordinator
        tableView.intercellSpacing = .init(width: 10, height: 1)

        // introspection blocks
        for block in introspectBlocks {
            block(tableView, scrollView)
        }

        if let sortDescriptor = tableView.sortDescriptors.first,
           let sortedColumn = tableView.tableColumns.first(where: { $0.sortDescriptorPrototype == sortDescriptor }) {
            context.coordinator.tableView(tableView, mouseDownInHeaderOf: sortedColumn)
        }

        if let selected = self.columns.first(where: { $0.columnSort.columnID == self.columnSort.columnID }) {
            /**
             We are being rendered and want to co-ordinate the compare func with the model
             They might have set a columnSort usually based on id
             */
            DispatchQueue.main.async {
                /**
                 Publishing changes from within view updates is not allowed, this will cause undefined behavior.
                 do it after the current run loop
                 */
                self.columnSort.compare = selected.columnSort.compare
            }
        }

        Log4swift[Self.self].info("tagID: '\(tagID)'")
        return scrollView
    }

    /**
     Return true if the selection in our view does not match the selection binding.
     */
    private func selectionHasChanged(_ tableView: TableView<RowValue>) -> Bool {
        let selectedRowIndexes = tableView.selectedRowIndexes

        switch selectionType {
        case .single:
            let existing = selectedRowIndexes.map { rows[$0].id }.first
            return singleSelection != existing
        case .multiple:
            let existing = Set(selectedRowIndexes.map { rows[$0].id })
            return multipleSelection != existing
        }
    }

    /**
     Return the rows we shall select, derived from the selection binding.
     */
    private func selectedIndexes() -> IndexSet {
        switch selectionType {
        case .single:
            if let existing = rows.firstIndex(where: { $0.id == singleSelection}) {
                return IndexSet([existing])
            }
            return IndexSet()
        case .multiple:
            let rows = rows.enumerated()
                .filter { multipleSelection.contains($0.element.id) }
                .map(\.offset)
            return IndexSet(rows)
        }
    }

    /**
     Gets called whenever `model` changes. So probably frequently
     */
    public func updateNSView(_ nsView: TableScrollView<RowValue>, context: Context) {
        guard context.coordinator.updateStatus != .fromCoordinator
        else { return }
        context.coordinator.updateStatus = .fromNSView
        defer { context.coordinator.updateStatus = .none }

        let tableView = nsView.tableView
        context.coordinator.parent = self
        let isFirstResponder = tableView.window?.firstResponder == tableView

        Log4swift[Self.self].debug("tag: '\(tagID)' makeFirstResponder: '\(makeFirstResponder)' isFirstResponder: '\(isFirstResponder)'")
        if makeFirstResponder && !isFirstResponder {
            /**
             We are told to become firstResponder, so we can handle key events.
             We need to do this once, so we relinquish the makeFirstResponder by setting it to false
             */
            Log4swift[Self.self].info("tag: '\(tagID)' makeFirstResponder: '\(makeFirstResponder)'")
            makeFirstResponder = false
            tableView.window?.makeFirstResponder(tableView)
        }

        if context.coordinator.rows != rows {
            /**
             This is Ryo Aoyama's code order 'O(N)`
             It flies ... Why does apple write such crappy code

             version 2.1.4

             Old code
             2023-12-14 20:01:03.575 <16883> [I 1c44e58] <IDDList.IDDList<TCATable.File> reloadDataWithAnimations_v1()>   found: '18576 updates' from rows: '37152' in: '23489.753 ms'
             2023-12-14 20:01:54.262 <16883> [I 1c44e58] <IDDList.IDDList<TCATable.File> reloadDataWithAnimations_v1()>   found: '18576 updates' from rows: '55728' in: '24138.001 ms'

             New code
             2023-12-14 19:59:37.683 <16789> [I 1c44823] <IDDList.IDDList<TCATable.File> reloadDataWithAnimations()>   found: '1 updates' from rows: '55728' in: '83.533 ms'
             2023-12-14 19:59:43.144 <16789> [I 1c44823] <IDDList.IDDList<TCATable.File> reloadDataWithAnimations()>   found: '1 updates' from rows: '74304' in: '113.000 ms'
             Klajd Deda, December 14, 2023
             */
            func reloadDataWithAnimations() {
                let startDate = Date()
                let changeset = StagedChangeset(source: context.coordinator.rows, target: rows)
                let deleted = changeset.reduce(into: 0) { $0 += $1.elementDeleted.count }
                let updated = changeset.reduce(into: 0) { $0 += $1.elementUpdated.count }
                let moved = changeset.reduce(into: 0) { $0 += $1.elementMoved.count }
                let inserted = changeset.reduce(into: 0) { $0 += $1.elementInserted.count }

                Log4swift[Self.self].info("tag: '\(tagID)' deleted: '\(deleted)' updated: '\(updated)' moved: '\(moved)' inserted: '\(inserted)' from rows: '\(rows.count)' completed in: '\(startDate.elapsedTime) ms'")
                if moved > 5 {
                    // when moved is present the `reload(using:` behaves as if its
                    // rotating over the horizontal axis
                    // this is an attempt at fixing it
                    // Klajd Deda, February 29, 2024
                    //
                    context.coordinator.rows = rows
                    tableView.reloadData()
                } else {
                    tableView.reload(using: changeset, with: .effectFade) { data in
                        context.coordinator.rows = data
                    }
                }
            }

            Log4swift[Self.self].info("tag: '\(tagID)' reloadDataWithAnimations current: '\(context.coordinator.rows.count) rows' incomming: '\(rows.count) rows'")
            reloadDataWithAnimations()

            // preserve selection
            let selectedRowIndexes = selectedIndexes()
            tableView.selectRowIndexes(selectedRowIndexes, byExtendingSelection: false)
        } else if selectionHasChanged(tableView) {
            // the binding and the ui do not agree on the selection
            // the binding shall to drive the ui
            let selectedRowIndexes = selectedIndexes()
            
            if selectedRowIndexes.isEmpty {
                tableView.deselectAll(nil)
                DispatchQueue.main.async {
                    /**
                     If we have no selection, so we should have no highlights.
                     But somehow i'm not able to trigger the un-highlight when the selection is set to emtpy
                     The reload will do it, but it might cause a slight flicker
                     */
                    tableView.reloadVisibleRows()
                }
                return
            }
            Log4swift[Self.self].debug("tag: '\(tagID)' detected changes in the selection binding, selecting: 'rows \(selectedRowIndexes.map(\.description).joined(separator: ", "))'")
            tableView.reloadData(forRowIndexes: selectedRowIndexes, columnIndexes: IndexSet(0 ..< tableView.tableColumns.count))
            tableView.selectRowIndexes(selectedRowIndexes, byExtendingSelection: false)
        } else if Int(abs(tableFrame.size.width - nsView.frame.size.width)) > 0 {
            // the view was resized, reload visible rows and remember the new size
            let visibleRows = tableView.rows(in: tableView.visibleRect)
            let updatedRowIndexes = (0 ..< visibleRows.length).map { visibleRows.location + $0 }

            Log4swift[Self.self].debug("tag: '\(tagID)' detected changes in the tableView width, saved: '\(tableFrame)' current: '\(tableView.frame)'")
            tableView.reloadData(forRowIndexes: IndexSet(updatedRowIndexes), columnIndexes: IndexSet(0 ..< tableView.tableColumns.count))
        } else {
            // catch all, something changed, this is light weight anyhow
            tableView.reloadVisibleRows()
        }

        // update column visibility
        tableView.tableColumns.forEach { tableColumn in
            guard let foundIdx = columns.firstIndex(where: { $0.id == tableColumn.identifier })
            else { return }

            tableColumn.isHidden = !columns[foundIdx].isVisible
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
            // have to in order to avoid SwiftUI recursive complaint
            if Int(abs(tableFrame.size.width - nsView.frame.size.width)) > 0 {
                self.tableFrame = nsView.frame
                Log4swift[Self.self].debug("tag: '\(tagID)' saved: '\(tableFrame)'")
            }
        }
    }
    
    // MARK: - Coordinator -
    
    /**
     Gets called once per view "identity"
     */
    public func makeCoordinator() -> TableViewCoordinator<RowValue> {
        Log4swift[Self.self].info("tag: '\(tagID)'")
        return TableViewCoordinator(self, rows: rows)
    }

    // MARK: - Helpers -

    /**
     Convenience, Called from the Coordinator since we manage the state
     */
    func updateSelection(from indices: IndexSet) {
        switch selectionType {
        case .single:
            let indices = Set(indices.map { rows[$0].id })
            singleSelection = indices.first
        case .multiple:
            let indices = Set(indices.map { rows[$0].id })
            multipleSelection = indices
        }
    }

    /**
     Convenience, Called from the Coordinator since we manage the state.
     For now we support only one column sorting :-)
     */
    func updateSorting(from sortDescriptors: [NSSortDescriptor]) {
        guard let first = sortDescriptors.first
        else { return }

        let newSorts = [first] // sortDescriptors
        let configuredColumnSorts = columns.map { $0.columnSort }
        let updated = newSorts
            .compactMap { sort in
                if let match = configuredColumnSorts.first(where: { $0.key == sort.key }) {
                    var copy = match
                    copy.ascending = sort.ascending
                    return copy
                }
                return nil
            }

        guard let first = updated.first
        else {
            // should not get here
            Log4swift[Self.self].error("tag: '\(tagID)' found no match from: '\(sortDescriptors)'")
            return }

        self.columnSort = first
    }
}

// MARK: - View Modifiers -

extension IDDList {
    /**
     A generic introspection block that allows direct access to the tableView and scrollView objects.

     This code will be called after the tableView and the scrollView are created and allows one
     to override or set other values such as tableViews.intercellSpacing which bt default is set to `.init(width: 10, height: 1)`
     */
    public func introspect(
        _ block: @escaping IntrospectBlock
    ) -> Self {
        var copy = self
        copy.introspectBlocks.append(block)
        return copy
    }
}
