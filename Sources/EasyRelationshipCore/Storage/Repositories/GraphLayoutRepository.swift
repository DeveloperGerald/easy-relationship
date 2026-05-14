import Foundation

public struct GraphLayoutRepository: Sendable {
    private let database: SQLiteDatabase

    public init(database: SQLiteDatabase) {
        self.database = database
    }

    public func load(groupId: String) throws -> GraphLayout? {
        try database.withStatement(
            "SELECT version, node_positions_json, updated_at FROM graph_layouts WHERE group_id = ? LIMIT 1;"
        ) { statement in
            statement.bindText(groupId, index: 1)
            let result = statement.step()
            guard result == SQLiteStatement.row else {
                return nil
            }

            let version = statement.columnInt(0)
            let json = statement.columnText(1) ?? "{}"
            let updatedAt = Date(timeIntervalSince1970: TimeInterval(statement.columnInt64(2)))

            let payload = try decodePayload(json)
            return GraphLayout(
                groupId: groupId,
                version: version,
                nodePositions: payload.positions,
                lockedNodeIds: Set(payload.locked),
                updatedAt: updatedAt
            )
        }
    }

    public func save(_ layout: GraphLayout) throws {
        let payload = Payload(positions: layout.nodePositions, locked: Array(layout.lockedNodeIds))
        let json = try encodePayload(payload)
        let updatedAt = Int64(layout.updatedAt.timeIntervalSince1970)

        try database.withStatement(
            "INSERT OR REPLACE INTO graph_layouts(group_id, version, node_positions_json, updated_at) VALUES(?, ?, ?, ?);"
        ) { statement in
            statement.bindText(layout.groupId, index: 1)
            statement.bindInt(layout.version, index: 2)
            statement.bindText(json, index: 3)
            statement.bindInt64(updatedAt, index: 4)
            let result = statement.step()
            guard result == SQLiteStatement.done else {
                throw SQLiteError(code: result, message: database.lastErrorMessage())
            }
        }
    }

    private struct Payload: Codable, Sendable {
        var positions: [String: GraphPoint]
        var locked: [String]
    }

    private func encodePayload(_ payload: Payload) throws -> String {
        let data = try JSONEncoder().encode(payload)
        guard let string = String(data: data, encoding: .utf8) else {
            throw SQLiteError(code: -1, message: "Failed to encode JSON")
        }
        return string
    }

    private func decodePayload(_ json: String) throws -> Payload {
        let data = Data(json.utf8)
        return try JSONDecoder().decode(Payload.self, from: data)
    }
}

