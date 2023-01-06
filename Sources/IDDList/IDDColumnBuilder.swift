//
//  IDDColumnBuilder.swift
//  IDDList
//
//  Created by Klajd Deda on 01/05/23.
//  Copyright (C) 1997-2023 id-design, inc. All rights reserved.
//

import Foundation

@resultBuilder
public enum IDDColumnBuilder<RowValue>
    where RowValue: Identifiable, RowValue: Equatable
{
    public static func buildBlock(_ components: IDDColumn<RowValue>...) -> [IDDColumn<RowValue>] {
        components
    }
    
    public static func buildEither(first component: [IDDColumn<RowValue>]) -> [IDDColumn<RowValue>] {
        component
    }
    
    public static func buildEither(second component: [IDDColumn<RowValue>]) -> [IDDColumn<RowValue>] {
        component
    }
    
    public static func buildOptional(_ component: [IDDColumn<RowValue>]?) -> [IDDColumn<RowValue>] {
        component ?? []
    }
    
    public static func buildBlock(_ components: [IDDColumn<RowValue>]...) -> [IDDColumn<RowValue>] {
        // TODO: this crashes - not sure why
        components.flatMap { $0 }
    }
    
    public static func buildExpression(_ expression: IDDColumn<RowValue>) -> [IDDColumn<RowValue>] {
        [expression]
    }
    
    public static func buildExpression(_ expression: Void) -> [IDDColumn<RowValue>] {
        [IDDColumn]()
    }
}
