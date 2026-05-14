import SwiftUI
import EasyRelationshipCore

struct RelationsView: View {
    @StateObject private var store: RelationsStore
    @State private var isPresentingCreate: Bool = false
    @State private var deleteTarget: RelationListItem? = nil
    @State private var editTarget: RelationListItem? = nil

    init(store: RelationsStore) {
        self._store = StateObject(wrappedValue: store)
    }

    var body: some View {
        List {
            if !store.lastErrorMessage.isEmpty {
                Section {
                    Text("操作失败：\(store.lastErrorMessage)")
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }

            if store.items.isEmpty {
                Section {
                    Text("暂无关系")
                        .foregroundStyle(.secondary)
                }
            } else {
                Section {
                    ForEach(store.items) { item in
                        Button {
                            editTarget = item
                        } label: {
                            HStack(spacing: 8) {
                                Text(item.fromName)
                                Text("—[")
                                    .foregroundStyle(.secondary)
                                Text(item.relationTypeName)
                                    .foregroundStyle(.secondary)
                                Text("]→")
                                    .foregroundStyle(.secondary)
                                Text(item.toName)
                                Spacer()
                            }
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                deleteTarget = item
                            } label: {
                                Text("删除")
                            }

                            Button {
                                editTarget = item
                            } label: {
                                Text("编辑")
                            }
                            .tint(.blue)
                        }
                    }
                }
            }
        }
        .navigationTitle("关系")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isPresentingCreate = true
                } label: {
                    Image(systemName: "plus")
                }
                .disabled(store.entities.isEmpty || store.relationTypes.isEmpty)
            }
        }
        .onAppear { store.reload() }
        .sheet(isPresented: $isPresentingCreate) {
            NewRelationSheet(entities: store.entities, relationTypes: store.relationTypes) { fromId, toId, typeId in
                store.create(fromEntityId: fromId, toEntityId: toId, relationTypeId: typeId)
            }
        }
        .sheet(item: $editTarget) { item in
            EditRelationSheet(
                entities: store.entities,
                relationTypes: store.relationTypes,
                initialFromId: item.fromId,
                initialToId: item.toId,
                initialRelationTypeId: item.relationTypeId
            ) { fromId, toId, typeId in
                store.update(relationId: item.id, fromEntityId: fromId, toEntityId: toId, relationTypeId: typeId)
            }
        }
        .confirmationDialog(
            "删除关系？",
            isPresented: Binding(
                get: { deleteTarget != nil },
                set: { if !$0 { deleteTarget = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("删除", role: .destructive) {
                if let item = deleteTarget {
                    store.delete(relationId: item.id)
                }
                deleteTarget = nil
            }

            Button("取消", role: .cancel) {
                deleteTarget = nil
            }
        }
    }
}
