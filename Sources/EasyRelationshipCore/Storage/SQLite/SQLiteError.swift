import Foundation

public struct SQLiteError: Error, Sendable, Equatable {
    public var code: Int32
    public var message: String

    public init(code: Int32, message: String) {
        self.code = code
        self.message = message
    }
}

