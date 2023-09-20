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
        func fetchFiles(url: URL, batchID: Int, batchSize: Int) -> [File] {
            let files = url
                .contentsOfDirectory
                .enumerated()
                .map { File.init(fileURL: $0.element) }

            let rv = batchID == 0 ? files : Array(files.prefix(min(files.count, batchSize)))

            let newValues: [File] = rv.map { file in
                var newCopy = file

                if batchSize != 0 {
                    newCopy.batchID = batchID
                    newCopy.logicalSize += newCopy.logicalSize * Int64.random(in: newCopy.logicalSize ... newCopy.logicalSize * 10)
                    newCopy.physicalSize += newCopy.physicalSize * Int64.random(in: newCopy.logicalSize ... newCopy.logicalSize * 10)
                }
                return newCopy
            }

            return newValues
        }

        return Self(
            fetchFiles: { url in
                return fetchFiles(url: url, batchID: 0, batchSize: 0)
            },
            loadAnotherBatch: { url, batchID in
                return fetchFiles(url: url, batchID: batchID, batchSize: Int.random(in: 5 ... 50))
            }
        )
    }()
}

