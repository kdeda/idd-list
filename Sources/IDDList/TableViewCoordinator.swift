//
//  TableViewCoordinator.swift
//  IDDList
//
//  Created by Klajd Deda on 01/05/23.
//  Copyright (C) 1997-2024 id-design, inc. All rights reserved.
//

import Foundation
import AppKit
import SwiftUI
import Log4swift

public final class TableViewCoordinator<RowValue>: NSObject, NSTableViewDelegate, NSTableViewDataSource
where RowValue: Equatable, RowValue: Identifiable, RowValue: Hashable
{
    var rows: [TableRowValue<RowValue>]
    // this reference is update each time a new parent is created
    // IDDList.updateNSView
    var parent: IDDList<RowValue>
    var updateStatus: UpdateSource = .none
    var tagID: String = ""

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

        // DEDA DEBUG
        // Helpers
        // if row < 5 {
        //     Log4swift[Self.self].info("[\(String(format: "%03d", row))]'\(column.title)': '\(rows[row].value)'")
        // }
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

        if column.isBrowserColumn {
            // kdeda: Feb 4, 2024
            // when we are modeling a browser columm, usually a tableview with one column
            // these constraints will cause the cell contents to not scale well
            // there will be a jump as you resize the column and we do not want that
            // the following config removes the sizing issues
            //
            if let leading = cell.constraints.first(where: { $0.firstAnchor.name == "leading" }),
               leading.isActive {
                leading.isActive = false
            }
            if let trailing = cell.constraints.first(where: { $0.firstAnchor.name == "trailing" }),
               trailing.isActive {
                trailing.isActive = false
            }
        }

        cell.hostingView.invalidateIntrinsicContentSize()
        return cell
    }

    // MARK: - NSTableViewDelegate -

    /**
     Push changes back into the model
     */
    public func tableViewSelectionDidChange(_ notification: Notification) {
        guard let tableView = notification.object as? TableView<RowValue>,
              !rows.isEmpty
        else {
            Log4swift[Self.self].error("tagID: '\(tagID)' no rows ...")
            return
        }

        guard updateStatus != .fromUpdateNSView
        else {
            Log4swift[Self.self].debug("tagID: '\(tagID)' ignoring fromUpdateNSView")
            return
        }
        updateStatus = .fromCoordinator
        defer { updateStatus = .none }

        parent.updateSelection(from: tableView.selectedRowIndexes)

        // avoid frequent calls
        // i suspect this makes no sense any longer,
        // Klajd Deda, September 20, 2024
        // let selectedIndices: IndexSet = tableView.selectedRowIndexes
        // NSObject.cancelPreviousPerformRequests(withTarget: self)
        // perform(#selector(updateSelection(from:)), with: selectedIndices, afterDelay: 0.1)
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

    public func tableView(
        _ tableView: NSTableView,
        heightOfRow: Int
    ) -> CGFloat {
        let rowValue = rows[heightOfRow].value
        return parent.heightOfRow(rowValue)
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

