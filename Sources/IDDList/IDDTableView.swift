//
//  IDDTableView.swift
//  IDDList
//
//  Created by Klajd Deda on 01/05/23.
//  Copyright (C) 1997-2023 id-design, inc. All rights reserved.
//

import AppKit
import SwiftUI
import Log4swift

public class IDDTableView<RowValue>: NSTableView
    where RowValue: Identifiable, RowValue: Equatable
{
    public var axes: Axis.Set = [.horizontal, .vertical]

    init(columns: [IDDColumn<RowValue>]) {
        super.init(frame: .zero)

        // column setup
        columns
            .map(NSTableColumn.init)
            .forEach(self.addTableColumn)

        if columns.count == 1 {
            // we want the first column to fit
            var last = self.tableColumns[0]
            last.resizingMask = [.autoresizingMask]
            self.sizeLastColumnToFit()

            last = self.tableColumns[0]
            Log4swift[Self.self].info("width: '\(last.width)'")
        }

        self.translatesAutoresizingMaskIntoConstraints = false
        self.sortDescriptors = columns.compactMap(\.sortDescriptor)

        Log4swift[Self.self].info("created: '\(self.sortDescriptors)'")
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
