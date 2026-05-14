import Foundation
import SQLite3

public struct SQLiteStatement {
    fileprivate let pointer: OpaquePointer

    public static let row: Int32 = SQLITE_ROW
    public static let done: Int32 = SQLITE_DONE

    private static let transientDestructor = unsafeBitCast(-1, to: sqlite3_destructor_type.self)

    init(pointer: OpaquePointer) {
        self.pointer = pointer
    }

    public func bindText(_ value: String?, index: Int32) {
        if let value {
            sqlite3_bind_text(pointer, index, value, -1, SQLiteStatement.transientDestructor)
        } else {
            sqlite3_bind_null(pointer, index)
        }
    }

    public func bindInt(_ value: Int, index: Int32) {
        sqlite3_bind_int64(pointer, index, sqlite3_int64(value))
    }

    public func bindInt64(_ value: Int64, index: Int32) {
        sqlite3_bind_int64(pointer, index, sqlite3_int64(value))
    }

    public func step() -> Int32 {
        sqlite3_step(pointer)
    }

    public func reset() {
        sqlite3_reset(pointer)
        sqlite3_clear_bindings(pointer)
    }

    public func columnText(_ index: Int32) -> String? {
        guard let cString = sqlite3_column_text(pointer, index) else {
            return nil
        }
        return String(cString: cString)
    }

    public func columnInt64(_ index: Int32) -> Int64 {
        sqlite3_column_int64(pointer, index)
    }

    public func columnInt(_ index: Int32) -> Int {
        Int(sqlite3_column_int64(pointer, index))
    }
}
