import Foundation

public struct SchemaMigrator: Sendable {
    public init() {}

    public func migrate(_ database: SQLiteDatabase) throws {
        try database.execute("""
        CREATE TABLE IF NOT EXISTS schema_meta (
            key TEXT PRIMARY KEY,
            value TEXT NOT NULL
        );
        """)

        let currentVersion = try readSchemaVersion(database)
        if currentVersion < 1 {
            try createV1(database)
            try setSchemaVersion(database, version: 1)
        }
    }

    private func readSchemaVersion(_ database: SQLiteDatabase) throws -> Int {
        try database.withStatement("SELECT value FROM schema_meta WHERE key = 'schema_version' LIMIT 1;") { statement in
            let result = statement.step()
            if result == SQLiteStatement.row {
                let value = statement.columnText(0) ?? "0"
                return Int(value) ?? 0
            }
            return 0
        }
    }

    private func setSchemaVersion(_ database: SQLiteDatabase, version: Int) throws {
        try database.withStatement("INSERT OR REPLACE INTO schema_meta(key, value) VALUES('schema_version', ?);") { statement in
            statement.bindText(String(version), index: 1)
            let result = statement.step()
            guard result == SQLiteStatement.done else {
                throw SQLiteError(code: result, message: database.lastErrorMessage())
            }
        }
    }

    private func createV1(_ database: SQLiteDatabase) throws {
        try database.execute("""
        CREATE TABLE IF NOT EXISTS groups (
            id TEXT PRIMARY KEY,
            name TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL
        );
        """)

        try database.execute("""
        CREATE TABLE IF NOT EXISTS people (
            id TEXT PRIMARY KEY,
            group_id TEXT NOT NULL,
            name TEXT NOT NULL,
            attributes_json TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            updated_at INTEGER NOT NULL,
            FOREIGN KEY(group_id) REFERENCES groups(id) ON DELETE CASCADE
        );
        """)

        try database.execute("""
        CREATE INDEX IF NOT EXISTS idx_people_group_id ON people(group_id);
        """)

        try database.execute("""
        CREATE TABLE IF NOT EXISTS attribute_definitions (
            id TEXT PRIMARY KEY,
            group_id TEXT NOT NULL,
            key TEXT NOT NULL,
            label TEXT NOT NULL,
            type TEXT NOT NULL,
            required INTEGER NOT NULL,
            options_json TEXT NOT NULL,
            sort_order INTEGER NOT NULL,
            FOREIGN KEY(group_id) REFERENCES groups(id) ON DELETE CASCADE
        );
        """)

        try database.execute("""
        CREATE UNIQUE INDEX IF NOT EXISTS uniq_attrdef_group_key ON attribute_definitions(group_id, key);
        """)

        try database.execute("""
        CREATE TABLE IF NOT EXISTS relation_types (
            id TEXT PRIMARY KEY,
            group_id TEXT NOT NULL,
            name TEXT NOT NULL,
            directional INTEGER NOT NULL,
            style_json TEXT NOT NULL,
            FOREIGN KEY(group_id) REFERENCES groups(id) ON DELETE CASCADE
        );
        """)

        try database.execute("""
        CREATE INDEX IF NOT EXISTS idx_relation_types_group_id ON relation_types(group_id);
        """)

        try database.execute("""
        CREATE TABLE IF NOT EXISTS relations (
            id TEXT PRIMARY KEY,
            group_id TEXT NOT NULL,
            from_person_id TEXT NOT NULL,
            to_person_id TEXT NOT NULL,
            relation_type_id TEXT NOT NULL,
            attributes_json TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            FOREIGN KEY(group_id) REFERENCES groups(id) ON DELETE CASCADE,
            FOREIGN KEY(from_person_id) REFERENCES people(id) ON DELETE CASCADE,
            FOREIGN KEY(to_person_id) REFERENCES people(id) ON DELETE CASCADE,
            FOREIGN KEY(relation_type_id) REFERENCES relation_types(id)
        );
        """)

        try database.execute("""
        CREATE INDEX IF NOT EXISTS idx_relations_group_id ON relations(group_id);
        """)

        try database.execute("""
        CREATE INDEX IF NOT EXISTS idx_relations_from_to ON relations(from_person_id, to_person_id);
        """)

        try database.execute("""
        CREATE TABLE IF NOT EXISTS graph_layouts (
            group_id TEXT PRIMARY KEY,
            version INTEGER NOT NULL,
            node_positions_json TEXT NOT NULL,
            updated_at INTEGER NOT NULL,
            FOREIGN KEY(group_id) REFERENCES groups(id) ON DELETE CASCADE
        );
        """)
    }
}
