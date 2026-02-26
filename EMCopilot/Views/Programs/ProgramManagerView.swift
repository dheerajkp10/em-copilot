import SwiftUI
import SwiftData

struct ProgramManagerView: View {
    @Environment(\.modelContext) private var ctx
    @Query(sort: \Program.updatedAt, order: .reverse) private var programs: [Program]

    @State private var showingAdd = false
    @State private var selected: Program? = nil
    @State private var filterStatus: ProgramStatus? = nil

    private var filtered: [Program] {
        guard let status = filterStatus else { return programs }
        return programs.filter { $0.status == status }
    }

    var body: some View {
        Group {
            if programs.isEmpty {
                emptyState
            } else {
                list
            }
        }
        .navigationTitle("Programs")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingAdd = true } label: {
                    Label("Add Program", systemImage: "plus")
                }
            }
            ToolbarItem(placement: .automatic) {
                Menu {
                    Button("All") { filterStatus = nil }
                    Divider()
                    ForEach(ProgramStatus.allCases, id: \.self) { s in
                        Button(s.rawValue) { filterStatus = s }
                    }
                } label: {
                    Label(filterStatus?.rawValue ?? "Filter", systemImage: "line.3.horizontal.decrease.circle")
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddProgramView()
        }
        .sheet(item: $selected) { program in
            ProgramDetailView(program: program)
        }
    }

    private var list: some View {
        List(filtered) { program in
            Button { selected = program } label: {
                ProgramRowView(program: program)
            }
            .buttonStyle(.plain)
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button(role: .destructive) { ctx.delete(program) } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Programs", systemImage: "list.bullet.clipboard")
        } description: {
            Text("Add programs to track status, risks, and generate stakeholder reports.")
        } actions: {
            Button("Add Program") { showingAdd = true }
                .buttonStyle(.borderedProminent)
        }
    }
}

struct ProgramRowView: View {
    let program: Program

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: program.status.icon)
                .foregroundStyle(statusColor)
                .font(.title3)
                .frame(width: 30)

            VStack(alignment: .leading, spacing: 3) {
                Text(program.name).fontWeight(.semibold)
                Text(program.objective.isEmpty ? "No objective set" : program.objective)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text(program.status.rawValue)
                    .font(.caption2)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(statusColor.opacity(0.12))
                    .foregroundStyle(statusColor)
                    .clipShape(Capsule())

                if !program.criticalRisks.isEmpty {
                    Label("\(program.criticalRisks.count) risks", systemImage: "exclamationmark.triangle.fill")
                        .font(.caption2)
                        .foregroundStyle(.orange)
                }
            }
        }
        .padding(.vertical, 4)
    }

    private var statusColor: Color {
        switch program.status {
        case .onTrack:   return .green
        case .atRisk:    return .orange
        case .offTrack:  return .red
        case .blocked:   return .red
        case .completed: return .blue
        case .onHold:    return .gray
        }
    }
}

struct ProgramDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var ctx
    @Bindable var program: Program

    @State private var showingStatusReport = false
    @State private var showingAddRisk = false
    @State private var showingAddUpdate = false
    @State private var updateNotes = ""
    @State private var generatingReport = false
    @State private var reportError: String? = nil

    var body: some View {
        NavigationStack {
            List {
                // Status header
                Section {
                    HStack {
                        Image(systemName: program.status.icon)
                            .font(.title)
                            .foregroundStyle(statusColor)
                        VStack(alignment: .leading) {
                            Text(program.name).font(.title2).bold()
                            Picker("Status", selection: $program.status) {
                                ForEach(ProgramStatus.allCases, id: \.self) { s in
                                    Text(s.rawValue).tag(s)
                                }
                            }
                            .pickerStyle(.menu)
                            .labelsHidden()
                        }
                    }
                    .padding(.vertical, 4)
                }

                // Quick info
                Section("Overview") {
                    if !program.objective.isEmpty {
                        LabeledContent("Objective", value: program.objective)
                    }
                    if !program.owner.isEmpty {
                        LabeledContent("Owner", value: program.owner)
                    }
                    if let date = program.targetDate {
                        LabeledContent("Target Date", value: date.formatted(date: .long, time: .omitted))
                    }
                    if !program.stakeholders.isEmpty {
                        LabeledContent("Stakeholders", value: program.stakeholders)
                    }
                }

                // AI Actions
                Section("Generate Reports") {
                    Button {
                        showingAddUpdate = true
                    } label: {
                        Label("Generate Status Report", systemImage: "doc.text.magnifyingglass")
                    }
                    Button {
                        showingAddUpdate = true
                    } label: {
                        Label("Generate Stakeholder Email", systemImage: "envelope.badge")
                    }
                    Button {
                        showingAddUpdate = true
                    } label: {
                        Label("Generate Risk Report", systemImage: "shield.lefthalf.filled")
                    }
                }

                // Risks
                Section {
                    ForEach(program.risks.sorted { r1, r2 in
                        severityOrder(r1.severity) < severityOrder(r2.severity)
                    }) { risk in
                        RiskRowView(risk: risk)
                    }
                    Button {
                        showingAddRisk = true
                    } label: {
                        Label("Add Risk", systemImage: "plus.circle")
                    }
                } header: {
                    HStack {
                        Text("Risks")
                        if !program.criticalRisks.isEmpty {
                            Spacer()
                            Text("\(program.criticalRisks.count) critical/high")
                                .font(.caption)
                                .foregroundStyle(.orange)
                        }
                    }
                }

                // Recent updates
                if !program.updates.isEmpty {
                    Section("Update History") {
                        ForEach(program.updates.sorted { $0.createdAt > $1.createdAt }) { update in
                            VStack(alignment: .leading, spacing: 4) {
                                Text(update.createdAt.formatted(date: .abbreviated, time: .shortened))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(update.summary)
                                    .font(.callout)
                                    .lineLimit(3)
                            }
                        }
                    }
                }
            }
            .navigationTitle(program.name)
            .navigationTitleInline()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        program.updatedAt = Date()
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingAddRisk) {
                AddRiskView(program: program)
            }
            .sheet(isPresented: $showingAddUpdate) {
                ProgramUpdateGeneratorView(program: program)
            }
        }
    }

    private var statusColor: Color {
        switch program.status {
        case .onTrack:   return .green
        case .atRisk:    return .orange
        case .offTrack, .blocked: return .red
        case .completed: return .blue
        case .onHold:    return .gray
        }
    }

    private func severityOrder(_ s: RiskSeverity) -> Int {
        switch s {
        case .critical: return 0
        case .high:     return 1
        case .medium:   return 2
        case .low:      return 3
        }
    }
}

struct RiskRowView: View {
    let risk: ProgramRisk

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack {
                SeverityBadge(severity: risk.severity)
                Text(risk.title).fontWeight(.medium)
            }
            if !risk.details.isEmpty {
                Text(risk.details)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
            }
            if !risk.mitigation.isEmpty {
                Label(risk.mitigation, systemImage: "shield.checkered")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 2)
    }
}

struct SeverityBadge: View {
    let severity: RiskSeverity

    var body: some View {
        Text(severity.rawValue)
            .font(.caption2)
            .fontWeight(.semibold)
            .padding(.horizontal, 7)
            .padding(.vertical, 3)
            .background(color.opacity(0.15))
            .foregroundStyle(color)
            .clipShape(Capsule())
    }

    private var color: Color {
        switch severity {
        case .critical: return .red
        case .high:     return .orange
        case .medium:   return .yellow
        case .low:      return .green
        }
    }
}

struct AddRiskView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var ctx
    let program: Program

    @State private var title = ""
    @State private var description = ""
    @State private var severity: RiskSeverity = .medium
    @State private var mitigation = ""
    @State private var owner = ""

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Risk title *", text: $title)
                    TextEditor(text: $description)
                        .frame(minHeight: 60)
                } header: { Text("Risk") }

                Section {
                    Picker("Severity", selection: $severity) {
                        ForEach(RiskSeverity.allCases, id: \.self) { s in
                            Text(s.rawValue).tag(s)
                        }
                    }
                } header: { Text("Severity") }

                Section {
                    TextField("Mitigation plan", text: $mitigation)
                    TextField("Owner", text: $owner)
                } header: { Text("Mitigation") }
            }
            .formStyle(.grouped)
            .navigationTitle("Add Risk")
            .navigationTitleInline()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") { save() }
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let risk = ProgramRisk(
            title: title.trimmingCharacters(in: .whitespaces),
            details: description.trimmingCharacters(in: .whitespaces),
            severity: severity,
            mitigation: mitigation.trimmingCharacters(in: .whitespaces),
            owner: owner.trimmingCharacters(in: .whitespaces)
        )
        risk.program = program
        ctx.insert(risk)
        program.risks.append(risk)
        dismiss()
    }
}

struct ProgramUpdateGeneratorView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var ctx
    let program: Program

    @State private var updateType: DocumentType = .programStatus
    @State private var notes = ""
    @State private var isGenerating = false
    @State private var generatedContent = ""
    @State private var showingOutput = false
    @State private var error: String? = nil

    var body: some View {
        NavigationStack {
            Form {
                Section("Report Type") {
                    Picker("Type", selection: $updateType) {
                        Text("Status Report").tag(DocumentType.programStatus)
                        Text("Stakeholder Email").tag(DocumentType.stakeholderEmail)
                        Text("Risk Report").tag(DocumentType.riskReport)
                    }
                    .pickerStyle(.segmented)
                }

                Section {
                    TextEditor(text: $notes)
                        .frame(minHeight: 120)
                } header: {
                    Text("Updates & Context")
                } footer: {
                    Text("Paste in your latest notes, what shipped, what's blocked, any new risks.")
                }

                if let error {
                    Section {
                        Label(error, systemImage: "xmark.octagon").foregroundStyle(.red)
                    }
                }

                Section {
                    Button {
                        Task { await generate() }
                    } label: {
                        HStack {
                            Spacer()
                            if isGenerating {
                                ProgressView().controlSize(.small)
                                Text("Generating…")
                            } else {
                                Image(systemName: "sparkles")
                                Text("Generate").fontWeight(.semibold)
                            }
                            Spacer()
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.indigo)
                    .disabled(isGenerating || notes.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Generate for \(program.name)")
            .navigationTitleInline()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
            }
            .sheet(isPresented: $showingOutput) {
                GeneratedDocumentOutputView(
                    content: generatedContent,
                    type: updateType,
                    reportName: program.name,
                    onSave: { title in
                        let update = ProgramUpdate(summary: notes, generatedReport: generatedContent)
                        update.program = program
                        ctx.insert(update)
                        program.updates.append(update)
                        dismiss()
                    }
                )
            }
        }
    }

    private func generate() async {
        isGenerating = true
        error = nil
        let trimmed = notes.trimmingCharacters(in: .whitespaces)
        do {
            let system: String
            let user: String
            switch updateType {
            case .programStatus:
                system = Prompts.programStatusSystem(programName: program.name, status: program.status.rawValue, stakeholders: program.stakeholders)
                user = Prompts.programStatusUser(notes: trimmed)
            case .stakeholderEmail:
                system = Prompts.stakeholderEmailSystem(context: "Program update for \(program.name)", audience: program.stakeholders.isEmpty ? "key stakeholders" : program.stakeholders, tone: "professional")
                user = Prompts.stakeholderEmailUser(notes: trimmed)
            case .riskReport:
                system = Prompts.riskReportSystem
                user = Prompts.riskReportUser(notes: trimmed + "\n\nKnown risks: \(program.risks.map { "\($0.severity.rawValue): \($0.title)" }.joined(separator: ", "))")
            default:
                system = Prompts.programStatusSystem(programName: program.name, status: program.status.rawValue, stakeholders: program.stakeholders)
                user = Prompts.programStatusUser(notes: trimmed)
            }
            generatedContent = try await ClaudeService.shared.generate(systemPrompt: system, userMessage: user)
            showingOutput = true
        } catch {
            self.error = error.localizedDescription
        }
        isGenerating = false
    }
}

struct AddProgramView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var ctx

    @State private var name = ""
    @State private var objective = ""
    @State private var owner = ""
    @State private var status: ProgramStatus = .onTrack
    @State private var targetDate: Date = Calendar.current.date(byAdding: .month, value: 3, to: Date()) ?? Date()
    @State private var hasTargetDate = false
    @State private var stakeholders = ""
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            Form {
                Section("Program") {
                    TextField("Program name *", text: $name)
                    TextEditor(text: $objective)
                        .frame(minHeight: 60)
                        .overlay(alignment: .topLeading) {
                            if objective.isEmpty {
                                Text("Objective / goal statement")
                                    .foregroundStyle(.tertiary)
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                                    .allowsHitTesting(false)
                            }
                        }
                }

                Section("Status") {
                    Picker("Status", selection: $status) {
                        ForEach(ProgramStatus.allCases, id: \.self) { s in
                            Text(s.rawValue).tag(s)
                        }
                    }
                    TextField("Owner / DRI", text: $owner)
                    Toggle("Has Target Date", isOn: $hasTargetDate)
                    if hasTargetDate {
                        DatePicker("Target Date", selection: $targetDate, displayedComponents: .date)
                    }
                }

                Section("Stakeholders") {
                    TextEditor(text: $stakeholders)
                        .frame(minHeight: 60)
                        .overlay(alignment: .topLeading) {
                            if stakeholders.isEmpty {
                                Text("VP Engineering, Product Lead, Finance…")
                                    .foregroundStyle(.tertiary)
                                    .padding(.top, 8)
                                    .padding(.leading, 4)
                                    .allowsHitTesting(false)
                            }
                        }
                }

                Section("Notes") {
                    TextEditor(text: $notes)
                        .frame(minHeight: 60)
                }
            }
            .formStyle(.grouped)
            .navigationTitle("Add Program")
            .navigationTitleInline()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Cancel") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }

    private func save() {
        let program = Program(
            name: name.trimmingCharacters(in: .whitespaces),
            objective: objective.trimmingCharacters(in: .whitespaces),
            status: status,
            owner: owner.trimmingCharacters(in: .whitespaces),
            targetDate: hasTargetDate ? targetDate : nil,
            stakeholders: stakeholders.trimmingCharacters(in: .whitespaces),
            notes: notes.trimmingCharacters(in: .whitespaces)
        )
        ctx.insert(program)
        dismiss()
    }
}
