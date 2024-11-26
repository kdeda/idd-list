//
//  CellView.swift
//  IDDList
//
//  Created by Klajd Deda on 01/05/23.
//  Copyright (C) 1997-2024 id-design, inc. All rights reserved.
//

import Foundation
import SwiftUI

public struct CellView<Content>: View where Content: View {
    @EnvironmentObject var cellModel: CellModel
    let content: (_ cellModel: CellModel) -> Content

    public init(@ViewBuilder content: @escaping (_ cellModel: CellModel) -> Content) {
        self.content = content
    }

    public var body: some View {
        self.content(cellModel)
    }
}
