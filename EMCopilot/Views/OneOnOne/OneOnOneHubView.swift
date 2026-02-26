import SwiftUI
import SwiftData

/// The 1:1 Hub — per-person view showing all sessions, running action items, and contribution log.
struct OneOnOneHubView: View {
    @Environment(\.modelContext) private var ctx
    let report: DirectReport

    @Query private var allSessions: [OneOnOneSession]
    @Query private var allActions: [ActionItem]
    @Query private var allArtifacts: [ContributionArtifact]

    @State private var selectedTab: HubTab = .sessions
    @State private var showingNewSession = false

    enum HubTab: String, CaseIterable {
        case sessions     = "Sessions"
        case actionItems  = "Action Items"
        case contributions = "Contributions"
    }

    // Filtered to this report
    private var sessions: [OneOnOneSession] {
        allSessions
            .filter { $0.report?.id == report.id }
            .sorted { $0.date > $1.date }
    }
    private var openActions: [ActionItem] {
        allActions
            .filter { $0.report?.id == report.id && !$0.isCompleted }
            .sorted { ($0.dueDate ?? .distantFuture) < ($1.dueDate ?? .distantFuture) }
    }
    private var contributions: [ContributionArtifact] {
        allArtifacts
            .filter { $0.report?.id == report.id }
            .sorted { $0.artifactDate > $1.artifactDate }
    }

    var body: some View {
        VStack(spacing: 0) {
            // Stats bar
            HStack(spacing: 0) {
                StatPill(value: "\(sessions.count)", label: "Sessions")
                Divider().frame(height: 30)
                StatPill(value: "\(openActions.count)", label: "Open Items",
                         highlight: openActions.contains { $0.isOverdue })
                Divider().frame(height: 30)
                StatPill(value: "\(contributions.count)", label: "Contributions")
            }
            .padding(.vertical, 10)
            .background(.quaternary.opacity(0.5))

            // Tab picker
            Picker("", selection: $selectedTab) {
                ForEach(HubTab.allCases, id: \.self) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)

            Divider()

            // Tab content
            Group {
                switch selectedTab {
                case .sessions:      sessionsTab
                case .actionItems:   actionItemsTab
                case .contributions: contributionsTab
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .navigationTitle("\(report.name) — 1:1s")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingNewSession = true } label: {
                    Label("New Session", systemImage: "plus")
                }
                .buttonStyle(.borderedProminent)
                .tint(.indigo)
            }
        }
        .sheet(isPresented: $showingNewSession) {
            OneOnOneSessionView(report: report)
        }
    }

    // MARK: - Sessions tab

    private var sessionsTab: some View {
        Group {
            if sessions.isEmpty {
                ContentUnavailableView {
                    Label("No Sessions Yet", systemImage: "person.2")
                } description: {
                    Text("Start a new session to capture 1:1 notes, action items, and build a running history.")
                } actions: {
                    Button("New Session") { showingNewSession = true }
                        .buttonStyle(.borderedProminent).tint(.indigo)
                }
            } else {
                List {
                    ForEach(sessions) { session in
                        SessionRowView(session: session, report: report)
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    // MARK: - Action Items tab

    private var actionItemsTab: some View {
        Group {
            if openActions.isEmpty {
                ContentUnavailableView {
                    Label("No Open Action Items", systemImage: "checkmark.circle")
                } description: {
                    Text("Action items from your 1:1 sessions will appear here.")
                }
            } else {
                List {
                    ForEach(openActions) { item in
                        ActionItemRow(item: item)
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    // MARK: - Contributions tab

    private var contributionsTab: some View {
        Group {
            if contributions.isEmpty {
                ContentUnavailableView {
                    Label("No Contributions Logged", systemImage: "chart.line.uptrend.xyaxis")
                } description: {
                    Text("Link PRs, design docs, and incidents from your 1:1 sessions to build a contribution log.")
                }
            } else {
                List {
                    ForEach(groupedByMonth(contributions), id: \.month) { group in
                        Section(group.month) {
                            ForEach(group.artifacts) { artifact in
                                ArtifactRowView(artifact: artifact)
                            }
                        }
                    }
                }
                .listStyle(.plain)
            }
        }
    }

    private struct MonthGroup {
        let month: String
        let artifacts: [ContributionArtifact]
    }

    private func groupedByMonth(_ artifacts: [ContributionArtifact]) -> [MonthGroup] {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        let grouped = Dictionary(grouping: artifacts) { formatter.string(from: $0.artifactDate) }
        return grouped.keys.sorted(by: >).map { MonthGroup(month: $0, artifacts: grouped[$0]!) }
    }
}

// MARK: - Supporting row views

struct StatPill: View {
    let value: String
    let label: String
    var highlight: Bool = false

    var body: some View {
        VStack(spacing: 2) {
            Text(value).font(.title3.bold()).foregroundStyle(highlight ? .orange : .primary)
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}

struct SessionRowView: View {
    let session: OneOnOneSession
    let report: DirectReport
    @State private var showingDetail = false

    var body: some View {
        Button { showingDetail = true } label: {
            HStack(spacing: 14) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(session.date.formatted(date: .long, time: .omitted))
                        .fontWeight(.semibold)
                    if session.generatedSummary.isEmpty {
                        Text("Notes captured — summary not yet generated")
                            .font(.caption).foregroundStyle(.secondary)
                    } else {
                        Text(firstLine(of: session.generatedSummary))
                            .font(.caption).foregroundStyle(.secondary).lineLimit(1)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 3) {
                    if !session.openActionItems.isEmpty {
                        Label("\(session.openActionItems.count)", systemImage: "square")
                            .font(.caption2).foregroundStyle(.orange)
                    }
                    if !session.artifacts.isEmpty {
                        Label("\(session.artifacts.count)", systemImage: "link")
                            .font(.caption2).foregroundStyle(.secondary)
                    }
                }
                Image(systemName: "chevron.right").font(.caption).foregroundStyle(.tertiary)
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingDetail) {
            OneOnOneSessionView(report: report, existingSession: session)
        }
    }

    private func firstLine(of text: String) -> String {
        text.components(separatedBy: "\n")
            .first(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty })?
            .replacingOccurrences(of: "#", with: "")
            .trimmingCharacters(in: .whitespaces) ?? ""
    }
}

struct ActionItemRow: View {
    @Bindable var item: ActionItem

    var body: some View {
        HStack(spacing: 12) {
            Button {
                item.isCompleted = true
                item.completedAt = Date()
            } label: {
                Image(systemName: "square")
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title).font(.subheadline)
                HStack(spacing: 6) {
                    if !item.owner.isEmpty {
                        Label(item.owner, systemImage: "person").font(.caption2).foregroundStyle(.secondary)
                    }
                    if let due = item.dueDate {
                        Label(due.formatted(date: .abbreviated, time: .omitted),
                              systemImage: "calendar")
                            .font(.caption2)
                            .foregroundStyle(item.isOverdue ? .red : .secondary)
                    }
                }
            }
        }
        .padding(.vertical, 3)
    }
}

struct ArtifactRowView: View {
    let artifact: ContributionArtifact

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: artifact.artifactType.icon)
                .foregroundStyle(.indigo)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(artifact.title).font(.subheadline)
                HStack {
                    Text(artifact.artifactType.rawValue)
                        .font(.caption2).foregroundStyle(.secondary)
                    if !artifact.notes.isEmpty {
                        Text("·").font(.caption2).foregroundStyle(.tertiary)
                        Text(artifact.notes).font(.caption2).foregroundStyle(.secondary).lineLimit(1)
                    }
                }
            }
            Spacer()
            if !artifact.url.isEmpty {
                Link(destination: URL(string: artifact.url) ?? URL(string: "https://example.com")!) {
                    Image(systemName: "arrow.up.right.square")
                        .font(.caption)
                        .foregroundStyle(.indigo)
                }
            }
        }
        .padding(.vertical, 3)
    }
}
