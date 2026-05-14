import Foundation
import EasyRelationshipCore

@MainActor
final class AttributeDefinitionsStore: ObservableObject {
    @Published private(set) var definitions: [EasyRelationshipCore.AttributeDefinition] = []
    @Published private(set) var lastErrorMessage: String = ""

    private let store: LocalStore
    private let groupId: String

    init(store: LocalStore, groupId: String) {
        self.store = store
        self.groupId = groupId
    }

    func reload() {
        do {
            definitions = try store.attributeDefinitions.list(groupId: groupId)
        } catch {
            lastErrorMessage = String(describing: error)
        }
    }

    func createDefinition(
        key: String,
        label: String,
        type: AttributeValueType,
        required: Bool,
        options: [String]
    ) {
        do {
            let nextSortOrder = (definitions.map { $0.sortOrder }.max() ?? -1) + 1
            _ = try store.attributeDefinitions.create(
                groupId: groupId,
                key: key,
                label: label,
                type: type,
                required: required,
                options: options,
                sortOrder: nextSortOrder
            )
            reload()
        } catch {
            lastErrorMessage = String(describing: error)
        }
    }

    func updateDefinition(
        id: String,
        key: String,
        label: String,
        type: AttributeValueType,
        required: Bool,
        options: [String],
        sortOrder: Int
    ) {
        do {
            try store.attributeDefinitions.update(
                attributeDefinitionId: id,
                groupId: groupId,
                key: key,
                label: label,
                type: type,
                required: required,
                options: options,
                sortOrder: sortOrder
            )
            reload()
        } catch {
            lastErrorMessage = String(describing: error)
        }
    }

    func deleteDefinition(id: String) {
        do {
            try store.attributeDefinitions.delete(attributeDefinitionId: id)
            reload()
        } catch {
            lastErrorMessage = String(describing: error)
        }
    }

    func move(from source: IndexSet, to destination: Int) {
        var reordered = definitions
        reordered.move(fromOffsets: source, toOffset: destination)
        for (index, definition) in reordered.enumerated() {
            if definition.sortOrder == index { continue }
            do {
                try store.attributeDefinitions.update(
                    attributeDefinitionId: definition.id,
                    groupId: groupId,
                    key: definition.key,
                    label: definition.label,
                    type: definition.type,
                    required: definition.required,
                    options: definition.options,
                    sortOrder: index
                )
            } catch {
                lastErrorMessage = String(describing: error)
                break
            }
        }
        reload()
    }
}

