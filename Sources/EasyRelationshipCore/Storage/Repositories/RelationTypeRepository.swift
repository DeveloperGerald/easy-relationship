import Foundation

public struct RelationTypeRepository: Sendable {
    private let database: SQLiteDatabase

    public init(database: SQLiteDatabase) {
        self.database = database
    }

    public func create(
        groupId: String,
        name: String,
        directional: Bool,
        style: [String: String] = [:]
    ) throws -> RelationType {
        let id = UUID().uuidString
        let styleJSON = try SQLiteJSON.encodeDictionary(style)
        try database.withStatement(
            "INSERT INTO relation_types(id, group_id, name, directional, style_json) VALUES(?, ?, ?, ?, ?);"
        ) { statement in
            statement.bindText(id, index: 1)
            statement.bindText(groupId, index: 2)
            statement.bindText(name, index: 3)
            statement.bindInt(directional ? 1 : 0, index: 4)
            statement.bindText(styleJSON, index: 5)
            let result = statement.step()
            guard result == SQLiteStatement.done else {
                throw SQLiteError(code: result, message: database.lastErrorMessage())
            }
        }
        return RelationType(id: id, groupId: groupId, name: name, directional: directional, style: style)
    }

    public func list(groupId: String) throws -> [RelationType] {
        try database.withStatement(
            "SELECT id, group_id, name, directional, style_json FROM relation_types WHERE group_id = ? ORDER BY name ASC;"
        ) { statement in
            statement.bindText(groupId, index: 1)
            var result: [RelationType] = []
            while statement.step() == SQLiteStatement.row {
                let id = statement.columnText(0) ?? ""
                let groupId = statement.columnText(1) ?? ""
                let name = statement.columnText(2) ?? ""
                let directional = statement.columnInt(3) != 0
                let styleJSON = statement.columnText(4) ?? "{}"
                let style = (try? SQLiteJSON.decodeDictionary(styleJSON)) ?? [:]
                result.append(RelationType(id: id, groupId: groupId, name: name, directional: directional, style: style))
            }
            return result
        }
    }

    public func delete(relationTypeId: String) throws {
        try database.withStatement("DELETE FROM relation_types WHERE id = ?;") { statement in
            statement.bindText(relationTypeId, index: 1)
            let result = statement.step()
            guard result == SQLiteStatement.done else {
                throw SQLiteError(code: result, message: database.lastErrorMessage())
            }
        }
    }

    public func update(
        relationTypeId: String,
        name: String,
        directional: Bool,
        style: [String: String] = [:]
    ) throws {
        let styleJSON = try SQLiteJSON.encodeDictionary(style)
        try database.withStatement(
            "UPDATE relation_types SET name = ?, directional = ?, style_json = ? WHERE id = ?;"
        ) { statement in
            statement.bindText(name, index: 1)
            statement.bindInt(directional ? 1 : 0, index: 2)
            statement.bindText(styleJSON, index: 3)
            statement.bindText(relationTypeId, index: 4)
            let result = statement.step()
            guard result == SQLiteStatement.done else {
                throw SQLiteError(code: result, message: database.lastErrorMessage())
            }
        }
    }
}
