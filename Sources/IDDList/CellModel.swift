//
//  CellModel.swift
//  IDDList
//
//  Created by Klajd Deda on 01/05/23.
//  Copyright (C) 1997-2023 id-design, inc. All rights reserved.
//

import Foundation
import SwiftUI

public final class CellModel: ObservableObject {
    @Published public var isHighlighted: Bool = false

    public init(isHighlighted: Bool = false) {
        self.isHighlighted = isHighlighted
    }
    
    public var objectID: String {
        ObjectIdentifier(self).debugDescription
    }
}
