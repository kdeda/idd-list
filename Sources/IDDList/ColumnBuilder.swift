//
//  ColumnBuilder.swift
//  IDDList
//
//  Created by Klajd Deda on 01/05/23.
//  Copyright (C) 1997-2024 id-design, inc. All rights reserved.
//

import Foundation

@resultBuilder
public enum ColumnBuilder<RowValue>
where RowValue: Identifiable, RowValue: Equatable
{
    public static func buildBlock(_ components: Column<RowValue>...) -> [Column<RowValue>] {
        components
    }
    
    public static func buildBlock(_ components: [Column<RowValue>]...) -> [Column<RowValue>] {
        // TODO: this crashes - not sure why
        components.flatMap { $0 }
    }

    public static func buildArray(_ components: [[Column<RowValue>]]) -> [Column<RowValue>] {
        components.flatMap { $0 }
    }

    public static func buildEither(first component: [Column<RowValue>]) -> [Column<RowValue>] {
        component
    }
    
    public static func buildEither(second component: [Column<RowValue>]) -> [Column<RowValue>] {
        component
    }
    
    public static func buildOptional(_ component: [Column<RowValue>]?) -> [Column<RowValue>] {
        component ?? []
    }
    
    public static func buildExpression(_ expression: Column<RowValue>) -> [Column<RowValue>] {
        [expression]
    }
    
    public static func buildExpression(_ expression: Void) -> [Column<RowValue>] {
        [Column]()
    }
}
