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
            try setSchemaVersion(database, version: 2) // 直接跳到 2
        } else if currentVersion < 2 {
            try migrateToV2(database)
            try setSchemaVersion(database, version: 2)
        }
    }

    private func migrateToV2(_ database: SQLiteDatabase) throws {
        // 1. 重命名 people 表为 entities
        try database.execute("ALTER TABLE people RENAME TO entities;")
        
        // 2. 更新 relations 表
        // SQLite 3.25.0+ 支持 RENAME COLUMN
        // 如果不支持，则需要创建新表并迁移数据
        // iOS 13+ (SQLite 3.26+) 支持此语法
        try database.execute("ALTER TABLE relations RENAME COLUMN from_person_id TO from_entity_id;")
        try database.execute("ALTER TABLE relations RENAME COLUMN to_person_id TO to_entity_id;")

        // 3. 更新索引 (SQLite 中 RENAME TABLE 会自动处理关联的索引吗？通常是的，但为了保险可以手动处理)
        // 实际上 SQLite 的 RENAME TABLE 会自动处理外键引用和索引。
        // 但我们之前定义的索引名包含 'people'，最好也更新一下索引名。
        try database.execute("DROP INDEX IF EXISTS idx_people_group_id;")
        try database.execute("CREATE INDEX IF NOT EXISTS idx_entities_group_id ON entities(group_id);")
        
        try database.execute("DROP INDEX IF EXISTS idx_relations_from_to;")
        try database.execute("CREATE INDEX IF NOT EXISTS idx_relations_from_to ON relations(from_entity_id, to_entity_id);")
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
        CREATE TABLE IF NOT EXISTS entities (
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
        CREATE INDEX IF NOT EXISTS idx_entities_group_id ON entities(group_id);
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
            from_entity_id TEXT NOT NULL,
            to_entity_id TEXT NOT NULL,
            relation_type_id TEXT NOT NULL,
            attributes_json TEXT NOT NULL,
            created_at INTEGER NOT NULL,
            FOREIGN KEY(group_id) REFERENCES groups(id) ON DELETE CASCADE,
            FOREIGN KEY(from_entity_id) REFERENCES entities(id) ON DELETE CASCADE,
            FOREIGN KEY(to_entity_id) REFERENCES entities(id) ON DELETE CASCADE,
            FOREIGN KEY(relation_type_id) REFERENCES relation_types(id)
        );
        """)

        try database.execute("""
        CREATE INDEX IF NOT EXISTS idx_relations_group_id ON relations(group_id);
        """)

        try database.execute("""
        CREATE INDEX IF NOT EXISTS idx_relations_from_to ON relations(from_entity_id, to_entity_id);
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
