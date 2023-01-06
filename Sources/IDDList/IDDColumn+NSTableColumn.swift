//
//  IDDColumn+NSTableColumn.swift
//  IDDList
//
//  Created by Klajd Deda on 01/05/23.
//  Copyright (C) 1997-2023 id-design, inc. All rights reserved.
//

import Foundation
import AppKit
import Log4swift

extension NSTableColumn {
    convenience init<RowValue>(_ column: IDDColumn<RowValue>) {
        self.init()
        self.title = column.title
        self.identifier = column.id

        switch column.width {
        case let .fixed(width):
            self.width = width
            self.resizingMask = []
        case let .limits(min: minW, ideal: idealW, max: maxW):
            if let minW { self.minWidth = minW }
            if let maxW { self.maxWidth = maxW }
            if let idealW { self.width = idealW }
            self.resizingMask = [.userResizingMask, .autoresizingMask]
        }
        self.isHidden = !column.isVisible
        self.isEditable = false

        // introspection blocks
        column.introspectBlocks.forEach {
            $0(self)
        }

        // Log4swift[Self.self].info("column: '\(column.title)' column.alignment: '\(column.alignment.horizontal)'")
        switch column.alignment {
        case .leading:  self.headerCell.alignment = .left
        case .trailing: self.headerCell.alignment = .right
        case .center:   self.headerCell.alignment = .center
        default:        self.headerCell.alignment = .center
        }

        if let sortDescriptor = column.sortDescriptor {
            self.sortDescriptorPrototype = sortDescriptor
        }
    }
}
