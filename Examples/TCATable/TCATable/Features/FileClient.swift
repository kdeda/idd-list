//
//  FileClient.swift
//  TCATable
//
//  Created by Klajd Deda on 11/3/22.
//  Copyright (C) 1997-2023 id-design, inc. All rights reserved.
//

import Foundation
import ComposableArchitecture
import XCTestDynamicOverlay

public struct FileClient {
    /**
     Given a url, return all files under it
     Start fetching files under ~/Desktop ...
     This will work because we removed entitlements from this app
     */
    let fetchFiles: (_ url: URL) async -> [File]
    let loadAnotherBatch: (_ url: URL, _ batchID: Int) async -> [File]
}

extension DependencyValues {
    public var fileClient: FileClient {
        get { self[FileClient.self] }
        set { self[FileClient.self] = newValue }
    }
}

extension FileClient: DependencyKey {
    public static let liveValue: Self = {
        // make sur eto use a giant folder
        // "/Volumes/Vault/Library/FoldersWithLotsOfFiles/18000 files"
        let maxCount = 100_000
        // let maxCount = 10
        var files: [File] = []

        func fetchFiles(url: URL, batchID: Int) -> [File] {
            let files = {
                guard files.isEmpty
                else { return files }

                // load once
                let files_ = url
                    .contentsOfDirectory
                    .enumerated()
                    .map { File.init(fileURL: $0.element) }
                    .sorted { $0.fileName > $1.fileName }

                files = Array(files_.prefix(min(files_.count, maxCount)))
                return files
            }()

            if batchID == 0 {
                return files
            }

            let newValues: [File] = files.map { file in
                var newCopy = file

                newCopy.batchID = batchID
                newCopy.fileName = newCopy.fileName + " (\(batchID))"
                newCopy.logicalSize += newCopy.logicalSize * Int64.random(in: newCopy.logicalSize ... newCopy.logicalSize * 10)
                newCopy.physicalSize += newCopy.physicalSize * Int64.random(in: newCopy.logicalSize ... newCopy.logicalSize * 10)
                return newCopy
            }
            return newValues
        }

        return Self(
            fetchFiles: { url in
                return fetchFiles(url: url, batchID: 0)
            },
            loadAnotherBatch: { url, batchID in
                return fetchFiles(url: url, batchID: batchID) // Int.random(in: 5 ... 50))
            }
        )
    }()
}

