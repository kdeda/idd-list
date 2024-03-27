//
//  CSVClient.swift
//  CSVTable
//
//  Created by Klajd Deda on 11/3/22.
//  Copyright (C) 1997-2023 id-design, inc. All rights reserved.
//

import Foundation
import ComposableArchitecture
import IDDSwift
import Log4swift
import XCTestDynamicOverlay

public struct CSVClient {
    /**
     Given a CSV file, return a stream of all rows in it.
     */
    let parseCSVFile: (_ url: URL) -> AsyncStream<[CSVRow]>
}

extension DependencyValues {
    public var csvClient: CSVClient {
        get { self[CSVClient.self] }
        set { self[CSVClient.self] = newValue }
    }
}

extension CSVClient: DependencyKey {
    public static let liveValue: Self = {
        return Self(
            parseCSVFile: { url in
                let charsToBeDeleted = CharacterSet(charactersIn: "\"{]}")
                let defaultSeparator = "\","
                let columnNamesSeparator = ","

                @Sendable func fileRows() -> AsyncStream<CSVRow> {
                    AsyncStream { continuation in
                        let task = Task.detached {
                            do {
                                // Read each line of the data as it becomes available.
                                for try await line in url.lines {
                                    let result: (columns: [String], parsedLine: String) = {
                                        let columns = line.components(separatedBy: defaultSeparator)

                                        guard columns.count > 1
                                        else {
                                            let columns = line.components(separatedBy: columnNamesSeparator)
                                            let parsedLine = columns.joined(separator: ",")

                                            return (columns, parsedLine)
                                        }

                                        let columns_ = columns.map { $0.trimmingCharacters(in: charsToBeDeleted) }
                                        let parsedLine = "\"\(columns_.joined(separator: "\",\""))\""
                                        return (columns_, parsedLine)
                                    }()

                                    if !result.columns.isEmpty {
                                        // Do something with line.

                                        if line != result.parsedLine {
                                            // these should match ...
                                            Log4swift[Self.self].error(function: "parseCSVFile", "line: '\(line)'")
                                            Log4swift[Self.self].error(function: "parseCSVFile", "line: '\(result.parsedLine)'")
                                        }

                                        continuation.yield(CSVRow.init(id: 0, columns: result.columns))
                                        try? await Task.sleep(nanoseconds: NSEC_PER_MSEC * 5)
                                    }
                                }
                            } catch {
                                Log4swift[Self.self].error(function: "fileRows", "error: \(error)")
                            }

                            continuation.finish()
                        }

                        continuation.onTermination = { _ in
                            Log4swift[Self.self].info(function: "fileRows", "terminated ...")
                            task.cancel()
                        }
                    }
                }

                return AsyncStream { continuation in
                    let task = Task.detached {
                        // don't bother to push upstream too often
                        for try await fileRows in fileRows().collect(waitForMilliseconds: 100) {
                            continuation.yield(fileRows)
                        }
                        continuation.finish()
                    }

                    continuation.onTermination = { _ in
                        Log4swift[Self.self].info(function: "parseCSVFile", "terminated ...")
                        task.cancel()
                    }
                }
            }
        )
    }()
}

