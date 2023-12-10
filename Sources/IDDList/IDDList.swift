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

public struct IDDList<RowValue>: NSViewRepresentable
where RowValue: Equatable, RowValue: Identifiable, RowValue: Hashable
{
    enum SelectionType {
        case single
        case multiple
    }

    public var scrollAxes: Axis.Set = [.horizontal, .vertical]
    public var rows: [RowValue]
    private var selectionType: SelectionType
    @Binding private var singleSelection: RowValue.ID?
    @Binding private var multipleSelection: Set<RowValue.ID>

    /**
     We can sort by one column at a time
     */
    @Binding private var columnSort: ColumnSort<RowValue>
    @State public var columns: [Column<RowValue>]
    @State private var tableFrame: CGRect = .zero
    var tag: String = ""

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
        rv.axes = scrollAxes
        rv.sortDescriptors = [columnSort].compactMap(NSSortDescriptor.init)

        return rv
    }

    private func buildScrollView(tableView: TableView<RowValue>) -> TableScrollView<RowValue> {
        let rv = TableScrollView<RowValue>(tableView: tableView)

        // content and geometry
        rv.translatesAutoresizingMaskIntoConstraints = false // has no effect?
        rv.documentView = tableView

        rv.hasVerticalScroller = scrollAxes.contains(.vertical)
        rv.hasHorizontalScroller = scrollAxes.contains(.horizontal)

        // prevent glitchy behavior when axes are constrained
        rv.verticalScrollElasticity = scrollAxes.contains(.vertical) ? .automatic : .none
        rv.horizontalScrollElasticity = scrollAxes.contains(.horizontal) ? .automatic : .none
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
     These can be called often
     */
    public init(
        _ rows: [RowValue],
        singleSelection: Binding<RowValue.ID?>,
        columnSort: Binding<ColumnSort<RowValue>> = .constant(.init()),
        @ColumnBuilder<RowValue> columns: () -> [Column<RowValue>]
    ) {
        self.rows = rows
        self.selectionType = .single
        self._singleSelection = singleSelection
        self._multipleSelection = .constant(Set())
        self._columnSort = columnSort

        let updatedColumns = columns().updateColumnSorts(columnSort)
        self._columns = State(initialValue: updatedColumns)

        // Log4swift[Self.self].info("")
    }

    /**
     These can be called often
     */
    public init(
        _ rows: [RowValue],
        multipleSelection: Binding<Set<RowValue.ID>>,
        columnSort: Binding<ColumnSort<RowValue>> = .constant(.init()),
        @ColumnBuilder<RowValue> columns: () -> [Column<RowValue>]
    ) {
        self.rows = rows
        self.selectionType = .multiple
        self._singleSelection = .constant(.none)
        self._multipleSelection = multipleSelection
        self._columnSort = columnSort

        let updatedColumns = columns().updateColumnSorts(columnSort)
        self._columns = State(initialValue: updatedColumns)

        // Log4swift[Self.self].info("")
    }

    public func tag(_ tag: String) -> Self {
        var copy = self

        copy.tag = tag
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
        scrollView.hasHorizontalScroller = false

        // introspection blocks
        for block in introspectBlocks {
            block(tableView, scrollView)
        }

        if let sortDescriptor = tableView.sortDescriptors.first,
           let sortedColumn = tableView.tableColumns.first(where: { $0.sortDescriptorPrototype == sortDescriptor }) {
            context.coordinator.tableView(tableView, mouseDownInHeaderOf: sortedColumn)
        }
        Log4swift[Self.self].info("tag: '\(self.tag)'")
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

        /**
         Reload just the visible cells.
         */
        func reloadVisible() {
            let visibleRows = tableView.rows(in: tableView.visibleRect)
            let updatedRowIndexes = (0 ..< visibleRows.length).map { visibleRows.location + $0 }

            // Log4swift[Self.self].info("tag: '\(self.tag)' detected changes in general ...")
            tableView.reloadData(forRowIndexes: IndexSet(updatedRowIndexes), columnIndexes: IndexSet(0 ..< tableView.tableColumns.count))
        }
        
        // Log4swift[Self.self].info("detected changes ...")
        let tableView = nsView.tableView
        context.coordinator.parent = self
        if context.coordinator.rows != rows {
            let bigO = context.coordinator.rows.count * rows.count
            let MAX_BIG_O = 100_000

            /**
             this is n * m complexity
             so it will not be called for anything larger than MAX_BIG_O
            */
            func reloadDataWithAnimations() {
                let startDate = Date()
                let updates = rows.difference(from: context.coordinator.rows)
                Log4swift[Self.self].info("found: '\(updates.count) updates' from rows: '\(rows.count)' in: '\(startDate.elapsedTimeInMilliseconds.with3Digits) ms'")

                // the rows have changed we shall reload it all
                context.coordinator.rows = rows
                guard updates.insertions.count != updates.removals.count
                else {
                    // it means all has changed, avoid flicker and direct reload
                    tableView.reloadData()
                    return
                }
                Log4swift[Self.self].debug("tag: '\(self.tag)' detected changes in the rows, reloading: '\(rows.count) rows'")
                tableView.beginUpdates()
                for step in updates.steps {
                    switch step {
                    case let .remove(element, index):
                        Log4swift[Self.self].debug("remove: '\(element)'")
                        tableView.removeRows(at: [index], withAnimation: .effectFade)

                    case let .insert(element, index):
                        Log4swift[Self.self].debug("insert: '\(element)'")
                        tableView.insertRows(at: [index], withAnimation: .effectFade)

                    case let .move(element, from, to):
                        Log4swift[Self.self].debug("move: '\(element)'")
                        tableView.moveRow(at: from, to: to)
                    }
                }
                tableView.endUpdates()
                tableView.invalidateIntrinsicContentSize()
            }

            if bigO > MAX_BIG_O {
                context.coordinator.rows = rows
                tableView.reloadData()
            } else {
                reloadDataWithAnimations()
            }

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
                    reloadVisible()
                }
                return
            }
            Log4swift[Self.self].debug("tag: '\(self.tag)' detected changes in the selection binding, selecting: 'rows \(selectedRowIndexes.map(\.description).joined(separator: ", "))'")
            tableView.reloadData(forRowIndexes: selectedRowIndexes, columnIndexes: IndexSet(0 ..< tableView.tableColumns.count))
            tableView.selectRowIndexes(selectedRowIndexes, byExtendingSelection: false)
        } else if tableFrame.size.width != tableView.frame.size.width {
            // the view was resized, reload visible rows and remember the new size
            let visibleRows = tableView.rows(in: tableView.visibleRect)
            let updatedRowIndexes = (0 ..< visibleRows.length).map { visibleRows.location + $0 }

            Log4swift[Self.self].debug("tag: '\(self.tag)' detected changes in the tableView width, saved: '\(tableFrame)' current: '\(tableView.frame)'")
            tableView.reloadData(forRowIndexes: IndexSet(updatedRowIndexes), columnIndexes: IndexSet(0 ..< tableView.tableColumns.count))
        } else {
            // catch all, something changed, this is light weight anyhow
            reloadVisible()
        }

        // update column visibility
        tableView.tableColumns.forEach { tableColumn in
            guard let foundIdx = columns.firstIndex(where: { $0.id == tableColumn.identifier })
            else { return }

            tableColumn.isHidden = !columns[foundIdx].isVisible
        }

        DispatchQueue.main.async {
            // have to in order to avoid SwiftUI recursive complaint
            if self.tableFrame.size.width != tableView.frame.size.width {
                self.tableFrame = tableView.frame
                Log4swift[Self.self].debug("tag: '\(self.tag)' saved: '\(tableFrame)'")
            }
        }
    }
    
    // MARK: - Coordinator -
    
    /**
     Gets called once per view "identity"
     */
    public func makeCoordinator() -> TableViewCoordinator<RowValue> {
        Log4swift[Self.self].info("tag: '\(self.tag)'")
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
            Log4swift[Self.self].error("tag: '\(self.tag)' found no match from: '\(sortDescriptors)'")
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
