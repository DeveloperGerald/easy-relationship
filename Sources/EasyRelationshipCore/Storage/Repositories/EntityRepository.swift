import Foundation

public struct EntityRepository: Sendable {
    private let database: SQLiteDatabase

    public init(database: SQLiteDatabase) {
        self.database = database
    }

    public func create(
        groupId: String,
        name: String,
        attributes: [String: String],
        now: Date = Date()
    ) throws -> Entity {
        let id = UUID().uuidString
        let createdAt = now
        let updatedAt = now
        let attributesJSON = try SQLiteJSON.encodeDictionary(attributes)

        try database.withStatement(
            "INSERT INTO entities(id, group_id, name, attributes_json, created_at, updated_at) VALUES(?, ?, ?, ?, ?, ?);"
        ) { statement in
            statement.bindText(id, index: 1)
            statement.bindText(groupId, index: 2)
            statement.bindText(name, index: 3)
            statement.bindText(attributesJSON, index: 4)
            statement.bindInt64(Int64(createdAt.timeIntervalSince1970), index: 5)
            statement.bindInt64(Int64(updatedAt.timeIntervalSince1970), index: 6)
            let result = statement.step()
            guard result == SQLiteStatement.done else {
                throw SQLiteError(code: result, message: database.lastErrorMessage())
            }
        }

        return Entity(
            id: id,
            groupId: groupId,
            name: name,
            attributes: attributes,
            createdAt: createdAt,
            updatedAt: updatedAt
        )
    }

    public func list(groupId: String) throws -> [Entity] {
        try database.withStatement(
            "SELECT id, group_id, name, attributes_json, created_at, updated_at FROM entities WHERE group_id = ? ORDER BY updated_at DESC;"
        ) { statement in
            statement.bindText(groupId, index: 1)
            var result: [Entity] = []
            while statement.step() == SQLiteStatement.row {
                let id = statement.columnText(0) ?? ""
                let groupId = statement.columnText(1) ?? ""
                let name = statement.columnText(2) ?? ""
                let attributesJSON = statement.columnText(3) ?? "{}"
                let createdAt = Date(timeIntervalSince1970: TimeInterval(statement.columnInt64(4)))
                let updatedAt = Date(timeIntervalSince1970: TimeInterval(statement.columnInt64(5)))

                let attributes = (try? SQLiteJSON.decodeDictionary(attributesJSON)) ?? [:]
                result.append(
                    Entity(
                        id: id,
                        groupId: groupId,
                        name: name,
                        attributes: attributes,
                        createdAt: createdAt,
                        updatedAt: updatedAt
                    )
                )
            }
            return result
        }
    }

    public func search(groupId: String, nameQuery: String) throws -> [Entity] {
        let pattern = "%" + nameQuery + "%"
        return try database.withStatement(
            "SELECT id, group_id, name, attributes_json, created_at, updated_at FROM entities WHERE group_id = ? AND name LIKE ? ORDER BY updated_at DESC;"
        ) { statement in
            statement.bindText(groupId, index: 1)
            statement.bindText(pattern, index: 2)
            var result: [Entity] = []
            while statement.step() == SQLiteStatement.row {
                let id = statement.columnText(0) ?? ""
                let groupId = statement.columnText(1) ?? ""
                let name = statement.columnText(2) ?? ""
                let attributesJSON = statement.columnText(3) ?? "{}"
                let createdAt = Date(timeIntervalSince1970: TimeInterval(statement.columnInt64(4)))
                let updatedAt = Date(timeIntervalSince1970: TimeInterval(statement.columnInt64(5)))
                let attributes = (try? SQLiteJSON.decodeDictionary(attributesJSON)) ?? [:]
                result.append(Entity(id: id, groupId: groupId, name: name, attributes: attributes, createdAt: createdAt, updatedAt: updatedAt))
            }
            return result
        }
    }

    public func update(
        entityId: String,
        name: String,
        attributes: [String: String],
        now: Date = Date()
    ) throws {
        let attributesJSON = try SQLiteJSON.encodeDictionary(attributes)
        try database.withStatement(
            "UPDATE entities SET name = ?, attributes_json = ?, updated_at = ? WHERE id = ?;"
        ) { statement in
            statement.bindText(name, index: 1)
            statement.bindText(attributesJSON, index: 2)
            statement.bindInt64(Int64(now.timeIntervalSince1970), index: 3)
            statement.bindText(entityId, index: 4)
            let result = statement.step()
            guard result == SQLiteStatement.done else {
                throw SQLiteError(code: result, message: database.lastErrorMessage())
            }
        }
    }

    public func delete(entityId: String) throws {
        try database.withStatement("DELETE FROM entities WHERE id = ?;") { statement in
            statement.bindText(entityId, index: 1)
            let result = statement.step()
            guard result == SQLiteStatement.done else {
                throw SQLiteError(code: result, message: database.lastErrorMessage())
            }
        }
    }
}
