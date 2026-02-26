import SwiftUI

struct GeneratedDocumentOutputView: View {
    @Environment(\.dismiss) private var dismiss

    let content: String
    let type: DocumentType
    let reportName: String
    let onSave: (String) -> Void

    @State private var title: String = ""
    @State private var showingSaveSheet = false
    @State private var isCopied = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    // Header banner
                    HStack {
                        Image(systemName: type.icon)
                            .font(.title2)
                        VStack(alignment: .leading) {
                            Text(type.rawValue)
                                .fontWeight(.semibold)
                            if !reportName.isEmpty {
                                Text(reportName)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        Spacer()
                        Text(Date().formatted(date: .abbreviated, time: .omitted))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(.quaternary)

                    Divider()

                    // Generated content (rendered as plain text for now)
                    Text(content)
                        .font(.system(.callout, design: .default))
                        .textSelection(.enabled)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
            }
            .navigationTitle("Generated Document")
            .navigationTitleInline()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Back") { dismiss() }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button {
                        copyToClipboard()
                    } label: {
                        Label(
                            isCopied ? "Copied!" : "Copy",
                            systemImage: isCopied ? "checkmark.circle.fill" : "doc.on.doc"
                        )
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button("Save") {
                        title = "\(type.rawValue)\(reportName.isEmpty ? "" : " – \(reportName)") – \(Date().formatted(date: .abbreviated, time: .omitted))"
                        showingSaveSheet = true
                    }
                    .fontWeight(.semibold)
                }
            }
            .alert("Save Document", isPresented: $showingSaveSheet) {
                TextField("Document title", text: $title)
                Button("Save") { onSave(title); dismiss() }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Give this document a title to save it.")
            }
        }
    }

    private func copyToClipboard() {
        #if os(macOS)
        NSPasteboard.general.clearContents()
        NSPasteboard.general.setString(content, forType: .string)
        #else
        UIPasteboard.general.string = content
        #endif
        isCopied = true
        Task {
            try? await Task.sleep(for: .seconds(2))
            isCopied = false
        }
    }
}
