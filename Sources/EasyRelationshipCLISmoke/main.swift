import Foundation
import EasyRelationshipCore

let dbURL = URL(fileURLWithPath: NSTemporaryDirectory())
    .appendingPathComponent("easyrelationship-smoke.sqlite")

do {
    try? FileManager.default.removeItem(at: dbURL)
    let store = try LocalStore(fileURL: dbURL)

    let group = try store.groups.create(name: "Demo")
    _ = try store.attributeDefinitions.upsert(
        groupId: group.id,
        key: "role",
        label: "角色",
        type: .singleSelect,
        required: false,
        options: ["老板", "员工"],
        sortOrder: 0
    )

    let alice = try store.entities.create(groupId: group.id, name: "Alice", attributes: ["role": "老板"])
    let bob = try store.entities.create(groupId: group.id, name: "Bob", attributes: ["role": "员工"])
    let type = try store.relationTypes.create(groupId: group.id, name: "同事", directional: false)
    _ = try store.relations.create(groupId: group.id, fromEntityId: alice.id, toEntityId: bob.id, relationTypeId: type.id)

    let exported = try store.exports.exportGroupJSON(groupId: group.id)
    let json = String(decoding: exported, as: UTF8.self)
    print(json)
} catch {
    fputs("Smoke test failed: \(error)\n", stderr)
    exit(1)
}

