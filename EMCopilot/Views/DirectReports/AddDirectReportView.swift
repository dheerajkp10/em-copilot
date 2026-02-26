import SwiftUI
import SwiftData

struct AddDirectReportView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var ctx

    @State private var name = ""
    @State private var role = ""
    @State private var level = ""
    @State private var team = ""
    @State private var startDate = Date()
    @State private var notes = ""

    private var canSave: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        NavigationStack {
            Form {
                Section("Identity") {
                    TextField("Full Name *", text: $name)
                    TextField("Role (e.g. Senior Engineer)", text: $role)
                    TextField("Level (e.g. L5, SDE2, Senior)", text: $level)
                    TextField("Team", text: $team)
                }

                Section {
                    DatePicker("Start Date", selection: $startDate, displayedComponents: .date)
                } header: {
                    Text("Reporting Relationship")
                }

                Section {
                    TextEditor(text: $notes)
                        .frame(minHeight: 80)
                } header: {
                    Text("Initial Notes (optional)")
                } footer: {
                    Text("Add any context about this person's background, ongoing projects, or goals. You can update this anytime.")
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Add Direct Report")
            .navigationTitleInline()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(!canSave)
                }
            }
        }
    }

    private func save() {
        let report = DirectReport(
            name: name.trimmingCharacters(in: .whitespaces),
            role: role.trimmingCharacters(in: .whitespaces),
            level: level.trimmingCharacters(in: .whitespaces),
            team: team.trimmingCharacters(in: .whitespaces),
            startDate: startDate,
            notes: notes.trimmingCharacters(in: .whitespaces)
        )
        ctx.insert(report)
        dismiss()
    }
}
