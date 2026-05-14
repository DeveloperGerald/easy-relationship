# iOS App

本目录提供 iOS App 的工程骨架建议与后续落地方式。

由于当前环境未安装 Xcode，本仓库暂不生成可直接编译的 `.xcodeproj`。建议在有 Xcode 的机器上：

1. 新建一个 SwiftUI iOS App 工程（例如 `EasyRelationshipApp`）
2. 将本仓库作为 Swift Package 依赖引入（依赖产品：`EasyRelationshipCore`）
3. App 层优先把数据模型、存储与图谱引擎放在 Core 或独立模块，UI 只负责展示与交互

