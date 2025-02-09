//
//  MacTableApp.swift
//  MacTable
//
//  Created by Klajd Deda on 01/05/23.
//  Copyright (C) 1997-2025 id-design, inc. All rights reserved.
//

import SwiftUI
import Log4swift

@main
struct MacTableApp: App {
    init() {
        let logRootURL = URL.home.appendingPathComponent("Library/Logs/MacTableApp")
        Log4swift.configure(fileLogConfig: try? .init(logRootURL: logRootURL, appPrefix: "MacTableApp", appSuffix: "", daysToKeep: 30))
        Log4swift[Self.self].info("Starting ...")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
