//
//  TableViewCell.swift
//  IDDList
//
//  Created by Klajd Deda on 01/05/23.
//  Copyright (C) 1997-2023 id-design, inc. All rights reserved.
//

import Foundation
import SwiftUI
import Log4swift

public final class TableViewCell: NSTableCellView {
    let hostingView = NSHostingView(rootView: AnyView(EmptyView()))
    private let label = NSTextField.label()
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

    public override func layout() {
        super.layout()

        label.sizeToFit()
        label.frame.origin = CGPoint(x: 2, y: 2)
    }

    required init?(coder: NSCoder) {
        fatalError("Not implemented")
    }

    public override var backgroundStyle: NSView.BackgroundStyle {
        get {
            super.backgroundStyle
        }
        set {
            super.backgroundStyle = newValue

            let isHighlighted = newValue == .emphasized
            if self.cellModel.isHighlighted != isHighlighted {
                Log4swift[Self.self].info("backgroundStyle: '\(cellModel.objectID)' isHighlighted: '\(isHighlighted)'")
                self.cellModel.isHighlighted = isHighlighted
            }
            // if newValue == .emphasized {
            //     Log4swift[Self.self].info("backgroundStyle: '\(cellModel.objectID)'")
            // }
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
