import Foundation

public struct Group: Sendable, Equatable, Identifiable {
    public var id: String
    public var name: String
    public var createdAt: Date
    public var updatedAt: Date

    public init(id: String, name: String, createdAt: Date, updatedAt: Date) {
        self.id = id
        self.name = name
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct Entity: Sendable, Equatable, Identifiable {
    public var id: String
    public var groupId: String
    public var name: String
    public var attributes: [String: String]
    public var createdAt: Date
    public var updatedAt: Date

    public init(
        id: String,
        groupId: String,
        name: String,
        attributes: [String: String],
        createdAt: Date,
        updatedAt: Date
    ) {
        self.id = id
        self.groupId = groupId
        self.name = name
        self.attributes = attributes
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public enum AttributeValueType: String, Sendable, Equatable, CaseIterable {
    case text
    case number
    case date
    case singleSelect
}

public struct AttributeDefinition: Sendable, Equatable, Identifiable {
    public var id: String
    public var groupId: String
    public var key: String
    public var label: String
    public var type: AttributeValueType
    public var required: Bool
    public var options: [String]
    public var sortOrder: Int

    public init(
        id: String,
        groupId: String,
        key: String,
        label: String,
        type: AttributeValueType,
        required: Bool,
        options: [String],
        sortOrder: Int
    ) {
        self.id = id
        self.groupId = groupId
        self.key = key
        self.label = label
        self.type = type
        self.required = required
        self.options = options
        self.sortOrder = sortOrder
    }
}

public struct RelationType: Sendable, Equatable, Identifiable {
    public var id: String
    public var groupId: String
    public var name: String
    public var directional: Bool
    public var style: [String: String]

    public init(id: String, groupId: String, name: String, directional: Bool, style: [String: String]) {
        self.id = id
        self.groupId = groupId
        self.name = name
        self.directional = directional
        self.style = style
    }
}

public struct Relation: Sendable, Equatable, Identifiable {
    public var id: String
    public var groupId: String
    public var fromEntityId: String
    public var toEntityId: String
    public var relationTypeId: String
    public var attributes: [String: String]
    public var createdAt: Date

    public init(
        id: String,
        groupId: String,
        fromEntityId: String,
        toEntityId: String,
        relationTypeId: String,
        attributes: [String: String],
        createdAt: Date
    ) {
        self.id = id
        self.groupId = groupId
        self.fromEntityId = fromEntityId
        self.toEntityId = toEntityId
        self.relationTypeId = relationTypeId
        self.attributes = attributes
        self.createdAt = createdAt
    }
}

