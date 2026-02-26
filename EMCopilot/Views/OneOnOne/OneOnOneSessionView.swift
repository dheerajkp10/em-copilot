import SwiftUI
import SwiftData

/// Create or view a single 1:1 session.
/// Feeds the full context (past sessions, open action items, contributions) to Claude.
struct OneOnOneSessionView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var ctx

    let report: DirectReport
    var existingSession: OneOnOneSession? = nil

    // Session state
    @State private var date: Date
    @State private var rawNotes: String
    @State private var generatedSummary: String

    // New items being added in this session
    @State private var newActionItems: [DraftActionItem] = []
    @State private var newArtifacts: [ContributionArtifact] = []

    // Generation
    @State private var isGenerating = false
    @State private var generationError: String? = nil

    // UI
    @State private var showingAddArtifact = false
    @State private var showingAddAction = false
    @State private var activeTab: SessionTab = .notes

    enum SessionTab: String, CaseIterable {
        case notes        = "Notes"
        case actionItems  = "Action Items"
        case artifacts    = "Contributions"
        case summary      = "Summary"
    }

    struct DraftActionItem: Identifiable {
        let id = UUID()
        var title: String = ""
        var owner: String = ""
        var dueDate: Date? = nil
    }

    init(report: DirectReport, existingSession: OneOnOneSession? = nil) {
        self.report = report
        self.existingSession = existingSession
        _date            = State(initialValue: existingSession?.date ?? Date())
        _rawNotes        = State(initialValue: existingSession?.rawNotes ?? "")
        _generatedSummary = State(initialValue: existingSession?.generatedSummary ?? "")
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Date + person header
                HStack {
                    AvatarView(initials: report.initials, color: .purple, size: 36)
                    VStack(alignment: .leading, spacing: 2) {
                        Text(report.name).fontWeight(.semibold)
                        DatePicker("", selection: $date, displayedComponents: .date)
                            .labelsHidden()
                            .font(.caption)
                    }
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 10)
                .background(.quaternary.opacity(0.5))

                Divider()

                // Tab switcher
                Picker("", selection: $activeTab) {
                    ForEach(SessionTab.allCases, id: \.self) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
                .padding(.vertical, 10)

                Divider()

                // Tab content
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        switch activeTab {
                        case .notes:        notesTab
                        case .actionItems:  actionItemsTab
                        case .artifacts:    artifactsTab
                        case .summary:      summaryTab
                        }
                    }
                    .padding(16)
                }

                Divider()

                // Bottom toolbar
                HStack {
                    if activeTab == .notes {
                        Button {
                            Task { await generateSummary() }
                        } label: {
                            HStack {
                                if isGenerating {
                                    ProgressView().controlSize(.small)
                                    Text("Generating…")
                                } else {
                                    Image(systemName: "sparkles")
                                    Text("Generate Summary")
                                }
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(.indigo)
                        .disabled(isGenerating || rawNotes.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                    Spacer()
                    Button("Save") { saveSession() }
                        .buttonStyle(.borderedProminent)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
            }
            .navigationTitle("1:1 Session")
            .navigationTitleInline()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showingAddArtifact) {
                AddArtifactView { artifact in
                    newArtifacts.append(artifact)
                }
            }
        }
        .alert("Generation Error", isPresented: .constant(generationError != nil)) {
            Button("OK") { generationError = nil }
        } message: {
            Text(generationError ?? "")
        }
    }

    // MARK: - Notes tab

    private var notesTab: some View {
        VStack(alignment: .leading, spacing: 10) {
            Label("Meeting Notes", systemImage: "pencil").font(.headline)
            Text("Paste your raw notes — topics discussed, what they said, blockers, wins, anything.")
                .font(.caption).foregroundStyle(.secondary)

            TextEditor(text: $rawNotes)
                .frame(minHeight: 220)
                .font(.callout)
                .padding(8)
                .background(Color.secondary.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            if let error = generationError {
                Label(error, systemImage: "xmark.octagon").foregroundStyle(.red).font(.caption)
            }

            // Context preview (what gets sent to Claude)
            if !contextSummary.isEmpty {
                DisclosureGroup {
                    Text(contextSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .padding(.top, 4)
                } label: {
                    Label("Context being used by Claude", systemImage: "info.circle")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    // MARK: - Action Items tab

    private var actionItemsTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Action Items", systemImage: "checklist").font(.headline)
                Spacer()
                Button { newActionItems.append(DraftActionItem()) } label: {
                    Label("Add", systemImage: "plus.circle")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.indigo)
            }

            if newActionItems.isEmpty {
                Text("No action items yet. Add them manually or generate a summary — action items will be extracted automatically.")
                    .font(.caption).foregroundStyle(.secondary)
            }

            ForEach($newActionItems) { $item in
                VStack(alignment: .leading, spacing: 6) {
                    TextField("Action item description", text: $item.title)
                        .textFieldStyle(.roundedBorder)
                    HStack {
                        TextField("Owner (e.g. \(report.name), Manager)", text: $item.owner)
                            .textFieldStyle(.roundedBorder)
                        DatePicker("", selection: Binding(
                            get: { item.dueDate ?? Date() },
                            set: { item.dueDate = $0 }
                        ), displayedComponents: .date)
                        .labelsHidden()
                    }
                }
                .padding(10)
                .background(Color.secondary.opacity(0.06))
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            // Existing action items from this session (if editing)
            if let session = existingSession, !session.actionItems.isEmpty {
                Divider()
                Label("Previously captured", systemImage: "clock").font(.subheadline).foregroundStyle(.secondary)
                ForEach(session.actionItems) { item in
                    ActionItemRow(item: item)
                }
            }
        }
    }

    // MARK: - Artifacts tab

    private var artifactsTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Label("Contributions", systemImage: "link").font(.headline)
                Spacer()
                Button { showingAddArtifact = true } label: {
                    Label("Link", systemImage: "plus.circle")
                }
                .buttonStyle(.plain)
                .foregroundStyle(.indigo)
            }

            Text("Link PRs, design docs, incidents, or project updates contributed since the last 1:1.")
                .font(.caption).foregroundStyle(.secondary)

            if newArtifacts.isEmpty {
                Text("No contributions linked yet.")
                    .font(.caption).foregroundStyle(.tertiary)
            } else {
                ForEach(newArtifacts) { artifact in
                    ArtifactRowView(artifact: artifact)
                        .padding(10)
                        .background(Color.secondary.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }

            // Existing artifacts
            if let session = existingSession, !session.artifacts.isEmpty {
                Divider()
                Label("Previously linked", systemImage: "clock").font(.subheadline).foregroundStyle(.secondary)
                ForEach(session.artifacts) { ArtifactRowView(artifact: $0) }
            }
        }
    }

    // MARK: - Summary tab

    private var summaryTab: some View {
        VStack(alignment: .leading, spacing: 12) {
            if generatedSummary.isEmpty {
                ContentUnavailableView {
                    Label("No Summary Yet", systemImage: "sparkles")
                } description: {
                    Text("Go to the Notes tab and tap Generate Summary.")
                }
            } else {
                HStack {
                    Label("Generated Summary", systemImage: "sparkles").font(.headline)
                    Spacer()
                    Button {
                        #if os(macOS)
                        NSPasteboard.general.clearContents()
                        NSPasteboard.general.setString(generatedSummary, forType: .string)
                        #else
                        UIPasteboard.general.string = generatedSummary
                        #endif
                    } label: {
                        Label("Copy", systemImage: "doc.on.doc")
                    }
                    .buttonStyle(.bordered)
                }
                MarkdownContentView(markdown: generatedSummary)
            }
        }
    }

    // MARK: - Context for Claude

    private var contextSummary: String {
        var parts: [String] = []
        if !newArtifacts.isEmpty {
            parts.append("\(newArtifacts.count) contribution(s) linked")
        }
        if !newActionItems.isEmpty {
            parts.append("\(newActionItems.count) action item(s)")
        }
        // Past sessions
        let past = pastSessions()
        if !past.isEmpty { parts.append("\(past.count) past session(s) for context") }
        let open = openItemsFromPastSessions()
        if !open.isEmpty { parts.append("\(open.count) open item(s) from previous meetings") }
        return parts.joined(separator: " · ")
    }

    // MARK: - Data helpers

    private func pastSessions() -> [OneOnOneSession] {
        (report.documents
            .compactMap { _ -> OneOnOneSession? in nil }) // placeholder
        // Actually fetch from the model context via the report relationship
        // We'll use the sessions we can access via report's documents indirectly
        // For now return empty — the prompt builder queries directly
        return []
    }

    private func openItemsFromPastSessions() -> [ActionItem] { [] }

    // MARK: - Generation

    private func generateSummary() async {
        isGenerating = true
        generationError = nil

        // Fetch past sessions for this report to build context
        let descriptor = FetchDescriptor<OneOnOneSession>(
            predicate: #Predicate { $0.report?.id == report.id },
            sortBy: [SortDescriptor(\.date, order: .reverse)]
        )
        let pastSessions = (try? ctx.fetch(descriptor)) ?? []
        let recentPast = pastSessions.filter { $0.id != existingSession?.id }.prefix(3)

        // Fetch all open action items for this report
        let actionDescriptor = FetchDescriptor<ActionItem>(
            predicate: #Predicate { $0.report?.id == report.id && $0.isCompleted == false }
        )
        let openItems = (try? ctx.fetch(actionDescriptor)) ?? []

        // All recent artifacts (last 45 days)
        let cutoff = Calendar.current.date(byAdding: .day, value: -45, to: Date()) ?? Date()
        let artifactDescriptor = FetchDescriptor<ContributionArtifact>(
            predicate: #Predicate { $0.report?.id == report.id && $0.artifactDate >= cutoff }
        )
        let recentArtifacts = (try? ctx.fetch(artifactDescriptor)) ?? []
        // Also include any just-added artifacts from this session
        let allArtifacts = recentArtifacts + newArtifacts.filter { art in
            !recentArtifacts.contains { $0.id == art.id }
        }

        let system = Prompts.oneOnOneSystem
        let user = Prompts.oneOnOneUser(
            notes: rawNotes,
            reportName: report.name,
            pastSessions: Array(recentPast).map { s in
                (date: s.date,
                 summary: s.generatedSummary.isEmpty ? s.rawNotes : s.generatedSummary,
                 openItems: s.openActionItems.map { $0.title })
            },
            openActionItems: openItems.map { $0.title },
            recentArtifacts: allArtifacts.map { a in
                (type: a.artifactType.rawValue,
                 title: a.title,
                 date: a.artifactDate,
                 notes: a.notes)
            }
        )

        do {
            generatedSummary = try await ClaudeService.shared.generate(systemPrompt: system, userMessage: user)
            // Auto-switch to summary tab on success
            activeTab = .summary
        } catch {
            generationError = error.localizedDescription
        }
        isGenerating = false
    }

    // MARK: - Save

    private func saveSession() {
        let session = existingSession ?? OneOnOneSession(date: date, rawNotes: rawNotes)
        session.date = date
        session.rawNotes = rawNotes
        session.generatedSummary = generatedSummary
        session.report = report

        if existingSession == nil {
            ctx.insert(session)
        }

        // Persist new action items
        for draft in newActionItems where !draft.title.trimmingCharacters(in: .whitespaces).isEmpty {
            let item = ActionItem(title: draft.title.trimmingCharacters(in: .whitespaces),
                                  owner: draft.owner, dueDate: draft.dueDate)
            item.session = session
            item.report = report
            ctx.insert(item)
            session.actionItems.append(item)
        }

        // Persist new artifacts
        for artifact in newArtifacts {
            artifact.session = session
            artifact.report = report
            ctx.insert(artifact)
            session.artifacts.append(artifact)
        }

        dismiss()
    }
}
