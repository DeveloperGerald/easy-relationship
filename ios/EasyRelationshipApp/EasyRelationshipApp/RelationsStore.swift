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
    @Published private(set) var people: [EasyRelationshipCore.Person] = []
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
            people = try store.people.list(groupId: groupId)
            relationTypes = try store.relationTypes.list(groupId: groupId)
            relations = try store.relations.list(groupId: groupId)

            let peopleById = Dictionary(uniqueKeysWithValues: people.map { ($0.id, $0) })
            let typeById = Dictionary(uniqueKeysWithValues: relationTypes.map { ($0.id, $0) })

            items = relations.map { relation in
                let fromName = peopleById[relation.fromPersonId]?.name ?? "(未知)"
                let toName = peopleById[relation.toPersonId]?.name ?? "(未知)"
                let typeName = typeById[relation.relationTypeId]?.name ?? "(未知类型)"
                return RelationListItem(
                    id: relation.id,
                    fromId: relation.fromPersonId,
                    toId: relation.toPersonId,
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

    func create(fromPersonId: String, toPersonId: String, relationTypeId: String) {
        do {
            _ = try store.relations.create(
                groupId: groupId,
                fromPersonId: fromPersonId,
                toPersonId: toPersonId,
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

    func update(relationId: String, fromPersonId: String, toPersonId: String, relationTypeId: String) {
        do {
            try store.relations.update(
                relationId: relationId,
                groupId: groupId,
                fromPersonId: fromPersonId,
                toPersonId: toPersonId,
                relationTypeId: relationTypeId
            )
            reload()
        } catch {
            lastErrorMessage = String(describing: error)
        }
    }
}
