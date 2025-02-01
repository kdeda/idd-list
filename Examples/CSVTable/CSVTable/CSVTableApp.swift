//
//  CSVTableApp.swift
//  CSVTable
//
//  Created by Klajd Deda on 12/27/21.
//  Copyright (C) 1997-2025 id-design, inc. All rights reserved.
//

import SwiftUI
import Log4swift
import ComposableArchitecture

@main
struct CSVTableApp: App {
    let store: StoreOf<AppRoot>

    init() {
        let logRootURL = URL.home.appendingPathComponent("Library/Logs/CSVTableApp")
        Log4swift.configure(fileLogConfig: try? .init(logRootURL: logRootURL, appPrefix: "CSVTableApp", appSuffix: "", daysToKeep: 30))
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
