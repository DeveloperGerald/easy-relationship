import SwiftUI
import EasyRelationshipCore

struct EntityPickerView: View {
    let title: String
    let entities: [EasyRelationshipCore.Entity]
    let onPick: (EasyRelationshipCore.Entity) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var query: String = ""

    var body: some View {
        List {
            ForEach(filteredEntities) { entity in
                Button {
                    onPick(entity)
                    dismiss()
                } label: {
                    Text(entity.name)
                }
            }
        }
        .navigationTitle(title)
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "搜索姓名")
    }

    private var filteredEntities: [EasyRelationshipCore.Entity] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return entities }
        return entities.filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
    }
}

