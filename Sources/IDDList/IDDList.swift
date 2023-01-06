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

public struct IDDList<RowValue>: NSViewRepresentable
    where RowValue: Identifiable, RowValue: Equatable
{
    enum SelectionType {
        case single
        case multiple
    }

    public var scrollAxes: Axis.Set
    public var rows: [RowValue]
    private var selectionType: SelectionType
    @Binding private var singleSelection: RowValue.ID?
    @Binding private var multipleSelection: Set<RowValue.ID>
    @Binding public var columns: [IDDColumn<RowValue>]

    private func buildTableView() -> IDDTableView<RowValue> {
        let rv = IDDTableView<RowValue>(columns: columns)

        rv.allowsMultipleSelection = selectionType == .multiple
        // data source
        rv.axes = scrollAxes
        return rv
    }

    private func buildScrollView(tableView: IDDTableView<RowValue>) -> IDDTableScrollView<RowValue> {
        let rv = IDDTableScrollView<RowValue>(tableView: tableView)

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
        _ tableView: IDDTableView<RowValue>,
        _ scrollView: IDDTableScrollView<RowValue>
    ) -> Void
    
    internal var introspectBlocks: [IntrospectBlock] = []
    
    // MARK: - Init -

    public init(
        _ rows: [RowValue],
        singleSelection: Binding<RowValue.ID?>,
        @IDDColumnBuilder<RowValue> columns: () -> [IDDColumn<RowValue>]
    ) {
        self.rows = rows
        self.selectionType = .single
        self._singleSelection = singleSelection
        self.columns = columns()
        Log4swift[Self.self].info("")
    }

    public init(
        _ rows: [RowValue],
        multipleSelection: Binding<Set<RowValue.ID>>,
        @IDDColumnBuilder<RowValue> columns: () -> [IDDColumn<RowValue>]
    ) {
        self.rows = rows
        self.selectionType = .multiple
        self._multipleSelection = multipleSelection
        self.columns = columns()
        Log4swift[Self.self].info("")
    }

    // MARK: - NSViewRepresentable overrides -
    
    public typealias NSViewType = IDDTableScrollView<RowValue>
    
    // Gets called once per view "identity"
    public func makeNSView(context: Context) -> NSViewType {
        let tableView = buildTableView()
        let scrollView = buildScrollView(tableView: tableView)

        tableView.delegate = context.coordinator
        tableView.dataSource = context.coordinator
        Log4swift[Self.self].info("makeNSView")
        return scrollView
    }

    // Gets called whenever `model` changes
    public func updateNSView(_ nsView: NSViewType, context: Context) {
        Log4swift[Self.self].info("updateStatus: \(context.coordinator.updateStatus)")

        guard context.coordinator.updateStatus != .fromCoordinator
        else { return }
        context.coordinator.updateStatus = .fromNSView
        defer { context.coordinator.updateStatus = .none }

        let tableView = nsView.tableView
        context.coordinator.parent = self
        if context.coordinator.rows != rows {
            context.coordinator.rows = rows
            tableView.reloadData()
        }

        // update column visibility
        tableView.tableColumns.forEach { tableColumn in
            guard let foundIdx = columns.firstIndex(where: { $0.id == tableColumn.identifier })
            else { return }

            tableColumn.isHidden = !columns[foundIdx].isVisible
        }

        // preserve reservation from state
        DispatchQueue.main.async {
            let indexArray = rows
                .indices
                .filter { multipleSelection.contains(rows[$0].id) }
            let indices = IndexSet(indexArray)
            guard !indices.isEmpty,
                  tableView.selectedRowIndexes != indices
            else { return }
            print("selecting", indices.map { $0.description })
            tableView.selectRowIndexes(
                indices,
                byExtendingSelection: false
            )
        }
    }
    
    // MARK: - Coordinator -
    
    public func makeCoordinator() -> IDDListCoordinator<RowValue> {
        Log4swift[Self.self].info("makeCoordinator")
        return IDDListCoordinator(self, rows: rows)
    }

    // MARK: - Helpers -
    
    public func updateSelection(from indices: IndexSet) {
        let indices = Set(indices.map { rows[$0].id })

        multipleSelection = indices
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
