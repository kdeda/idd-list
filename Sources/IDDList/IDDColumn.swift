//
//  IDDColumn.swift
//  IDDList
//
//  Created by Klajd Deda on 01/05/23.
//  Copyright (C) 1997-2023 id-design, inc. All rights reserved.
//

import AppKit
import SwiftUI

public struct IDDColumn<RowValue>
    where RowValue: Identifiable, RowValue: Equatable
{
    public var title: String
    public let id: NSUserInterfaceItemIdentifier
    public var isVisible: Bool = true
    internal var width: IDDColumnColumnWidth = .default
    var cellView: (_ item: RowValue) -> any View

    // MARK: - Introspection -

    public typealias IntrospectBlock = (
        _ tableColumn: NSTableColumn
    ) -> Void

    internal var introspectBlocks: [IntrospectBlock] = []

    // MARK: - Init -

    public init(
        title: String,
        id: String,
        cellView: @escaping (_ item: RowValue) -> any View
    ) {
        self.title = title
        self.id = NSUserInterfaceItemIdentifier(rawValue: id)
        self.cellView = cellView
    }
}

// MARK: - Types -

extension IDDColumn {
    internal enum IDDColumnColumnWidth {
        case `default`
        case fixed(CGFloat)
        case limits(min: CGFloat?, ideal: CGFloat?, max: CGFloat?)
    }
}

// MARK: - View Modifiers -

extension IDDColumn {
    /// A generic introspection block that allows direct access to the table column object.
    public func introspect(
        _ block: @escaping IntrospectBlock
    ) -> Self {
        var copy = self
        copy.introspectBlocks.append(block)
        return copy
    }

    public func width(_ width: CGFloat) -> Self {
        var copy = self
        copy.width = .fixed(width)
        return copy
    }

    public func width(min: CGFloat?, ideal: CGFloat?, max: CGFloat?) -> Self {
        var copy = self
        copy.width = .limits(min: min, ideal: ideal, max: max)
        return copy
    }

    public func visible(_ state: Bool) -> Self {
        var copy = self
        copy.isVisible = state
        return copy
    }
}
