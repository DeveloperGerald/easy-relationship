import Foundation
import EasyRelationshipCore

@MainActor
final class RelationTypesStore: ObservableObject {
    @Published private(set) var relationTypes: [EasyRelationshipCore.RelationType] = []
    @Published private(set) var lastErrorMessage: String = ""

    private let store: LocalStore
    private let groupId: String

    init(store: LocalStore, groupId: String) {
        self.store = store
        self.groupId = groupId
    }

    func reload() {
        do {
            relationTypes = try store.relationTypes.list(groupId: groupId)
        } catch {
            lastErrorMessage = String(describing: error)
        }
    }

    func create(name: String, directional: Bool) {
        do {
            _ = try store.relationTypes.create(groupId: groupId, name: name, directional: directional)
            reload()
        } catch {
            lastErrorMessage = String(describing: error)
        }
    }

    func update(id: String, name: String, directional: Bool) {
        do {
            try store.relationTypes.update(relationTypeId: id, name: name, directional: directional)
            reload()
        } catch {
            lastErrorMessage = String(describing: error)
        }
    }

    func delete(id: String) {
        do {
            try store.relationTypes.delete(relationTypeId: id)
            reload()
        } catch {
            lastErrorMessage = String(describing: error)
        }
    }
}

