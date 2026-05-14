import Foundation

public struct ExportService: Sendable {
    private let database: SQLiteDatabase

    public init(database: SQLiteDatabase) {
        self.database = database
    }

    public func exportGroupJSON(groupId: String) throws -> Data {
        let group = try fetchGroup(groupId: groupId)
        let entities = try EntityRepository(database: database).list(groupId: groupId)
        let attributeDefinitions = try AttributeDefinitionRepository(database: database).list(groupId: groupId)
        let relationTypes = try RelationTypeRepository(database: database).list(groupId: groupId)
        let relations = try RelationRepository(database: database).list(groupId: groupId)

        let payload: [String: Any] = [
            "group": [
                "id": group.id,
                "name": group.name,
                "createdAt": Int64(group.createdAt.timeIntervalSince1970),
                "updatedAt": Int64(group.updatedAt.timeIntervalSince1970)
            ],
            "attributeDefinitions": attributeDefinitions.map {
                [
                    "id": $0.id,
                    "groupId": $0.groupId,
                    "key": $0.key,
                    "label": $0.label,
                    "type": $0.type.rawValue,
                    "required": $0.required,
                    "options": $0.options,
                    "sortOrder": $0.sortOrder
                ]
            },
            "entities": entities.map {
                [
                    "id": $0.id,
                    "groupId": $0.groupId,
                    "name": $0.name,
                    "attributes": $0.attributes,
                    "createdAt": Int64($0.createdAt.timeIntervalSince1970),
                    "updatedAt": Int64($0.updatedAt.timeIntervalSince1970)
                ]
            },
            "relationTypes": relationTypes.map {
                [
                    "id": $0.id,
                    "groupId": $0.groupId,
                    "name": $0.name,
                    "directional": $0.directional,
                    "style": $0.style
                ]
            },
            "relations": relations.map {
                [
                    "id": $0.id,
                    "groupId": $0.groupId,
                    "fromEntityId": $0.fromEntityId,
                    "toEntityId": $0.toEntityId,
                    "relationTypeId": $0.relationTypeId,
                    "attributes": $0.attributes,
                    "createdAt": Int64($0.createdAt.timeIntervalSince1970)
                ]
            }
        ]

        return try JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys])
    }

    private func fetchGroup(groupId: String) throws -> Group {
        try database.withStatement(
            "SELECT id, name, created_at, updated_at FROM groups WHERE id = ? LIMIT 1;"
        ) { statement in
            statement.bindText(groupId, index: 1)
            let stepResult = statement.step()
            guard stepResult == SQLiteStatement.row else {
                throw SQLiteError(code: stepResult, message: "Group not found")
            }
            let id = statement.columnText(0) ?? ""
            let name = statement.columnText(1) ?? ""
            let createdAt = Date(timeIntervalSince1970: TimeInterval(statement.columnInt64(2)))
            let updatedAt = Date(timeIntervalSince1970: TimeInterval(statement.columnInt64(3)))
            return Group(id: id, name: name, createdAt: createdAt, updatedAt: updatedAt)
        }
    }
}
