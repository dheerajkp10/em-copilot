import SwiftUI
import SwiftData

struct DocumentGeneratorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var ctx
    @Query(sort: \DirectReport.name) private var reports: [DirectReport]

    var preselectedType: DocumentType
    var preselectedReport: DirectReport?

    @State private var selectedType: DocumentType
    @State private var selectedReport: DirectReport?
    @State private var notes: String = ""

    // Perf review specific
    @State private var selectedRating: PerformanceRating = .meetsAll
    @State private var selectedPeriod: ReviewPeriod = .annual
    @State private var company: String = ""

    // Stakeholder email specific
    @State private var audience: String = ""
    @State private var emailTone: String = "professional"

    // Generation state
    @State private var isGenerating = false
    @State private var generatedContent: String = ""
    @State private var error: String? = nil
    @State private var showingOutput = false

    init(preselectedType: DocumentType = .perfReview, preselectedReport: DirectReport? = nil) {
        self.preselectedType = preselectedType
        self.preselectedReport = preselectedReport
        _selectedType = State(initialValue: preselectedType)
        _selectedReport = State(initialValue: preselectedReport)
    }

    var body: some View {
        NavigationStack {
            Form {
                // Document type picker
                Section("Document Type") {
                    Picker("Type", selection: $selectedType) {
                        ForEach(DocumentType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon).tag(type)
                        }
                    }
                    .pickerStyle(.menu)
                }

                // Direct report selector (for person-specific docs)
                if requiresReport {
                    Section("Direct Report") {
                        Picker("Person", selection: $selectedReport) {
                            Text("Select a person").tag(DirectReport?.none)
                            ForEach(reports) { r in
                                Text(r.name).tag(DirectReport?.some(r))
                            }
                        }
                        .pickerStyle(.menu)

                        if let report = selectedReport {
                            HStack {
                                AvatarView(initials: report.initials, color: .blue, size: 28)
                                Text(report.displayLevel)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                // Type-specific configuration
                typeSpecificConfig

                // Notes input
                Section {
                    TextEditor(text: $notes)
                        .frame(minHeight: 150)
                        .font(.callout)
                } header: {
                    Text(notesLabel)
                } footer: {
                    Text(notesHint)
                }

                // Error
                if let error {
                    Section {
                        Label(error, systemImage: "xmark.octagon.fill")
                            .foregroundStyle(.red)
                            .font(.callout)
                    }
                }

                // Generate button
                Section {
                    Button {
                        Task { await generate() }
                    } label: {
                        HStack {
                            Spacer()
                            if isGenerating {
                                ProgressView()
                                    .controlSize(.small)
                                    .padding(.trailing, 6)
                                Text("Generating…")
                            } else {
                                Image(systemName: "sparkles")
                                Text("Generate with Claude")
                                    .fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .disabled(isGenerating || !canGenerate)
                    .tint(.indigo)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("New Document")
            .navigationTitleInline()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
            .sheet(isPresented: $showingOutput) {
                GeneratedDocumentOutputView(
                    content: generatedContent,
                    type: selectedType,
                    reportName: selectedReport?.name ?? "",
                    onSave: saveDocument
                )
            }
        }
    }

    // MARK: - Type-specific configuration views

    @ViewBuilder
    private var typeSpecificConfig: some View {
        switch selectedType {
        case .perfReview:
            Section("Review Details") {
                Picker("Rating / Calibration", selection: $selectedRating) {
                    ForEach(PerformanceRating.allCases, id: \.self) { r in
                        Text(r.rawValue).tag(r)
                    }
                }
                Picker("Period", selection: $selectedPeriod) {
                    ForEach(ReviewPeriod.allCases, id: \.self) { p in
                        Text(p.rawValue).tag(p)
                    }
                }
            }

        case .promoDoc:
            Section("Promotion Details") {
                TextField("Company (optional)", text: $company)
            }

        case .stakeholderEmail:
            Section("Email Details") {
                TextField("Audience (e.g. VP Engineering, Steering Committee)", text: $audience)
                Picker("Tone", selection: $emailTone) {
                    Text("Professional").tag("professional")
                    Text("Direct / Urgent").tag("direct and urgent")
                    Text("Informational").tag("informational")
                    Text("Concise / Executive").tag("concise and executive-level")
                }
            }

        default:
            EmptyView()
        }
    }

    // MARK: - Computed helpers

    private var requiresReport: Bool {
        [.perfReview, .promoDoc, .oneOnOne, .pip].contains(selectedType)
    }

    private var canGenerate: Bool {
        !notes.trimmingCharacters(in: .whitespaces).isEmpty
        && (!requiresReport || selectedReport != nil)
        && (selectedType != .stakeholderEmail || !audience.trimmingCharacters(in: .whitespaces).isEmpty)
    }

    private var notesLabel: String {
        switch selectedType {
        case .perfReview:       return "Your Observations & Notes"
        case .promoDoc:         return "Accomplishments & Peer Feedback"
        case .oneOnOne:         return "1:1 Meeting Notes"
        case .pip:              return "Performance Gaps & Incidents"
        case .programStatus:    return "Program Updates & Progress"
        case .stakeholderEmail: return "Key Points to Communicate"
        case .riskReport:       return "Risks & Issues"
        }
    }

    private var notesHint: String {
        switch selectedType {
        case .perfReview:
            return "Paste your raw notes, Slack highlights, project outcomes, peer themes. The messier the better — Claude will structure it."
        case .promoDoc:
            return "List key projects, business impact, metrics, and peer/stakeholder feedback themes."
        case .oneOnOne:
            return "Raw 1:1 notes — topics discussed, what they said, your observations, follow-ups mentioned."
        case .pip:
            return "Describe specific performance gaps, incidents with dates, and the expected behavior gap."
        case .programStatus:
            return "What shipped, what's planned, blockers, risks, and any decisions needed."
        case .stakeholderEmail:
            return "The key message, context, and any action you need from them."
        case .riskReport:
            return "List risks you're tracking, their severity, any mitigations in place, and owners."
        }
    }

    // MARK: - Generation

    private func generate() async {
        guard !isGenerating else { return }
        isGenerating = true
        error = nil
        let trimmedNotes = notes.trimmingCharacters(in: .whitespaces)

        do {
            let system: String
            let user: String

            switch selectedType {
            case .perfReview:
                let r = selectedReport!
                system = Prompts.perfReviewSystem(
                    reportName: r.name,
                    level: r.level.isEmpty ? "unspecified" : r.level,
                    role: r.role.isEmpty ? "Engineer" : r.role,
                    period: selectedPeriod.rawValue,
                    targetRating: selectedRating.rawValue
                )
                user = Prompts.perfReviewUser(notes: trimmedNotes)

            case .promoDoc:
                let r = selectedReport!
                let parts = r.level.components(separatedBy: "→").map { $0.trimmingCharacters(in: .whitespaces) }
                system = Prompts.promoDocSystem(
                    reportName: r.name,
                    currentLevel: parts.first ?? r.level,
                    targetLevel: parts.count > 1 ? parts[1] : "next level",
                    role: r.role.isEmpty ? "Engineer" : r.role,
                    company: company
                )
                user = Prompts.promoDocUser(notes: trimmedNotes)

            case .oneOnOne:
                system = Prompts.oneOnOneSystem
                user = Prompts.oneOnOneUser(notes: trimmedNotes, reportName: selectedReport?.name ?? "the engineer")

            case .pip:
                let r = selectedReport!
                system = Prompts.pipSystem(
                    reportName: r.name,
                    role: r.role.isEmpty ? "Engineer" : r.role,
                    level: r.level.isEmpty ? "unspecified" : r.level,
                    issueType: "performance and delivery"
                )
                user = Prompts.pipUser(notes: trimmedNotes)

            case .programStatus:
                system = Prompts.programStatusSystem(
                    programName: "the program",
                    status: "Active",
                    stakeholders: ""
                )
                user = Prompts.programStatusUser(notes: trimmedNotes)

            case .stakeholderEmail:
                system = Prompts.stakeholderEmailSystem(
                    context: trimmedNotes,
                    audience: audience,
                    tone: emailTone
                )
                user = Prompts.stakeholderEmailUser(notes: trimmedNotes)

            case .riskReport:
                system = Prompts.riskReportSystem
                user = Prompts.riskReportUser(notes: trimmedNotes)
            }

            generatedContent = try await ClaudeService.shared.generate(
                systemPrompt: system,
                userMessage: user
            )
            showingOutput = true

        } catch {
            self.error = error.localizedDescription
        }

        isGenerating = false
    }

    private func saveDocument(title: String) {
        let doc = GeneratedDocument(
            type: selectedType,
            title: title,
            inputNotes: notes,
            generatedContent: generatedContent,
            rating: selectedType == .perfReview ? selectedRating : nil,
            period: selectedType == .perfReview ? selectedPeriod : nil,
            report: selectedReport,
            reportName: selectedReport?.name ?? ""
        )
        ctx.insert(doc)
        dismiss()
    }
}
