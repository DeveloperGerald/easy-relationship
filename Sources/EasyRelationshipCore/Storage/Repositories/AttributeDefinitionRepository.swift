import Foundation

public struct AttributeDefinitionRepository: Sendable {
    private let database: SQLiteDatabase

    public init(database: SQLiteDatabase) {
        self.database = database
    }

    public func create(
        groupId: String,
        key: String,
        label: String,
        type: AttributeValueType,
        required: Bool,
        options: [String],
        sortOrder: Int
    ) throws -> AttributeDefinition {
        let id = UUID().uuidString
        let optionsJSON = try SQLiteJSON.encodeStringArray(options)
        try database.withStatement(
            "INSERT INTO attribute_definitions(id, group_id, key, label, type, required, options_json, sort_order) VALUES(?, ?, ?, ?, ?, ?, ?, ?);"
        ) { statement in
            statement.bindText(id, index: 1)
            statement.bindText(groupId, index: 2)
            statement.bindText(key, index: 3)
            statement.bindText(label, index: 4)
            statement.bindText(type.rawValue, index: 5)
            statement.bindInt(required ? 1 : 0, index: 6)
            statement.bindText(optionsJSON, index: 7)
            statement.bindInt(sortOrder, index: 8)
            let result = statement.step()
            guard result == SQLiteStatement.done else {
                throw SQLiteError(code: result, message: database.lastErrorMessage())
            }
        }

        return AttributeDefinition(
            id: id,
            groupId: groupId,
            key: key,
            label: label,
            type: type,
            required: required,
            options: options,
            sortOrder: sortOrder
        )
    }

    public func update(
        attributeDefinitionId: String,
        groupId: String,
        key: String,
        label: String,
        type: AttributeValueType,
        required: Bool,
        options: [String],
        sortOrder: Int
    ) throws {
        let optionsJSON = try SQLiteJSON.encodeStringArray(options)
        try database.withStatement(
            "UPDATE attribute_definitions SET group_id = ?, key = ?, label = ?, type = ?, required = ?, options_json = ?, sort_order = ? WHERE id = ?;"
        ) { statement in
            statement.bindText(groupId, index: 1)
            statement.bindText(key, index: 2)
            statement.bindText(label, index: 3)
            statement.bindText(type.rawValue, index: 4)
            statement.bindInt(required ? 1 : 0, index: 5)
            statement.bindText(optionsJSON, index: 6)
            statement.bindInt(sortOrder, index: 7)
            statement.bindText(attributeDefinitionId, index: 8)
            let result = statement.step()
            guard result == SQLiteStatement.done else {
                throw SQLiteError(code: result, message: database.lastErrorMessage())
            }
        }
    }

    public func upsert(
        groupId: String,
        key: String,
        label: String,
        type: AttributeValueType,
        required: Bool,
        options: [String],
        sortOrder: Int
    ) throws -> AttributeDefinition {
        let existingId = try findId(groupId: groupId, key: key)
        if let existingId {
            try update(
                attributeDefinitionId: existingId,
                groupId: groupId,
                key: key,
                label: label,
                type: type,
                required: required,
                options: options,
                sortOrder: sortOrder
            )
            return AttributeDefinition(
                id: existingId,
                groupId: groupId,
                key: key,
                label: label,
                type: type,
                required: required,
                options: options,
                sortOrder: sortOrder
            )
        }

        return try create(
            groupId: groupId,
            key: key,
            label: label,
            type: type,
            required: required,
            options: options,
            sortOrder: sortOrder
        )
    }

    private func findId(groupId: String, key: String) throws -> String? {
        try database.withStatement(
            "SELECT id FROM attribute_definitions WHERE group_id = ? AND key = ? LIMIT 1;"
        ) { statement in
            statement.bindText(groupId, index: 1)
            statement.bindText(key, index: 2)
            let result = statement.step()
            guard result == SQLiteStatement.row else {
                return nil
            }
            return statement.columnText(0)
        }
    }

    public func list(groupId: String) throws -> [AttributeDefinition] {
        try database.withStatement(
            "SELECT id, group_id, key, label, type, required, options_json, sort_order FROM attribute_definitions WHERE group_id = ? ORDER BY sort_order ASC;"
        ) { statement in
            statement.bindText(groupId, index: 1)
            var result: [AttributeDefinition] = []
            while statement.step() == SQLiteStatement.row {
                let id = statement.columnText(0) ?? ""
                let groupId = statement.columnText(1) ?? ""
                let key = statement.columnText(2) ?? ""
                let label = statement.columnText(3) ?? ""
                let typeString = statement.columnText(4) ?? AttributeValueType.text.rawValue
                let type = AttributeValueType(rawValue: typeString) ?? .text
                let required = statement.columnInt(5) != 0
                let optionsJSON = statement.columnText(6) ?? "[]"
                let sortOrder = statement.columnInt(7)

                let options = (try? SQLiteJSON.decodeStringArray(optionsJSON)) ?? []
                result.append(
                    AttributeDefinition(
                        id: id,
                        groupId: groupId,
                        key: key,
                        label: label,
                        type: type,
                        required: required,
                        options: options,
                        sortOrder: sortOrder
                    )
                )
            }
            return result
        }
    }

    public func delete(attributeDefinitionId: String) throws {
        try database.withStatement("DELETE FROM attribute_definitions WHERE id = ?;") { statement in
            statement.bindText(attributeDefinitionId, index: 1)
            let result = statement.step()
            guard result == SQLiteStatement.done else {
                throw SQLiteError(code: result, message: database.lastErrorMessage())
            }
        }
    }
}
