//
//  IDDList.swift
//  IDDList
//
//  Created by Klajd Deda on 01/05/23.
//  Copyright (C) 1997-2024 id-design, inc. All rights reserved.
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

    private var modelIndexes: IndexSet {
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

    // MARK: - Introspection -
    
    public typealias IntrospectBlock = (
        _ tableView: TableView<RowValue>,
        _ scrollView: TableScrollView<RowValue>
    ) -> Void
    
    internal var introspectBlocks: [IntrospectBlock] = []
    internal var heightOfRow: (_ rowValue: RowValue) -> CGFloat = { _ in 22.0 }

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

    private func makeTableView() -> TableView<RowValue> {
        let rv = TableView<RowValue>(
            columns: columns,
            makeFirstResponder: $makeFirstResponder
        )

        rv.allowsMultipleSelection = selectionType == .multiple
        // data source
        rv.axes = [.horizontal, .vertical]
        rv.sortDescriptors = [columnSort].compactMap(NSSortDescriptor.init)
        rv.tagID = tagID

        return rv
    }

    private func makeScrollView(tableView: TableView<RowValue>) -> TableScrollView<RowValue> {
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

    /**
     Gets called once per view "identity"
     */
    public func makeNSView(context: Context) -> TableScrollView<RowValue> {
        let tableView = makeTableView()
        let scrollView = makeScrollView(tableView: tableView)

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
        Log4swift[Self.self].debug("tagID: '\(tagID)' tableView: '\(tableView)'")
        return scrollView
    }

    /**
     Attempt at handling push changes from the model and making sure the view agrees with it.

     Return the array of rowIDs if the selection in our view does not match the
     selection from the model/binding.
     We should than push these new values into the model right after updating the ui
     */
    private func modelHasChanged(_ tableView: TableView<RowValue>) -> IndexSet? {
        let tableIndexes = tableView.selectedRowIndexes
        let modelIndexes: IndexSet = modelIndexes

        if tableIndexes != modelIndexes {
            Log4swift[Self.self].debug("tagID: '\(tagID)' detected changes in the selection binding")
            Log4swift[Self.self].debug("tagID: '\(tagID)' tableIndexes: rows: '\(tableIndexes.map(\.description).joined(separator: ", "))'")
            Log4swift[Self.self].debug("tagID: '\(tagID)' modelIndexes: rows: '\(modelIndexes.map(\.description).joined(separator: ", "))'")
            return modelIndexes
        }
        return .none
    }

    /**
     Gets called whenever `model` changes. So probably frequently
     Be ware that this is the push from the model to the UI.
     When UI changes due to human interaction, say user clicks and selects a row we should
     push upstream from the updateSelection
     */
    public func updateNSView(_ nsView: TableScrollView<RowValue>, context: Context) {
        guard context.coordinator.updateStatus != .fromCoordinator
        else {
            Log4swift[Self.self].error("tagID: '\(tagID)' ignoring fromCoordinator")
            return
        }
        context.coordinator.updateStatus = .fromUpdateNSView
        defer { context.coordinator.updateStatus = .none }

        let tableView = nsView.tableView
        context.coordinator.parent = self

        // Log4swift[Self.self].debug("tagID: '\(tagID)'")
        /**
         This code reacts to pushes from the model to change the makeFirstResponder/resignFirstResponder
         The changes from the other way are in the TableView.becomeFirstResponder, TableView.resignFirstResponder
         We will care about the case where makeFirstResponder is true, the resignation is automatic.
         */
        if let window = NSApplication.shared.keyWindow,
           let ourWindow = tableView.window,
           window == ourWindow {
            // we have to do this dance
            // or else cocoa will barf
            // window.firstResponder should match our instance of tableView
            let isFirstResponder = window.firstResponder == tableView

            // Log4swift[Self.self].debug("tagID: '\(tagID)' makeFirstResponder: '\(makeFirstResponder)' isFirstResponder: '\(isFirstResponder)'")
            // Log4swift[Self.self].debug("tagID: '\(tagID)' firstResponder: '\(window.firstResponder)'")
            // Log4swift[Self.self].debug("tagID: '\(tagID)' tableView: '\(tableView)'")
            if makeFirstResponder && !isFirstResponder {
                /**
                 We are told to become firstResponder, so we can handle key events.
                 We need to do this once, so we relinquish the makeFirstResponder by setting it to false
                 */
                Log4swift[Self.self].debug("tagID: '\(tagID)' makeFirstResponder: '\(makeFirstResponder)'")
                Log4swift[Self.self].debug("tagID: '\(tagID)' window: '\(window)'")
                let result = window.makeFirstResponder(tableView)

                if !result {
                    Log4swift[Self.self].error("tagID: '\(tagID)' makeFirstResponder: '\(makeFirstResponder)' failed")
                    Log4swift[Self.self].error("tagID: '\(tagID)' ----------------------")
                }

                //  } else if !makeFirstResponder && isFirstResponder {
                //      Log4swift[Self.self].debug("tagID: '\(tagID)' makeFirstResponder: '\(makeFirstResponder)'")
                //      let result = tableView.resignFirstResponder()
                //
                //      if !result {
                //          Log4swift[Self.self].error("tagID: '\(tagID)' makeFirstResponder: '\(makeFirstResponder)' failed")
                //          Log4swift[Self.self].error("tagID: '\(tagID)' ----------------------")
                //      }
            }
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

                Log4swift[Self.self].info("tagID: '\(tagID)' deleted: '\(deleted)' updated: '\(updated)' moved: '\(moved)' inserted: '\(inserted)' from rows: '\(rows.count)' completed in: '\(startDate.elapsedTime) ms'")
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

            Log4swift[Self.self].info("tagID: '\(tagID)' reloadDataWithAnimations current: '\(context.coordinator.rows.count) rows' incomming: '\(rows.count) rows'")
            reloadDataWithAnimations()

            // preserve selection
            tableView.selectRowIndexes(modelIndexes, byExtendingSelection: false)
        } else if let selection = modelHasChanged(tableView) {
            tableView.reloadData(forRowIndexes: selection, columnIndexes: IndexSet(0 ..< tableView.tableColumns.count))
            tableView.selectRowIndexes(selection, byExtendingSelection: false)

            self.updateSelection(from: selection, forcePush: true)
        } else if Int(abs(tableFrame.size.width - nsView.frame.size.width)) > 0 {
            // the view was resized, reload visible rows and remember the new size
            let visibleRows = tableView.rows(in: tableView.visibleRect)
            let updatedRowIndexes = (0 ..< visibleRows.length).map { visibleRows.location + $0 }

            Log4swift[Self.self].debug("tagID: '\(tagID)' detected changes in the tableView width, saved: '\(tableFrame)' current: '\(tableView.frame)'")
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
                Log4swift[Self.self].debug("tagID: '\(tagID)' saved: '\(tableFrame)'")
            }
        }
    }
    
    // MARK: - Coordinator -
    
    /**
     Gets called once per view "identity"
     This will be the tableview's delegate and data source
     */
    public func makeCoordinator() -> TableViewCoordinator<RowValue> {
        let rv = TableViewCoordinator(self, rows: rows)

        rv.tagID = tagID
        return rv
    }

    // MARK: - Helpers -

    /**
     Push changes into the model
     Could be called more than once from the TableViewCoordinator or indirectly from TableView
     Avoid pushing if there are no changes.
     */
    internal func updateSelection(from indices: IndexSet, forcePush: Bool = false) {
        Log4swift[Self.self].debug("tagID: '\(tagID)'")
        Log4swift[Self.self].debug("tagID: '\(tagID)' -------------------------------------")
        Log4swift[Self.self].debug("tagID: '\(tagID)' newSelection: '\(indices.map({ rows[$0].id }))'")
        Log4swift[Self.self].debug("tagID: '\(tagID)' forcePush: '\(forcePush)'")

        switch selectionType {
        case .single:
            let indices = Set(indices.map { rows[$0].id })

            if forcePush || singleSelection != indices.first {
                Log4swift[Self.self].debug("tagID: '\(tagID)' existing singleSelection: '\(indices)'")
                singleSelection = indices.first
            }

        case .multiple:
            let indices = Set(indices.map { rows[$0].id })

            if forcePush || multipleSelection != indices {
                Log4swift[Self.self].debug("tagID: '\(tagID)' existing multipleSelection: '\(multipleSelection)'")
                multipleSelection = indices
            }
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
            Log4swift[Self.self].error("tagID: '\(tagID)' found no match from: '\(sortDescriptors)'")
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
    
    /// Height of row
    public func heightOfRow(_ heightOfRow: @escaping (_ rowValue: RowValue) -> CGFloat) -> Self {
        var copy = self

        copy.heightOfRow = heightOfRow
        return copy
    }
}
