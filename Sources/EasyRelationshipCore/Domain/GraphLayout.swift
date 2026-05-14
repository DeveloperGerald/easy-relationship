import Foundation

public struct GraphPoint: Sendable, Equatable, Codable {
    public var x: Double
    public var y: Double

    public init(x: Double, y: Double) {
        self.x = x
        self.y = y
    }
}

public struct GraphLayout: Sendable, Equatable {
    public var groupId: String
    public var version: Int
    public var nodePositions: [String: GraphPoint]
    public var lockedNodeIds: Set<String>
    public var updatedAt: Date

    public init(
        groupId: String,
        version: Int,
        nodePositions: [String: GraphPoint],
        lockedNodeIds: Set<String>,
        updatedAt: Date
    ) {
        self.groupId = groupId
        self.version = version
        self.nodePositions = nodePositions
        self.lockedNodeIds = lockedNodeIds
        self.updatedAt = updatedAt
    }
}

