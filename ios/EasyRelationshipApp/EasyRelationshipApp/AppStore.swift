import Foundation
import EasyRelationshipCore

@MainActor
final class AppStore: ObservableObject {
    @Published private(set) var groups: [EasyRelationshipCore.Group] = []
    @Published private(set) var lastErrorMessage: String = ""

    private let store: LocalStore

    init(databaseURL: URL) throws {
        self.store = try LocalStore(fileURL: databaseURL)
    }

    func makePeopleStore(groupId: String) -> PeopleStore {
        PeopleStore(store: store, groupId: groupId)
    }

    func makeAttributeDefinitionsStore(groupId: String) -> AttributeDefinitionsStore {
        AttributeDefinitionsStore(store: store, groupId: groupId)
    }

    func makeRelationTypesStore(groupId: String) -> RelationTypesStore {
        RelationTypesStore(store: store, groupId: groupId)
    }

    func makeRelationsStore(groupId: String) -> RelationsStore {
        RelationsStore(store: store, groupId: groupId)
    }

    func makeGraphStore(groupId: String) -> GraphStore {
        GraphStore(store: store, groupId: groupId)
    }

    static func make(databaseURL: URL) -> AppStore {
        do {
            return try AppStore(databaseURL: databaseURL)
        } catch {
            let fallbackURL = URL(fileURLWithPath: NSTemporaryDirectory())
                .appendingPathComponent("easyrelationship-fallback.sqlite")
            let store = (try? AppStore(databaseURL: fallbackURL)) ?? unsafeFallback()
            store.setErrorMessage(String(describing: error))
            return store
        }
    }

    func setErrorMessage(_ message: String) {
        lastErrorMessage = message
    }

    func reloadGroups() {
        do {
            groups = try store.groups.list()
        } catch {
            lastErrorMessage = String(describing: error)
        }
    }

    func createGroup(name: String) {
        do {
            _ = try store.groups.create(name: name)
            reloadGroups()
        } catch {
            lastErrorMessage = String(describing: error)
        }
    }

    func renameGroup(groupId: String, name: String) {
        do {
            try store.groups.updateName(groupId: groupId, name: name)
            reloadGroups()
        } catch {
            lastErrorMessage = String(describing: error)
        }
    }

    func deleteGroup(groupId: String) {
        do {
            try store.groups.delete(groupId: groupId)
            reloadGroups()
        } catch {
            lastErrorMessage = String(describing: error)
        }
    }

    func generateStressData(groupId: String, peopleCount: Int) {
        do {
            try store.database.inTransaction {
                let types = try store.relationTypes.list(groupId: groupId)
                let relationTypeId: String
                if let first = types.first {
                    relationTypeId = first.id
                } else {
                    relationTypeId = try store.relationTypes.create(groupId: groupId, name: "关联", directional: false).id
                }

                var peopleIds: [String] = []
                peopleIds.reserveCapacity(peopleCount)
                for i in 1...peopleCount {
                    let name = String(format: "P%03d", i)
                    let person = try store.people.create(groupId: groupId, name: name, attributes: [:])
                    peopleIds.append(person.id)
                }

                if peopleIds.count >= 2 {
                    for i in 0..<peopleIds.count {
                        let fromId = peopleIds[i]
                        let toId = peopleIds[(i + 1) % peopleIds.count]
                        _ = try store.relations.create(
                            groupId: groupId,
                            fromPersonId: fromId,
                            toPersonId: toId,
                            relationTypeId: relationTypeId
                        )
                    }

                    for i in 0..<peopleIds.count {
                        let fromId = peopleIds[i]
                        let toId = peopleIds[(i + 7) % peopleIds.count]
                        _ = try store.relations.create(
                            groupId: groupId,
                            fromPersonId: fromId,
                            toPersonId: toId,
                            relationTypeId: relationTypeId
                        )
                    }
                }
            }
        } catch {
            lastErrorMessage = String(describing: error)
        }
    }
}

@MainActor
private func unsafeFallback() -> AppStore {
    let url = URL(fileURLWithPath: NSTemporaryDirectory())
        .appendingPathComponent("easyrelationship-unsafe.sqlite")
    return try! AppStore(databaseURL: url)
}
