//
//  CSVRow.swift
//  CSVTable
//
//  Created by Klajd Deda on 12/27/21.
//  Copyright (C) 1997-2023 id-design, inc. All rights reserved.
//

import Foundation

@dynamicMemberLookup
struct CSVRow: Equatable, Identifiable, Hashable {
    var id: Int
    var columns: [String]

    subscript(dynamicMember string: String) -> String {
        guard let index = Int(string)
        else { return "" }
        return columns[index]
    }
}
