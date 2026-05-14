import Foundation
import EasyRelationshipCore

@MainActor
final class PeopleStore: ObservableObject {
    @Published private(set) var people: [EasyRelationshipCore.Person] = []
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
                people = try store.people.list(groupId: groupId)
            } else {
                people = try store.people.search(groupId: groupId, nameQuery: query)
            }
        } catch {
            lastErrorMessage = String(describing: error)
        }
    }

    func createPerson(name: String, attributes: [String: String]) {
        do {
            _ = try store.people.create(groupId: groupId, name: name, attributes: attributes)
            reload()
        } catch {
            lastErrorMessage = String(describing: error)
        }
    }

    func updatePerson(personId: String, name: String, attributes: [String: String]) {
        do {
            try store.people.update(personId: personId, name: name, attributes: attributes)
            reload()
        } catch {
            lastErrorMessage = String(describing: error)
        }
    }

    func deletePerson(personId: String) {
        do {
            try store.people.delete(personId: personId)
            reload()
        } catch {
            lastErrorMessage = String(describing: error)
        }
    }

    func personById(_ id: String) -> EasyRelationshipCore.Person? {
        people.first(where: { $0.id == id })
    }
}
