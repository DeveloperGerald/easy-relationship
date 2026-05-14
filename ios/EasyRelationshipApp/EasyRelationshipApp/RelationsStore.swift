import Foundation
import EasyRelationshipCore

struct RelationListItem: Identifiable, Equatable {
    var id: String
    var fromId: String
    var toId: String
    var relationTypeId: String
    var fromName: String
    var toName: String
    var relationTypeName: String
}

@MainActor
final class RelationsStore: ObservableObject {
    @Published private(set) var entities: [EasyRelationshipCore.Entity] = []
    @Published private(set) var relationTypes: [EasyRelationshipCore.RelationType] = []
    @Published private(set) var relations: [EasyRelationshipCore.Relation] = []
    @Published private(set) var items: [RelationListItem] = []
    @Published private(set) var lastErrorMessage: String = ""

    private let store: LocalStore
    private let groupId: String

    init(store: LocalStore, groupId: String) {
        self.store = store
        self.groupId = groupId
    }

    func reload() {
        do {
            entities = try store.entities.list(groupId: groupId)
            relationTypes = try store.relationTypes.list(groupId: groupId)
            relations = try store.relations.list(groupId: groupId)

            let entitiesById = Dictionary(uniqueKeysWithValues: entities.map { ($0.id, $0) })
            let typeById = Dictionary(uniqueKeysWithValues: relationTypes.map { ($0.id, $0) })

            items = relations.map { relation in
                let fromName = entitiesById[relation.fromEntityId]?.name ?? "(未知)"
                let toName = entitiesById[relation.toEntityId]?.name ?? "(未知)"
                let typeName = typeById[relation.relationTypeId]?.name ?? "(未知类型)"
                return RelationListItem(
                    id: relation.id,
                    fromId: relation.fromEntityId,
                    toId: relation.toEntityId,
                    relationTypeId: relation.relationTypeId,
                    fromName: fromName,
                    toName: toName,
                    relationTypeName: typeName
                )
            }
        } catch {
            lastErrorMessage = String(describing: error)
        }
    }

    func create(fromEntityId: String, toEntityId: String, relationTypeId: String) {
        do {
            _ = try store.relations.create(
                groupId: groupId,
                fromEntityId: fromEntityId,
                toEntityId: toEntityId,
                relationTypeId: relationTypeId
            )
            reload()
        } catch {
            lastErrorMessage = String(describing: error)
        }
    }

    func delete(relationId: String) {
        do {
            try store.relations.delete(relationId: relationId)
            reload()
        } catch {
            lastErrorMessage = String(describing: error)
        }
    }

    func update(relationId: String, fromEntityId: String, toEntityId: String, relationTypeId: String) {
        do {
            try store.relations.update(
                relationId: relationId,
                groupId: groupId,
                fromEntityId: fromEntityId,
                toEntityId: toEntityId,
                relationTypeId: relationTypeId
            )
            reload()
        } catch {
            lastErrorMessage = String(describing: error)
        }
    }
}
