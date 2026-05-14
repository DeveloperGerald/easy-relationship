import SwiftUI
import EasyRelationshipCore

struct PeopleListView: View {
    @StateObject private var store: PeopleStore

    @State private var isPresentingCreate: Bool = false
    @State private var editTarget: EasyRelationshipCore.Person? = nil
    @State private var deleteTarget: EasyRelationshipCore.Person? = nil

    init(store: PeopleStore) {
        self._store = StateObject(wrappedValue: store)
    }

    var body: some View {
        List {
            if !store.lastErrorMessage.isEmpty {
                Section {
                    Text("加载失败：\(store.lastErrorMessage)")
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }

            if store.people.isEmpty {
                Section {
                    Text(store.query.isEmpty ? "暂无人物" : "无匹配结果")
                        .foregroundStyle(.secondary)
                }
            } else {
                Section {
                    ForEach(store.people) { person in
                        NavigationLink {
                            PersonDetailView(store: store, personId: person.id)
                        } label: {
                            Text(person.name)
                        }
                        .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                            Button(role: .destructive) {
                                deleteTarget = person
                            } label: {
                                Text("删除")
                            }

                            Button {
                                editTarget = person
                            } label: {
                                Text("编辑")
                            }
                            .tint(.blue)
                        }
                    }
                    .onDelete { indexSet in
                        for index in indexSet {
                            deleteTarget = store.people[index]
                        }
                    }
                }
            }
        }
        .navigationTitle("人物")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    isPresentingCreate = true
                } label: {
                    Image(systemName: "plus")
                }
            }
        }
        .searchable(text: $store.query, placement: .navigationBarDrawer(displayMode: .always), prompt: "搜索姓名")
        .onChange(of: store.query) { _, _ in
            store.reload()
        }
        .onAppear {
            store.reload()
        }
        .sheet(isPresented: $isPresentingCreate) {
            PersonEditorSheet(
                mode: .create,
                attributeDefinitions: store.attributeDefinitions
            ) { name, attributes in
                store.createPerson(name: name, attributes: attributes)
            }
        }
        .sheet(item: $editTarget) { person in
            PersonEditorSheet(
                mode: .edit(personId: person.id),
                attributeDefinitions: store.attributeDefinitions,
                initialName: person.name,
                initialAttributes: person.attributes
            ) { name, attributes in
                store.updatePerson(personId: person.id, name: name, attributes: attributes)
            }
        }
        .confirmationDialog(
            "删除人物？",
            isPresented: Binding(
                get: { deleteTarget != nil },
                set: { if !$0 { deleteTarget = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("删除", role: .destructive) {
                if let person = deleteTarget {
                    store.deletePerson(personId: person.id)
                }
                deleteTarget = nil
            }

            Button("取消", role: .cancel) {
                deleteTarget = nil
            }
        } message: {
            Text("删除后，与该人物相关的关系也会被删除。")
        }
    }
}
