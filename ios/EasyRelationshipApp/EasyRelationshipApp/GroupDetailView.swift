import SwiftUI
import EasyRelationshipCore

struct GroupDetailView: View {
    let group: EasyRelationshipCore.Group
    let appStore: AppStore

    @State private var isGeneratingStressData: Bool = false
    @State private var isPresentingGenerateConfirm: Bool = false
    @State private var lastMessage: String = ""

    var body: some View {
        List {
            Section("入口") {
                NavigationLink("个体") {
                    EntityListView(store: appStore.makeEntitiesStore(groupId: group.id))
                }

                NavigationLink("关系图") {
                    GraphView(store: appStore.makeGraphStore(groupId: group.id))
                }

                NavigationLink("属性模板") {
                    AttributeDefinitionsView(store: appStore.makeAttributeDefinitionsStore(groupId: group.id))
                }

                NavigationLink("关系类型") {
                    RelationTypesView(store: appStore.makeRelationTypesStore(groupId: group.id))
                }

                NavigationLink("关系") {
                    RelationsView(store: appStore.makeRelationsStore(groupId: group.id))
                }
            }

            Section("测试") {
                Button(isGeneratingStressData ? "生成中..." : "生成 100 个体测试数据") {
                    isPresentingGenerateConfirm = true
                }
                .disabled(isGeneratingStressData)

                if !lastMessage.isEmpty {
                    Text(lastMessage)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }
        }
        .navigationTitle(group.name)
        .confirmationDialog(
            "生成测试数据？",
            isPresented: $isPresentingGenerateConfirm,
            titleVisibility: .visible
        ) {
            Button("生成", role: .destructive) {
                runGenerateStressData()
            }
            Button("取消", role: .cancel) {}
        } message: {
            Text("会在当前群体中追加 100 个个体与多条关系，建议只用于性能测试。")
        }
    }

    private func runGenerateStressData() {
        isGeneratingStressData = true
        lastMessage = ""
        Task {
            appStore.generateStressData(groupId: group.id, entityCount: 100)
            isGeneratingStressData = false
            if appStore.lastErrorMessage.isEmpty {
                lastMessage = "已生成 100 个体测试数据"
            } else {
                lastMessage = "生成失败：\(appStore.lastErrorMessage)"
            }
        }
    }
}
