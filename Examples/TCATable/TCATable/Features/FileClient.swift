//
//  FileClient.swift
//  TCATable
//
//  Created by Klajd Deda on 11/3/22.
//  Copyright (C) 1997-2024 id-design, inc. All rights reserved.
//

import Foundation
import ComposableArchitecture
import XCTestDynamicOverlay

public struct FileClient: Sendable {
    /**
     Given a url, return all files under it
     Start fetching files under ~/Desktop ...
     This will work because we removed entitlements from this app
     */
    let fetchFiles:       @Sendable (_ url: URL) async -> [File]
    let loadAnotherBatch: @Sendable (_ url: URL, _ batchID: Int) async -> [File]
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
        let files: LockIsolated<[File]> = .init([])

        @Sendable
        func fetchFiles(url: URL, batchID: Int) -> [File] {
            let files = {
                guard files.isEmpty
                else { return files.value }

                // load once
                let files_ = url
                    .contentsOfDirectory
                    .enumerated()
                    .map { File.init(fileURL: $0.element) }
                    .sorted { $0.fileName > $1.fileName }

                files.withValue {
                    $0 = Array(files_.prefix(min(files_.count, maxCount)))
                }
                return files.value
            }()

            if batchID == 0 {
                return files
            }

            let newValues: [File] = files.map { file in
                var newCopy = file

                newCopy.id = .init()
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

