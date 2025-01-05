//
//  CellView.swift
//  IDDList
//
//  Created by Klajd Deda on 01/05/23.
//  Copyright (C) 1997-2025 id-design, inc. All rights reserved.
//

import Foundation
import SwiftUI

public struct CellView<Content>: View where Content: View {
    @EnvironmentObject var cellModel: CellModel
    let content: @MainActor @Sendable (_ cellModel: CellModel) -> Content

    /**
     By default, methods of any struct conforming to View inherit the MainActor isolation.
     So here content is implicitly @MainActor as well.
     */
    public init(@ViewBuilder content: @MainActor @Sendable @escaping (_ cellModel: CellModel) -> Content) {
        self.content = content
    }

    public var body: some View {
        self.content(cellModel)
    }
}
