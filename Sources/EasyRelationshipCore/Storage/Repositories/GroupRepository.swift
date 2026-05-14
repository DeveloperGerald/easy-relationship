import Foundation

public struct GroupRepository: Sendable {
    private let database: SQLiteDatabase

    public init(database: SQLiteDatabase) {
        self.database = database
    }

    public func create(name: String, now: Date = Date()) throws -> Group {
        let id = UUID().uuidString
        let createdAt = now
        let updatedAt = now

        try database.withStatement(
            "INSERT INTO groups(id, name, created_at, updated_at) VALUES(?, ?, ?, ?);"
        ) { statement in
            statement.bindText(id, index: 1)
            statement.bindText(name, index: 2)
            statement.bindInt64(Int64(createdAt.timeIntervalSince1970), index: 3)
            statement.bindInt64(Int64(updatedAt.timeIntervalSince1970), index: 4)
            let result = statement.step()
            guard result == SQLiteStatement.done else {
                throw SQLiteError(code: result, message: database.lastErrorMessage())
            }
        }

        return Group(id: id, name: name, createdAt: createdAt, updatedAt: updatedAt)
    }

    public func list() throws -> [Group] {
        try database.withStatement(
            "SELECT id, name, created_at, updated_at FROM groups ORDER BY updated_at DESC;"
        ) { statement in
            var result: [Group] = []
            while statement.step() == SQLiteStatement.row {
                let id = statement.columnText(0) ?? ""
                let name = statement.columnText(1) ?? ""
                let createdAt = Date(timeIntervalSince1970: TimeInterval(statement.columnInt64(2)))
                let updatedAt = Date(timeIntervalSince1970: TimeInterval(statement.columnInt64(3)))
                result.append(Group(id: id, name: name, createdAt: createdAt, updatedAt: updatedAt))
            }
            return result
        }
    }

    public func updateName(groupId: String, name: String, now: Date = Date()) throws {
        try database.withStatement(
            "UPDATE groups SET name = ?, updated_at = ? WHERE id = ?;"
        ) { statement in
            statement.bindText(name, index: 1)
            statement.bindInt64(Int64(now.timeIntervalSince1970), index: 2)
            statement.bindText(groupId, index: 3)
            let result = statement.step()
            guard result == SQLiteStatement.done else {
                throw SQLiteError(code: result, message: database.lastErrorMessage())
            }
        }
    }

    public func delete(groupId: String) throws {
        try database.withStatement("DELETE FROM groups WHERE id = ?;") { statement in
            statement.bindText(groupId, index: 1)
            let result = statement.step()
            guard result == SQLiteStatement.done else {
                throw SQLiteError(code: result, message: database.lastErrorMessage())
            }
        }
    }
}
