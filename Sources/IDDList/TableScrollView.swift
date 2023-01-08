//
//  TableScrollView.swift
//  IDDList
//
//  Created by Klajd Deda on 01/05/23.
//  Copyright (C) 1997-2023 id-design, inc. All rights reserved.
//

import AppKit
import SwiftUI

public class TableScrollView<RowValue>: NSScrollView
    where RowValue: Identifiable, RowValue: Equatable
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
