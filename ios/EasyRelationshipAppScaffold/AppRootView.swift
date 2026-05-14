import SwiftUI
import EasyRelationshipCore

struct AppRootView: View {
    let environment: AppEnvironment

    var body: some View {
        NavigationStack {
            List {
                Section("群体") {
                    Text("群体列表（待实现）")
                }

                Section("占位") {
                    HStack {
                        Text("AI 生成")
                        Spacer()
                        Text(environment.featureFlags.isEnabled(.aiGraphGeneration) ? "开启" : "未开启")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("云同步")
                        Spacer()
                        Text(environment.featureFlags.isEnabled(.cloudSync) ? "开启" : "未开启")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle("EasyRelationship")
        }
    }
}

