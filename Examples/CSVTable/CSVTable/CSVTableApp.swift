//
//  CSVTableApp.swift
//  CSVTable
//
//  Created by Klajd Deda on 12/27/21.
//  Copyright (C) 1997-2023 id-design, inc. All rights reserved.
//

import SwiftUI
import Log4swift
import ComposableArchitecture

@main
struct CSVTableApp: App {
    let store: StoreOf<AppRoot>

    init() {
        Log4swift.configure(appName: "CSVTableApp")
        Log4swift[Self.self].info("Starting ...")
        
        self.store = Store(
            initialState: AppRoot.State(),
            reducer: AppRoot.init
        )
    }
    
    var body: some Scene {
        WindowGroup {
            AppRootView(store: store)
        }
    }
}
