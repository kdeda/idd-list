//
//  MacTableApp.swift
//  MacTable
//
//  Created by Klajd Deda on 01/05/23.
//  Copyright (C) 1997-2023 id-design, inc. All rights reserved.
//

import SwiftUI
import Log4swift

@main
struct MacTableApp: App {
    init() {
        Log4swift.configure(appName: "MacTableApp")
        Log4swift[Self.self].info("Starting ...")
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
