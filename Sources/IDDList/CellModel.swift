//
//  CellModel.swift
//  IDDList
//
//  Created by Klajd Deda on 01/05/23.
//  Copyright (C) 1997-2023 id-design, inc. All rights reserved.
//

import Foundation
import SwiftUI
import Log4swift

public final class CellModel: ObservableObject {
    @Published public var isHighlighted: Bool = false

    public init(isHighlighted: Bool = false) {
        self.isHighlighted = isHighlighted
    }
    
    public var objectID: String {
        ObjectIdentifier(self).debugDescription
    }

    /**
     Avoid the dreaded
     Publishing changes from within view updates is not allowed, this will cause undefined behavior.
     */
    public func updateIsHighlighted(_ newValue: Bool) {
        if self.isHighlighted != newValue {
            Task { @MainActor in
                Log4swift[Self.self].info("backgroundStyle: '\(self.objectID)' isHighlighted: '\(newValue)' was: '\(self.isHighlighted)'")
                self.isHighlighted = newValue
            }
        }
    }
}
