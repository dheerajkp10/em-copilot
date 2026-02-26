import SwiftUI
import SwiftData

struct DirectReportsView: View {
    @Environment(\.modelContext) private var ctx
    @Query(sort: \DirectReport.name) private var reports: [DirectReport]

    @State private var showingAdd = false
    @State private var selected: DirectReport? = nil

    var body: some View {
        Group {
            if reports.isEmpty {
                emptyState
            } else {
                list
            }
        }
        .navigationTitle("Direct Reports")
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button { showingAdd = true } label: {
                    Label("Add", systemImage: "plus")
                }
            }
        }
        .sheet(isPresented: $showingAdd) {
            AddDirectReportView()
        }
        .sheet(item: $selected) { report in
            DirectReportDetailView(report: report)
        }
    }

    private var list: some View {
        List(reports) { report in
            Button { selected = report } label: {
                HStack(spacing: 14) {
                    AvatarView(initials: report.initials, color: colorFor(report.name))
                    VStack(alignment: .leading, spacing: 3) {
                        Text(report.name).fontWeight(.semibold)
                        Text(report.displayLevel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    Spacer()
                    Text("\(report.documents.count) docs")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .padding(.vertical, 4)
            }
            .buttonStyle(.plain)
            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button(role: .destructive) {
                    ctx.delete(report)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView {
            Label("No Direct Reports", systemImage: "person.2")
        } description: {
            Text("Add your direct reports to start generating performance reviews, promo docs, and more.")
        } actions: {
            Button("Add Direct Report") { showingAdd = true }
                .buttonStyle(.borderedProminent)
        }
    }

    private func colorFor(_ name: String) -> Color {
        let colors: [Color] = [.blue, .purple, .green, .orange, .pink, .teal, .indigo, .cyan]
        let idx = abs(name.hashValue) % colors.count
        return colors[idx]
    }
}

struct AvatarView: View {
    let initials: String
    let color: Color
    var size: CGFloat = 40

    var body: some View {
        ZStack {
            Circle()
                .fill(color.opacity(0.15))
                .frame(width: size, height: size)
            Text(initials)
                .font(.system(size: size * 0.38, weight: .semibold))
                .foregroundStyle(color)
        }
    }
}

struct DirectReportDetailView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var ctx
    let report: DirectReport
    @State private var showingGenerator = false
    @State private var showingOneOnOneHub = false
    @State private var selectedDocType: DocumentType = .perfReview

    var body: some View {
        NavigationStack {
            List {
                // Profile header
                Section {
                    HStack(spacing: 16) {
                        AvatarView(initials: report.initials, color: .blue, size: 56)
                        VStack(alignment: .leading, spacing: 4) {
                            Text(report.name).font(.title2).bold()
                            Text(report.displayLevel).foregroundStyle(.secondary)
                            if !report.team.isEmpty {
                                Text(report.team).font(.caption).foregroundStyle(.tertiary)
                            }
                        }
                    }
                    .padding(.vertical, 6)
                }

                // 1:1 Hub — prominent entry point at the top
                Section {
                    Button {
                        showingOneOnOneHub = true
                    } label: {
                        HStack(spacing: 14) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.purple.opacity(0.12))
                                    .frame(width: 36, height: 36)
                                Image(systemName: "person.2.circle.fill")
                                    .foregroundStyle(.purple)
                                    .font(.title3)
                            }
                            VStack(alignment: .leading, spacing: 2) {
                                Text("1:1 Sessions")
                                    .fontWeight(.semibold)
                                Text("Notes · Action items · Contributions")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                        }
                        .padding(.vertical, 2)
                    }
                    .buttonStyle(.plain)
                } header: {
                    Text("1:1 Workflow")
                }

                // AI document generators (removes oneOnOne from here — it lives in the hub)
                Section("Generate Document") {
                    ForEach([DocumentType.perfReview, .promoDoc, .pip], id: \.self) { type in
                        Button {
                            selectedDocType = type
                            showingGenerator = true
                        } label: {
                            Label(type.rawValue, systemImage: type.icon)
                        }
                    }
                }

                if !report.documents.isEmpty {
                    Section("Recent Documents") {
                        ForEach(report.documents.sorted { $0.createdAt > $1.createdAt }.prefix(5)) { doc in
                            VStack(alignment: .leading, spacing: 2) {
                                Text(doc.title).font(.subheadline)
                                Text(doc.createdAt.formatted(date: .abbreviated, time: .omitted))
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                        }
                    }
                }

                if !report.notes.isEmpty {
                    Section("Ongoing Notes") {
                        Text(report.notes)
                            .font(.callout)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .navigationTitle(report.name)
            .navigationTitleInline()
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
            }
            .sheet(isPresented: $showingGenerator) {
                DocumentGeneratorView(
                    preselectedType: selectedDocType,
                    preselectedReport: report
                )
            }
            .sheet(isPresented: $showingOneOnOneHub) {
                OneOnOneHubView(report: report)
            }
        }
    }
}
