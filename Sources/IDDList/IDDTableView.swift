//
//  IDDTableView.swift
//  IDDList
//
//  Created by Klajd Deda on 01/05/23.
//  Copyright (C) 1997-2023 id-design, inc. All rights reserved.
//

import AppKit
import SwiftUI

public class IDDTableView<RowValue>: NSTableView
    where RowValue: Identifiable, RowValue: Equatable
{
    public var axes: Axis.Set = [.horizontal, .vertical]

    init(columns: [IDDColumn<RowValue>]) {
        super.init(frame: .zero)

        // column setup
        columns.forEach { column in
            let col = NSTableColumn()
            col.title = column.title
            col.identifier = column.id

            switch column.width {
            case let .fixed(width):
                col.width = width
                col.resizingMask = []
            case let .limits(min: minW, ideal: idealW, max: maxW):
                if let minW { col.minWidth = minW }
                if let maxW { col.maxWidth = maxW }
                if let idealW { col.width = idealW }
                col.resizingMask = [.userResizingMask, .autoresizingMask]
            case .default:
                break
            }
            col.isHidden = !column.isVisible
            col.isEditable = false

            // introspection blocks
            for block in column.introspectBlocks {
                block(col)
            }
            self.addTableColumn(col)
        }

        self.translatesAutoresizingMaskIntoConstraints = false
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
