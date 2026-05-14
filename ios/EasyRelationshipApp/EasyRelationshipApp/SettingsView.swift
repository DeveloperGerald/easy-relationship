import SwiftUI

enum SettingsKeys {
    static let enableAIGeneration = "settings.enableAIGeneration"
    static let enableCloudSync = "settings.enableCloudSync"
}

struct SettingsView: View {
    @AppStorage(SettingsKeys.enableAIGeneration) private var enableAIGeneration: Bool = false
    @AppStorage(SettingsKeys.enableCloudSync) private var enableCloudSync: Bool = false

    var body: some View {
        List {
            Section("功能开关（占位）") {
                Toggle("AI 生成（未接入）", isOn: $enableAIGeneration)
                Toggle("云同步（未接入）", isOn: $enableCloudSync)

                Text("以上开关仅用于预留入口展示，不会上传你的任何数据。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("数据与隐私") {
                Text("本应用默认仅在本机存储人物与关系数据，不会主动上传。")
                Text("如果未来启用 AI 或云同步，会在功能正式上线时单独提示并征得授权。")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }

            Section("关于") {
                HStack {
                    Text("版本")
                    Spacer()
                    Text(appVersionText)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .navigationTitle("设置")
    }

    private var appVersionText: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        if let version, let build {
            return "\(version) (\(build))"
        }
        return version ?? "—"
    }
}

