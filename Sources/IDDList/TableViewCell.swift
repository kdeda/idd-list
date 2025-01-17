//
//  TableViewCell.swift
//  IDDList
//
//  Created by Klajd Deda on 01/05/23.
//  Copyright (C) 1997-2025 id-design, inc. All rights reserved.
//

import Foundation
import SwiftUI
import Log4swift

public final class TableViewCell: NSTableCellView {
    let hostingView = NSHostingView(rootView: AnyView(EmptyView()))
    var cellModel = CellModel()

    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)

        addSubview(hostingView)
        hostingView.translatesAutoresizingMaskIntoConstraints = false
        // hostingView.layer?.backgroundColor = NSColor.yellow.cgColor

        NSLayoutConstraint.activate([
            hostingView.leadingAnchor.constraint(equalTo: leadingAnchor),
            hostingView.trailingAnchor.constraint(equalTo: trailingAnchor),
            hostingView.topAnchor.constraint(equalTo: topAnchor),
            hostingView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }

    /**
     Called magically by apple's AppKit.
     Say you select a row, or say you switch from one app to another. The old app selection becomes 'un-highlighted'
     */
    public override var backgroundStyle: NSView.BackgroundStyle {
        get {
            super.backgroundStyle
        }
        set {
            super.backgroundStyle = newValue
            self.cellModel.updateIsHighlighted(newValue == .emphasized)
        }
    }

    static func makeView(in tableView: NSTableView) -> Self {
        let id = NSUserInterfaceItemIdentifier(rawValue: String(describing: Self.self))
        if let view = tableView.makeView(withIdentifier: id, owner: nil) as? Self {
            return view
        }
        let view = Self()
        view.identifier = id
        return view
    }
}
