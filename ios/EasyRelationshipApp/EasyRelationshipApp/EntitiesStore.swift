import Foundation
import EasyRelationshipCore

@MainActor
final class EntitiesStore: ObservableObject {
    @Published private(set) var entities: [EasyRelationshipCore.Entity] = []
    @Published private(set) var attributeDefinitions: [EasyRelationshipCore.AttributeDefinition] = []
    @Published var query: String = ""
    @Published private(set) var lastErrorMessage: String = ""

    private let store: LocalStore
    private let groupId: String

    init(store: LocalStore, groupId: String) {
        self.store = store
        self.groupId = groupId
    }

    func reload() {
        do {
            attributeDefinitions = try store.attributeDefinitions.list(groupId: groupId)
            if query.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                entities = try store.entities.list(groupId: groupId)
            } else {
                entities = try store.entities.search(groupId: groupId, nameQuery: query)
            }
        } catch {
            lastErrorMessage = String(describing: error)
        }
    }

    func createEntity(name: String, attributes: [String: String]) {
        do {
            _ = try store.entities.create(groupId: groupId, name: name, attributes: attributes)
            reload()
        } catch {
            lastErrorMessage = String(describing: error)
        }
    }

    func updateEntity(entityId: String, name: String, attributes: [String: String]) {
        do {
            try store.entities.update(entityId: entityId, name: name, attributes: attributes)
            reload()
        } catch {
            lastErrorMessage = String(describing: error)
        }
    }

    func deleteEntity(entityId: String) {
        do {
            try store.entities.delete(entityId: entityId)
            reload()
        } catch {
            lastErrorMessage = String(describing: error)
        }
    }

    func entityById(_ id: String) -> EasyRelationshipCore.Entity? {
        entities.first(where: { $0.id == id })
    }
}
