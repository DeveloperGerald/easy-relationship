import Foundation

public struct GraphDraft: Sendable, Equatable {
    public var entities: [DraftEntity]
    public var relations: [DraftRelation]

    public init(entities: [DraftEntity], relations: [DraftRelation]) {
        self.entities = entities
        self.relations = relations
    }
}

public struct DraftEntity: Sendable, Equatable {
    public var clientId: String
    public var name: String
    public var attributes: [String: String]

    public init(clientId: String, name: String, attributes: [String: String]) {
        self.clientId = clientId
        self.name = name
        self.attributes = attributes
    }
}

public struct DraftRelation: Sendable, Equatable {
    public var fromClientId: String
    public var toClientId: String
    public var relationType: String
    public var attributes: [String: String]

    public init(
        fromClientId: String,
        toClientId: String,
        relationType: String,
        attributes: [String: String]
    ) {
        self.fromClientId = fromClientId
        self.toClientId = toClientId
        self.relationType = relationType
        self.attributes = attributes
    }
}

public protocol GraphGenerationService: Sendable {
    func generateGraphDraft(prompt: String, groupId: String) async throws -> GraphDraft
}

public enum GraphGenerationError: Error, Sendable, Equatable {
    case disabled
}

public struct DisabledGraphGenerationService: GraphGenerationService {
    public init() {}

    public func generateGraphDraft(prompt: String, groupId: String) async throws -> GraphDraft {
        throw GraphGenerationError.disabled
    }
}

