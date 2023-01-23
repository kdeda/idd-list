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

public final class IDDListModel<RowValue>: ObservableObject
    where RowValue: Identifiable, RowValue: Equatable
{
    @Published private var singleSelection: RowValue.ID?
    @Published private var multipleSelection: Set<RowValue.ID>
    @Published private var columnSorts: [ColumnSort<RowValue>]

    init(
        singleSelection: RowValue.ID? = nil,
        multipleSelection: Set<RowValue.ID>,
        columnSorts: [ColumnSort<RowValue>]
    ) {
        self.singleSelection = singleSelection
        self.multipleSelection = multipleSelection
        self.columnSorts = columnSorts
    }
}

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

    // MARK: - NSViewRepresentable overrides -

    /**
     Gets called once per view "identity"
     */
    public func makeNSView(context: Context) -> TableScrollView<RowValue> {
        let tableView = buildTableView()
        let scrollView = buildScrollView(tableView: tableView)

        tableView.delegate = context.coordinator
        tableView.dataSource = context.coordinator
        Log4swift[Self.self].info("makeNSView")
        return scrollView
    }

    /**
     Gets called whenever `model` changes. So probably frequently
     */
    public func updateNSView(_ nsView: TableScrollView<RowValue>, context: Context) {
        guard context.coordinator.updateStatus != .fromCoordinator
        else { return }
        context.coordinator.updateStatus = .fromNSView
        defer { context.coordinator.updateStatus = .none }

        Log4swift[Self.self].info("detected changes ...")

        let tableView = nsView.tableView
        context.coordinator.parent = self
        if context.coordinator.rows != rows {
            // let oldRows = context.coordinator.rows
            context.coordinator.rows = rows

            Log4swift[Self.self].info("detected changes in the rows, reloading: '\(rows.count) rows'")
            tableView.reloadData()
        } else {
            let visibleRows = tableView.rows(in: tableView.visibleRect)
            let updatedRowIndexes = (visibleRows.location ..< visibleRows.length).map { $0 }

            Log4swift[Self.self].info("detected changes in the rows, re-drawing: '\(updatedRowIndexes.count) visibleRows'")
            tableView.reloadData(forRowIndexes: IndexSet(updatedRowIndexes), columnIndexes: IndexSet(0 ..< tableView.tableColumns.count))
            if updatedRowIndexes.count == 0 {
                Log4swift[Self.self].info("detected changes in the rows, reloading: '\(rows.count) rows'")
            }
        }
        // tableView.reloadData()

        // update column visibility
        tableView.tableColumns.forEach { tableColumn in
            guard let foundIdx = columns.firstIndex(where: { $0.id == tableColumn.identifier })
            else { return }

            tableColumn.isHidden = !columns[foundIdx].isVisible
        }

        // preserve reservation from state
        DispatchQueue.main.async {
            let indices = selectedRows
            guard !indices.isEmpty,
                  tableView.selectedRowIndexes != indices
            else { return }

            Log4swift[Self.self].info("selected: '\(rows[indices.first!])'")
            Log4swift[Self.self].info("updating selections: '\(indices.map { $0.description })'")

            tableView.selectRowIndexes(indices, byExtendingSelection: false)
            if let first = indices.first {
                tableView.scrollRowToVisible(first)
            }
        }
    }
    
    // MARK: - Coordinator -
    
    /**
     Gets called once per view "identity"
     */
    public func makeCoordinator() -> TableViewCoordinator<RowValue> {
        Log4swift[Self.self].info("makeCoordinator")
        return TableViewCoordinator(self, rows: rows)
    }

    // MARK: - Helpers -

    /**
     Convenience, Called from the Coordinator since we manage the state
     */
    func updateSelection(from indices: IndexSet) {
        let indices = Set(indices.map { rows[$0].id })

        multipleSelection = indices
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
            Log4swift[Self.self].error("found no match from: '\(sortDescriptors)'")
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
