import Foundation
import SwiftUI
import EasyRelationshipCore

struct GraphNode: Identifiable, Equatable {
    var id: String
    var name: String
}

struct GraphEdge: Identifiable, Equatable {
    var id: String
    var fromId: String
    var toId: String
    var relationTypeId: String
    var label: String
    var directional: Bool
}

@MainActor
final class GraphStore: ObservableObject {
    @Published private(set) var nodes: [GraphNode] = []
    @Published private(set) var edges: [GraphEdge] = []
    @Published private(set) var positions: [String: CGPoint] = [:]
    @Published private(set) var lockedNodeIds: Set<String> = []
    @Published var selectedNodeId: String? = nil
    @Published var query: String = ""
    @Published private(set) var lastErrorMessage: String = ""

    private let store: LocalStore
    private let groupId: String
    private var entitiesById: [String: EasyRelationshipCore.Entity] = [:]
    private var adjacency: [String: Set<String>] = [:]

    init(store: LocalStore, groupId: String) {
        self.store = store
        self.groupId = groupId
    }

    func reload() {
        do {
            let entities = try store.entities.list(groupId: groupId)
            let relationTypes = try store.relationTypes.list(groupId: groupId)
            let relations = try store.relations.list(groupId: groupId)

            let savedLayout = try store.graphLayouts.load(groupId: groupId)

            entitiesById = Dictionary(uniqueKeysWithValues: entities.map { ($0.id, $0) })
            let relationTypeById = Dictionary(uniqueKeysWithValues: relationTypes.map { ($0.id, $0) })

            nodes = entities
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }
                .map { GraphNode(id: $0.id, name: $0.name) }

            edges = relations.map { relation in
                let type = relationTypeById[relation.relationTypeId]
                return GraphEdge(
                    id: relation.id,
                    fromId: relation.fromEntityId,
                    toId: relation.toEntityId,
                    relationTypeId: relation.relationTypeId,
                    label: type?.name ?? "(未知类型)",
                    directional: type?.directional ?? false
                )
            }

            rebuildAdjacency()

            if let savedLayout {
                lockedNodeIds = savedLayout.lockedNodeIds
            } else {
                lockedNodeIds = []
            }

            computeLayout(rootId: selectedNodeId)

            if let savedLayout {
                var merged = positions
                for (nodeId, point) in savedLayout.nodePositions {
                    merged[nodeId] = CGPoint(x: point.x, y: point.y)
                }
                positions = merged
            }
        } catch {
            lastErrorMessage = String(describing: error)
        }
    }

    func recomputeLayout() {
        computeLayout(rootId: selectedNodeId)
        persistLayout()
    }

    func persistLayout() {
        do {
            var stored: [String: GraphPoint] = [:]
            for (nodeId, point) in positions {
                stored[nodeId] = GraphPoint(x: Double(point.x), y: Double(point.y))
            }
            let layout = GraphLayout(
                groupId: groupId,
                version: 1,
                nodePositions: stored,
                lockedNodeIds: lockedNodeIds,
                updatedAt: Date()
            )
            try store.graphLayouts.save(layout)
        } catch {
            lastErrorMessage = String(describing: error)
        }
    }

    func selectNearestNode(worldPoint: CGPoint, maxDistance: CGFloat) {
        if let bestId = nearestNodeId(worldPoint: worldPoint, maxDistance: maxDistance) {
            selectedNodeId = bestId
        }
    }

    func nearestNodeId(worldPoint: CGPoint, maxDistance: CGFloat) -> String? {
        var bestId: String? = nil
        var bestDistance: CGFloat = .greatestFiniteMagnitude
        for node in nodes {
            guard let p = positions[node.id] else { continue }
            let d = hypot(p.x - worldPoint.x, p.y - worldPoint.y)
            if d < bestDistance {
                bestDistance = d
                bestId = node.id
            }
        }
        guard let bestId, bestDistance <= maxDistance else {
            return nil
        }
        return bestId
    }

    func updateNodePosition(nodeId: String, worldPosition: CGPoint) {
        positions[nodeId] = worldPosition
        lockedNodeIds.insert(nodeId)
    }

    func isLocked(nodeId: String) -> Bool {
        lockedNodeIds.contains(nodeId)
    }

    func toggleLock(nodeId: String) {
        if lockedNodeIds.contains(nodeId) {
            lockedNodeIds.remove(nodeId)
        } else {
            lockedNodeIds.insert(nodeId)
        }

        persistLayout()
    }

    func highlightedNodeIds() -> Set<String> {
        guard let selectedNodeId else { return [] }
        var result: Set<String> = [selectedNodeId]
        if let neighbors = adjacency[selectedNodeId] {
            result.formUnion(neighbors)
        }
        return result
    }

    func highlightedEdgeIds() -> Set<String> {
        guard let selectedNodeId else { return [] }
        var result = Set<String>()
        for edge in edges {
            if edge.fromId == selectedNodeId || edge.toId == selectedNodeId {
                result.insert(edge.id)
            }
        }
        return result
    }

    func suggestions(limit: Int = 10) -> [GraphNode] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return [] }
        return nodes
            .filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
            .prefix(limit)
            .map { $0 }
    }

    func focusFirstMatch() {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        if let match = nodes.first(where: { $0.name.localizedCaseInsensitiveCompare(trimmed) == .orderedSame }) {
            selectedNodeId = match.id
            computeLayout(rootId: match.id)
            return
        }
        if let match = nodes.first(where: { $0.name.localizedCaseInsensitiveContains(trimmed) }) {
            selectedNodeId = match.id
            computeLayout(rootId: match.id)
        }
    }

    private func rebuildAdjacency() {
        var map: [String: Set<String>] = [:]
        for node in nodes {
            map[node.id] = []
        }
        for edge in edges {
            map[edge.fromId, default: []].insert(edge.toId)
            map[edge.toId, default: []].insert(edge.fromId)
        }
        adjacency = map
    }

    private func computeLayout(rootId: String?) {
        let oldPositions = positions
        let root = rootId ?? pickDefaultRootId()
        let levels = bfsLevels(rootId: root)

        let levelGroups = Dictionary(grouping: nodes) { node in
            levels[node.id] ?? Int.max
        }

        let sortedLevels = levelGroups.keys.sorted()
        var newPositions: [String: CGPoint] = [:]

        let xSpacing: CGFloat = 220
        let ySpacing: CGFloat = 90

        for (levelIndex, level) in sortedLevels.enumerated() {
            let groupNodes = (levelGroups[level] ?? [])
                .sorted { $0.name.localizedCaseInsensitiveCompare($1.name) == .orderedAscending }

            let totalHeight = CGFloat(max(groupNodes.count - 1, 0)) * ySpacing
            for (i, node) in groupNodes.enumerated() {
                let x = CGFloat(levelIndex) * xSpacing
                let y = CGFloat(i) * ySpacing - totalHeight / 2
                newPositions[node.id] = CGPoint(x: x, y: y)
            }
        }

        for lockedId in lockedNodeIds {
            if let p = oldPositions[lockedId] {
                newPositions[lockedId] = p
            }
        }

        positions = newPositions
    }

    private func bfsLevels(rootId: String?) -> [String: Int] {
        guard let rootId else {
            return [:]
        }
        var levels: [String: Int] = [rootId: 0]
        var queue: [String] = [rootId]
        var index = 0
        while index < queue.count {
            let current = queue[index]
            index += 1
            let currentLevel = levels[current] ?? 0
            for next in adjacency[current] ?? [] {
                if levels[next] == nil {
                    levels[next] = currentLevel + 1
                    queue.append(next)
                }
            }
        }
        return levels
    }

    private func pickDefaultRootId() -> String? {
        var bestId: String? = nil
        var bestDegree: Int = -1
        for node in nodes {
            let degree = adjacency[node.id]?.count ?? 0
            if degree > bestDegree {
                bestDegree = degree
                bestId = node.id
            }
        }
        return bestId ?? nodes.first?.id
    }
}
