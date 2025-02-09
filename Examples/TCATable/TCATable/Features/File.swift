//
//  File.swift
//  TCATable
//
//  Created by Klajd Deda on 12/27/21.
//  Copyright (C) 1997-2025 id-design, inc. All rights reserved.
//

import Foundation
import AppKit
import IDDSwift

struct File: Equatable, Identifiable {
    static let lastModified: DateFormatter = {
        let rv = DateFormatter.init()
        
        rv.formatterBehavior = .behavior10_4
        rv.dateFormat = "MMM d, yyy 'at' h:mm:ss a"
        return rv
    }()

    var id = UUID()
    // we use this to emulate more rows
    // so the cloned id = original.id + files.count * batchCount
    var batchID: Int

    // this is derived and so it does not participate in the copy process
    // this allows sorting to be a tad bit faster
    var fileURL: URL {
        URL(fileURLWithPath: filePath)
    }
    
    let relativePath: String
    var logicalSize: Int64
    var physicalSize: Int64
    let modificationDate: Date
    var fileName: String
    var filePath: String

    init(fileURL: URL) {
        // self.fileURL = fileURL
        // TODO: figure a better way to display relative paths ...
        self.relativePath = fileURL.path
        self.logicalSize = fileURL.logicalSize
        self.physicalSize = fileURL.physicalSize
        self.modificationDate = fileURL.contentModificationDate
        self.fileName = fileURL.lastPathComponent
        self.filePath = fileURL.path
        self.batchID = 0
    }
    
    var icon: NSImage {
        NSWorkspace.shared.icon(forFile: filePath)
    }
}

extension File: Hashable {}

extension File: Comparable {
    static func < (lhs: File, rhs: File) -> Bool {
        false
    }
}

extension URL {
    /// Returns an array of immediate child urls, without recursing deep into the file hierarchy
    var contentsOfDirectory: [URL] {
        (try? FileManager.default.contentsOfDirectory(
            at: self,
            includingPropertiesForKeys: nil,
            options: .producesRelativePathURLs
        )) ?? []
    }
}
