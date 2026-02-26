import SwiftUI

/// Sheet for manually linking a contribution artifact (PR, design doc, incident, etc.)
/// to a 1:1 session or a direct report's contribution log.
struct AddArtifactView: View {
    @Environment(\.dismiss) private var dismiss

    var onAdd: (ContributionArtifact) -> Void

    @State private var title = ""
    @State private var artifactType: ArtifactType = .codeReview
    @State private var url = ""
    @State private var notes = ""
    @State private var artifactDate = Date()

    private var isValid: Bool {
        !title.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Details") {
                    TextField("Title (e.g. \"Migrate payments service to async\")", text: $title)

                    Picker("Type", selection: $artifactType) {
                        ForEach(ArtifactType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon).tag(type)
                        }
                    }

                    DatePicker("Date of Work", selection: $artifactDate, displayedComponents: .date)
                }

                Section {
                    TextField("URL (GitHub PR, Confluence doc, JIRA ticket…)", text: $url)
                        #if os(iOS)
                        .textInputAutocapitalization(.never)
                        .keyboardType(.URL)
                        #endif
                        .autocorrectionDisabled()
                } header: {
                    Text("Link")
                } footer: {
                    Text("Optional — paste a direct URL to the artifact for quick reference.")
                        .font(.caption)
                }

                Section {
                    ZStack(alignment: .topLeading) {
                        if notes.isEmpty {
                            Text("Add context: what was the impact? Any blockers overcome?")
                                .foregroundStyle(.tertiary)
                                .font(.callout)
                                .padding(.top, 8)
                                .padding(.leading, 4)
                                .allowsHitTesting(false)
                        }
                        TextEditor(text: $notes)
                            .frame(minHeight: 80)
                            .font(.callout)
                    }
                } header: {
                    Text("Notes")
                } footer: {
                    Text("These notes are included as context when generating 1:1 summaries.")
                        .font(.caption)
                }
            }
            .navigationTitle("Link Contribution")
            .navigationTitleInline()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let artifact = ContributionArtifact(
                            title: title.trimmingCharacters(in: .whitespaces),
                            artifactType: artifactType,
                            url: url.trimmingCharacters(in: .whitespaces),
                            notes: notes.trimmingCharacters(in: .whitespaces),
                            artifactDate: artifactDate
                        )
                        onAdd(artifact)
                        dismiss()
                    }
                    .disabled(!isValid)
                    .fontWeight(.semibold)
                }
            }
        }
        #if os(macOS)
        .frame(minWidth: 460, idealWidth: 500, minHeight: 420, idealHeight: 480)
        #endif
    }
}
