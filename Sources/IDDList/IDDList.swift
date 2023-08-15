//
//  IDDList.swift
//  IDDList
//
//  Created by Klajd Deda on 01/05/23.
//  Copyright (C) 1997-2023 id-design, inc. All rights reserved.
//

import AppKit
import SwiftUI
import Log4swift

//public final class IDDListModel<RowValue>: ObservableObject
//    where RowValue: Identifiable, RowValue: Equatable
//{
//    @Published private var singleSelection: RowValue.ID?
//    @Published private var multipleSelection: Set<RowValue.ID>
//    @Published private var columnSorts: [ColumnSort<RowValue>]
//
//    init(
//        singleSelection: RowValue.ID? = nil,
//        multipleSelection: Set<RowValue.ID>,
//        columnSorts: [ColumnSort<RowValue>]
//    ) {
//        self.singleSelection = singleSelection
//        self.multipleSelection = multipleSelection
//        self.columnSorts = columnSorts
//    }
//}

public struct IDDList<RowValue>: NSViewRepresentable
    where RowValue: Identifiable, RowValue: Equatable
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
    @Binding private var columnSorts: [ColumnSort<RowValue>]
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
        rv.sortDescriptors = columnSorts.compactMap(NSSortDescriptor.init)
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

        // introspection blocks
        for block in introspectBlocks {
            block(tableView, rv)
        }

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
        columnSorts: Binding<[ColumnSort<RowValue>]> = .constant([]),
        @ColumnBuilder<RowValue> columns: () -> [Column<RowValue>]
    ) {
        self.rows = rows
        self.selectionType = .single
        self._singleSelection = singleSelection
        self._multipleSelection = .constant(Set())
        self._columnSorts = columnSorts

        let updatedColumns = columns().updateColumnSorts(columnSorts.wrappedValue)
        self._columns = State(initialValue: updatedColumns)

        // Log4swift[Self.self].info("")
    }

    /**
     These can be called often
     */
    public init(
        _ rows: [RowValue],
        multipleSelection: Binding<Set<RowValue.ID>>,
        columnSorts: Binding<[ColumnSort<RowValue>]> = .constant([]),
        @ColumnBuilder<RowValue> columns: () -> [Column<RowValue>]
    ) {
        self.rows = rows
        self.selectionType = .multiple
        self._singleSelection = .constant(.none)
        self._multipleSelection = multipleSelection
        self._columnSorts = columnSorts

        let updatedColumns = columns().updateColumnSorts(columnSorts.wrappedValue)
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

        // Log4swift[Self.self].info("detected changes ...")
        let tableView = nsView.tableView
        context.coordinator.parent = self
        if context.coordinator.rows != rows {
            // the rows have changed we shall reload it all
            context.coordinator.rows = rows

            Log4swift[Self.self].debug("tag: '\(self.tag)' detected changes in the rows, reloading: '\(rows.count) rows'")
            tableView.reloadData()

            // preserve selection
            let selectedRowIndexes = selectedIndexes()
            tableView.selectRowIndexes(selectedRowIndexes, byExtendingSelection: false)
        } else if selectionHasChanged(tableView) {
            // the binding and the ui do not agree on the selection
            // the binding shall to drive the ui
            let selectedRowIndexes = selectedIndexes()
            
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
            let visibleRows = tableView.rows(in: tableView.visibleRect)
            let updatedRowIndexes = (0 ..< visibleRows.length).map { visibleRows.location + $0 }

            // Log4swift[Self.self].info("tag: '\(self.tag)' detected changes in general ...")
            tableView.reloadData(forRowIndexes: IndexSet(updatedRowIndexes), columnIndexes: IndexSet(0 ..< tableView.tableColumns.count))
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

        guard !updated.isEmpty
        else {
            // should not get here
            Log4swift[Self.self].error("tag: '\(self.tag)' found no match from: '\(sortDescriptors)'")
            return }

        self.columnSorts = updated
    }
}

// MARK: - View Modifiers -

extension IDDList {
    /// A generic introspection block that allows direct access to the table view and scroll view objects.
    public func introspect(
        _ block: @escaping IntrospectBlock
    ) -> Self {
        var copy = self
        copy.introspectBlocks.append(block)
        return copy
    }
}
