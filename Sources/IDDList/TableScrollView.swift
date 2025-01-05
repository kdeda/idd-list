//
//  TableScrollView.swift
//  IDDList
//
//  Created by Klajd Deda on 01/05/23.
//  Copyright (C) 1997-2025 id-design, inc. All rights reserved.
//

import AppKit
import SwiftUI
import Log4swift

/**
 Example: https://github.com/aiaf/MKKRightToLeftScrollView/tree/master?tab=readme-ov-file
 */
public class TableScrollView<RowValue>: NSScrollView
where RowValue: Identifiable, RowValue: Equatable, RowValue: Sendable
{
    public let tableView: TableView<RowValue>
    
    // MARK: - Init -
    
    public init(tableView: TableView<RowValue>) {
        self.tableView = tableView
        super.init(frame: .zero)
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
