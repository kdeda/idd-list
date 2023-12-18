//
//  TableRowValue.swift
//  IDDList
//
//  Created by Klajd Deda on 12/14/23.
//  Copyright (C) 1997-2023 id-design, inc. All rights reserved.
//

import Foundation
import DifferenceKit

/**
 Type eraser, the outside world does not need to know this
 They just gives us RowValue of constraints, Equatable, Identifiable and Hashable
 We wrap it in this we can use DifferenceKit
 */
public struct TableRowValue<RowValue>
where RowValue: Equatable, RowValue: Identifiable, RowValue: Hashable
{
    let value: RowValue
    public init(rowValue: RowValue) {
        self.value = rowValue
    }
}

extension TableRowValue: Equatable where RowValue: Equatable {}
extension TableRowValue: Identifiable where RowValue: Identifiable {
    public var id: RowValue.ID {
        value.id
    }
}
extension TableRowValue: Hashable where RowValue: Hashable {}
extension TableRowValue: Differentiable {}
