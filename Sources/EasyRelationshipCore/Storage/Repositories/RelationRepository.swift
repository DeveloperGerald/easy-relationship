import Foundation

public struct RelationRepository: Sendable {
    private let database: SQLiteDatabase

    public init(database: SQLiteDatabase) {
        self.database = database
    }

    public func create(
        groupId: String,
        fromEntityId: String,
        toEntityId: String,
        relationTypeId: String,
        attributes: [String: String] = [:],
        now: Date = Date()
    ) throws -> Relation {
        let id = UUID().uuidString
        let createdAt = now
        let attributesJSON = try SQLiteJSON.encodeDictionary(attributes)

        try database.withStatement(
            "INSERT INTO relations(id, group_id, from_entity_id, to_entity_id, relation_type_id, attributes_json, created_at) VALUES(?, ?, ?, ?, ?, ?, ?);"
        ) { statement in
            statement.bindText(id, index: 1)
            statement.bindText(groupId, index: 2)
            statement.bindText(fromEntityId, index: 3)
            statement.bindText(toEntityId, index: 4)
            statement.bindText(relationTypeId, index: 5)
            statement.bindText(attributesJSON, index: 6)
            statement.bindInt64(Int64(createdAt.timeIntervalSince1970), index: 7)
            let result = statement.step()
            guard result == SQLiteStatement.done else {
                throw SQLiteError(code: result, message: database.lastErrorMessage())
            }
        }

        return Relation(
            id: id,
            groupId: groupId,
            fromEntityId: fromEntityId,
            toEntityId: toEntityId,
            relationTypeId: relationTypeId,
            attributes: attributes,
            createdAt: createdAt
        )
    }

    public func list(groupId: String) throws -> [Relation] {
        try database.withStatement(
            "SELECT id, group_id, from_entity_id, to_entity_id, relation_type_id, attributes_json, created_at FROM relations WHERE group_id = ? ORDER BY created_at DESC;"
        ) { statement in
            statement.bindText(groupId, index: 1)
            var result: [Relation] = []
            while statement.step() == SQLiteStatement.row {
                let id = statement.columnText(0) ?? ""
                let groupId = statement.columnText(1) ?? ""
                let fromEntityId = statement.columnText(2) ?? ""
                let toEntityId = statement.columnText(3) ?? ""
                let relationTypeId = statement.columnText(4) ?? ""
                let attributesJSON = statement.columnText(5) ?? "{}"
                let createdAt = Date(timeIntervalSince1970: TimeInterval(statement.columnInt64(6)))
                let attributes = (try? SQLiteJSON.decodeDictionary(attributesJSON)) ?? [:]
                result.append(
                    Relation(
                        id: id,
                        groupId: groupId,
                        fromEntityId: fromEntityId,
                        toEntityId: toEntityId,
                        relationTypeId: relationTypeId,
                        attributes: attributes,
                        createdAt: createdAt
                    )
                )
            }
            return result
        }
    }

    public func delete(relationId: String) throws {
        try database.withStatement("DELETE FROM relations WHERE id = ?;") { statement in
            statement.bindText(relationId, index: 1)
            let result = statement.step()
            guard result == SQLiteStatement.done else {
                throw SQLiteError(code: result, message: database.lastErrorMessage())
            }
        }
    }

    public func update(
        relationId: String,
        groupId: String,
        fromEntityId: String,
        toEntityId: String,
        relationTypeId: String,
        attributes: [String: String] = [:]
    ) throws {
        let attributesJSON = try SQLiteJSON.encodeDictionary(attributes)
        try database.withStatement(
            "UPDATE relations SET group_id = ?, from_entity_id = ?, to_entity_id = ?, relation_type_id = ?, attributes_json = ? WHERE id = ?;"
        ) { statement in
            statement.bindText(groupId, index: 1)
            statement.bindText(fromEntityId, index: 2)
            statement.bindText(toEntityId, index: 3)
            statement.bindText(relationTypeId, index: 4)
            statement.bindText(attributesJSON, index: 5)
            statement.bindText(relationId, index: 6)
            let result = statement.step()
            guard result == SQLiteStatement.done else {
                throw SQLiteError(code: result, message: database.lastErrorMessage())
            }
        }
    }
}
