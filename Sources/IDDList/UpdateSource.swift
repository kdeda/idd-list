//
//  UpdateSource.swift
//  IDDList
//
//  Created by Klajd Deda on 9/19/24.
//  Copyright (C) 1997-2025 id-design, inc. All rights reserved.
//

/**
 Gives us a bit of sanity as to the directions of push.
 We can travel from the swift ui, or the model to the NSView
 Or from NSView to swiftUI.
 */
enum UpdateSource {
    case none
    // we got here as a result of changes from the fromUpdateNSView, but really due to the model chages
    case fromUpdateNSView

    // true if we are called from TableViewCoordinator
    // usually as  a result of NSView clicks
    case fromCoordinator
}
