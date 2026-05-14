import Foundation

public final class LocalStore: @unchecked Sendable {
    public let database: SQLiteDatabase
    public let groups: GroupRepository
    public let entities: EntityRepository
    public let relationTypes: RelationTypeRepository
    public let relations: RelationRepository
    public let attributeDefinitions: AttributeDefinitionRepository
    public let exports: ExportService
    public let graphLayouts: GraphLayoutRepository

    public init(fileURL: URL) throws {
        let database = try SQLiteDatabase(fileURL: fileURL)
        try SchemaMigrator().migrate(database)

        self.database = database
        self.groups = GroupRepository(database: database)
        self.entities = EntityRepository(database: database)
        self.relationTypes = RelationTypeRepository(database: database)
        self.relations = RelationRepository(database: database)
        self.attributeDefinitions = AttributeDefinitionRepository(database: database)
        self.exports = ExportService(database: database)
        self.graphLayouts = GraphLayoutRepository(database: database)
    }
}
