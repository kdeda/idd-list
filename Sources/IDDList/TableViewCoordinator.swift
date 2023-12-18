//
//  TableViewCoordinator.swift
//  IDDList
//
//  Created by Klajd Deda on 01/05/23.
//  Copyright (C) 1997-2023 id-design, inc. All rights reserved.
//

import Foundation
import AppKit
import SwiftUI
import Log4swift

enum UpdateSource {
    case none
    case fromNSView
    case fromCoordinator
}

public final class TableViewCoordinator<RowValue>: NSObject, NSTableViewDelegate, NSTableViewDataSource
where RowValue: Equatable, RowValue: Identifiable, RowValue: Hashable
{
    var rows: [TableRowValue<RowValue>]
    // this reference is update each time a new parent is created
    // IDDList.updateNSView
    var parent: IDDList<RowValue>
    var updateStatus: UpdateSource = .none

    public init(
        _ parent: IDDList<RowValue>,
        rows: [TableRowValue<RowValue>]
    ) {
        self.parent = parent
        self.rows = rows
    }

    private func createCellView(
        tableView: NSTableView,
        tableColumn: NSTableColumn,
        column: Column<RowValue>,
        row: Int
    ) -> TableViewCell {
        let cell = TableViewCell.makeView(in: tableView)
        var frame = column.width.frame
        if tableView.tableColumns.count == 1 {
            let width = tableColumn.width
            frame = (minWidth: width, idealWidth: width, maxWidth: width)
        }

        // Log4swift[Self.self].info("column: '\(column.title)' frame: '\(frame)'")
        // Log4swift[Self.self].info("alignment: '\(column.alignment == .trailing ? "trailing" : "")'")

        cell.hostingView.rootView = AnyView(
            column
                .cellView(rows[row].value)
            // .frame(width: frame.minWidth, alignment: column.alignment)
                .frame(minWidth: frame.minWidth, idealWidth: frame.idealWidth, maxWidth: frame.maxWidth, alignment: column.alignment)
            // .border(Color.yellow)
                .environmentObject(cell.cellModel)
        )
        cell.hostingView.invalidateIntrinsicContentSize()
        return cell
    }

    // MARK: - NSTableViewDelegate -

    public func tableViewSelectionDidChange(_ notification: Notification) {
        guard let tableView = notification.object as? TableView<RowValue>,
              !rows.isEmpty
        else { return }

        guard updateStatus != .fromNSView
        else { return }
        updateStatus = .fromCoordinator
        defer { updateStatus = .none }

        let selectedIndices = tableView.selectedRowIndexes

        if selectedIndices.isEmpty {
            parent.updateSelection(from: .init())
        } else {
            parent.updateSelection(from: selectedIndices)
        }
    }

    public func tableView(
        _ tableView: NSTableView,
        viewFor tableColumn: NSTableColumn?,
        row: Int
    ) -> NSView? {
        guard let tableColumn,
              let column = parent.columns.first(where: { $0.id == tableColumn.identifier })
        else { return nil }

        return self.createCellView(tableView: tableView, tableColumn: tableColumn, column: column, row: row)
    }

    @MainActor public func tableView(
        _ tableView: NSTableView,
        sizeToFitWidthOfColumn column: Int
    ) -> CGFloat {
        return 100
    }

    // MARK: - NSTableViewDataSource -

    public func numberOfRows(in tableView: NSTableView) -> Int {
        // Log4swift[Self.self].info("numberOfRows: '\(rows.count)'")
        return rows.count
    }

    public func tableView(
        _ tableView: NSTableView,
        objectValueFor tableColumn: NSTableColumn?,
        row: Int
    ) -> Any? {
        rows[row]
    }

    public func tableView(
        _ tableView: NSTableView,
        sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]
    ) {
        parent.updateSorting(from: tableView.sortDescriptors)
    }

    public func tableView(
        _ tableView: NSTableView,
        mouseDownInHeaderOf tableColumn: NSTableColumn
    ) {
        // Log4swift[Self.self].info("tableColumn: '\(tableColumn.title)'")

        tableView.tableColumns.forEach { column in
            let existingAttrbutedString = NSMutableAttributedString(attributedString: column.headerCell.attributedStringValue)
            let string = existingAttrbutedString.string

            if tableColumn == column {
                existingAttrbutedString.addAttribute(.foregroundColor, value: NSColor.headerTextColor, range: NSMakeRange(0, string.count))
                let semiboldFont = NSFont.systemFont(ofSize: 11, weight: .semibold)

                existingAttrbutedString.addAttribute(.font, value: semiboldFont, range: NSMakeRange(0, string.count))
            } else {
                existingAttrbutedString.addAttribute(.foregroundColor, value: NSColor.secondaryLabelColor, range: NSMakeRange(0, string.count))
                let theFont = NSFont.systemFont(ofSize: 11, weight: .regular)

                existingAttrbutedString.addAttribute(.font, value: theFont, range: NSMakeRange(0, string.count))
            }
            column.headerCell.attributedStringValue = existingAttrbutedString
        }

    }
}

