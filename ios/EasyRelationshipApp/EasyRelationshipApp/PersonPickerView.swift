import SwiftUI
import EasyRelationshipCore

struct PersonPickerView: View {
    let title: String
    let people: [EasyRelationshipCore.Person]
    let onPick: (EasyRelationshipCore.Person) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var query: String = ""

    var body: some View {
        List {
            ForEach(filteredPeople) { person in
                Button {
                    onPick(person)
                    dismiss()
                } label: {
                    Text(person.name)
                }
            }
        }
        .navigationTitle(title)
        .searchable(text: $query, placement: .navigationBarDrawer(displayMode: .always), prompt: "搜索姓名")
    }

    private var filteredPeople: [EasyRelationshipCore.Person] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return people }
        return people.filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
    }
}

