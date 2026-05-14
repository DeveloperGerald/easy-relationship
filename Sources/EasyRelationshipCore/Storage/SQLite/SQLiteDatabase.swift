import Foundation
import SQLite3

public final class SQLiteDatabase: @unchecked Sendable {
    private var db: OpaquePointer?
    private let queue: DispatchQueue
    private let queueKey = DispatchSpecificKey<UInt8>()

    public init(fileURL: URL) throws {
        self.queue = DispatchQueue(label: "EasyRelationship.SQLiteDatabase")
        self.queue.setSpecific(key: queueKey, value: 1)
        var pointer: OpaquePointer?
        let result = sqlite3_open(fileURL.path, &pointer)
        guard result == SQLITE_OK else {
            throw SQLiteError(code: result, message: "Failed to open database")
        }
        db = pointer

        sqlite3_busy_timeout(pointer, 2000)

        try execute("PRAGMA foreign_keys = ON;")
        try execute("PRAGMA journal_mode = WAL;")
    }

    deinit {
        if let db {
            sqlite3_close(db)
        }
    }

    public func execute(_ sql: String) throws {
        try syncOnQueue {
            guard let db else {
                throw SQLiteError(code: -1, message: "Database not open")
            }
            var errorMessagePointer: UnsafeMutablePointer<Int8>?
            let result = sqlite3_exec(db, sql, nil, nil, &errorMessagePointer)
            guard result == SQLITE_OK else {
                let message = errorMessagePointer.map { String(cString: $0) } ?? "SQLite error"
                sqlite3_free(errorMessagePointer)
                throw SQLiteError(code: result, message: message)
            }
        }
    }

    public func withStatement<T>(_ sql: String, _ body: (SQLiteStatement) throws -> T) throws -> T {
        try syncOnQueue {
            guard let db else {
                throw SQLiteError(code: -1, message: "Database not open")
            }
            var statementPointer: OpaquePointer?
            let result = sqlite3_prepare_v2(db, sql, -1, &statementPointer, nil)
            guard result == SQLITE_OK, let statementPointer else {
                throw SQLiteError(code: result, message: lastErrorMessage())
            }

            let statement = SQLiteStatement(pointer: statementPointer)
            defer { sqlite3_finalize(statementPointer) }
            return try body(statement)
        }
    }

    public func inTransaction<T>(_ body: () throws -> T) throws -> T {
        try syncOnQueue {
            try executeUnsafe("BEGIN IMMEDIATE;")
            do {
                let result = try body()
                try executeUnsafe("COMMIT;")
                return result
            } catch {
                try? executeUnsafe("ROLLBACK;")
                throw error
            }
        }
    }

    public func lastErrorMessage() -> String {
        guard let db, let cString = sqlite3_errmsg(db) else {
            return "SQLite error"
        }
        return String(cString: cString)
    }

    private func executeUnsafe(_ sql: String) throws {
        guard let db else {
            throw SQLiteError(code: -1, message: "Database not open")
        }
        var errorMessagePointer: UnsafeMutablePointer<Int8>?
        let result = sqlite3_exec(db, sql, nil, nil, &errorMessagePointer)
        guard result == SQLITE_OK else {
            let message = errorMessagePointer.map { String(cString: $0) } ?? "SQLite error"
            sqlite3_free(errorMessagePointer)
            throw SQLiteError(code: result, message: message)
        }
    }

    private func syncOnQueue<T>(_ body: () throws -> T) throws -> T {
        if DispatchQueue.getSpecific(key: queueKey) != nil {
            return try body()
        }
        return try queue.sync(execute: body)
    }
}
