//
//  CSVRow.swift
//  CSVTable
//
//  Created by Klajd Deda on 12/27/21.
//  Copyright (C) 1997-2024 id-design, inc. All rights reserved.
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

    func compareByColumIndex(_ rhs: Self, columnIndex: Int) -> Bool {
        columns[columnIndex] > rhs.columns[columnIndex]
    }
}

extension Array where Element == CSVRow {
    func csvData(separator: String) -> Data {
        let csvRows: [String] = self.map { row in
            row.columns.joined(separator: separator)
        }

        let csvString = csvRows.joined(separator: "\n")
        let csvData = csvString.data(using: .utf8) ?? Data()
        return csvData
    }

    mutating func updateIDs() -> Self {
        var id = 0

        return self.map { row in
            var copy = row
            copy.id = id
            id += 1
            return copy
        }
    }
}
