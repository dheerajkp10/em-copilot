import SwiftUI
import SwiftData

struct HomeView: View {
    @Query private var reports: [DirectReport]
    @Query(sort: \GeneratedDocument.createdAt, order: .reverse) private var recentDocs: [GeneratedDocument]
    @Query private var programs: [Program]

    @State private var showingGenerator = false
    @State private var quickDocType: DocumentType = .perfReview

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Greeting
                VStack(alignment: .leading, spacing: 4) {
                    Text("EM Copilot")
                        .font(.largeTitle)
                        .bold()
                    Text("Your AI-powered engineering management toolkit")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                .padding(.top, 8)

                // Quick actions
                VStack(alignment: .leading, spacing: 12) {
                    SectionHeader("Quick Generate")
                    LazyVGrid(columns: [GridItem(.adaptive(minimum: 160))], spacing: 12) {
                        ForEach(DocumentType.allCases, id: \.self) { type in
                            QuickActionCard(type: type) {
                                quickDocType = type
                                showingGenerator = true
                            }
                        }
                    }
                }
                .padding(.horizontal)

                // Stats row
                if !reports.isEmpty || !programs.isEmpty {
                    HStack(spacing: 16) {
                        StatCard(value: "\(reports.count)", label: "Direct Reports", icon: "person.2.fill", color: .blue)
                        StatCard(value: "\(programs.count)", label: "Programs", icon: "list.bullet.clipboard.fill", color: .teal)
                        StatCard(value: "\(recentDocs.count)", label: "Documents", icon: "doc.text.fill", color: .indigo)
                    }
                    .padding(.horizontal)
                }

                // Recent documents
                if !recentDocs.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader("Recent Documents")
                        VStack(spacing: 8) {
                            ForEach(recentDocs.prefix(5)) { doc in
                                RecentDocRow(doc: doc)
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                // Programs at risk
                let atRiskPrograms = programs.filter { $0.status == .atRisk || $0.status == .offTrack || $0.status == .blocked }
                if !atRiskPrograms.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        SectionHeader("Needs Attention")
                        VStack(spacing: 8) {
                            ForEach(atRiskPrograms) { program in
                                AtRiskProgramRow(program: program)
                            }
                        }
                    }
                    .padding(.horizontal)
                }

                Spacer(minLength: 40)
            }
        }
        .sheet(isPresented: $showingGenerator) {
            DocumentGeneratorView(preselectedType: quickDocType)
        }
    }
}

struct SectionHeader: View {
    let title: String
    init(_ title: String) { self.title = title }
    var body: some View {
        Text(title)
            .font(.headline)
            .foregroundStyle(.primary)
    }
}

struct QuickActionCard: View {
    let type: DocumentType
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 8) {
                Image(systemName: type.icon)
                    .font(.title2)
                    .foregroundStyle(cardColor)
                Text(type.rawValue)
                    .font(.caption)
                    .fontWeight(.medium)
                    .multilineTextAlignment(.leading)
                    .foregroundStyle(.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(14)
            .background(cardColor.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(cardColor.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }

    private var cardColor: Color {
        switch type.color {
        case "blue":   return .blue
        case "green":  return .green
        case "purple": return .purple
        case "orange": return .orange
        case "teal":   return .teal
        case "indigo": return .indigo
        case "red":    return .red
        default:       return .gray
        }
    }
}

struct StatCard: View {
    let value: String
    let label: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Image(systemName: icon).foregroundStyle(color)
            Text(value).font(.title2).bold()
            Text(label).font(.caption2).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

struct RecentDocRow: View {
    let doc: GeneratedDocument

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: doc.type.icon)
                .foregroundStyle(.indigo)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(doc.title).font(.subheadline).lineLimit(1)
                if !doc.reportName.isEmpty {
                    Text(doc.reportName).font(.caption).foregroundStyle(.secondary)
                }
            }
            Spacer()
            Text(doc.createdAt.formatted(.relative(presentation: .named)))
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .padding(10)
        .background(.quaternary.opacity(0.5))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}

struct AtRiskProgramRow: View {
    let program: Program

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: program.status.icon)
                .foregroundStyle(program.status == .blocked || program.status == .offTrack ? .red : .orange)
                .frame(width: 24)
            VStack(alignment: .leading, spacing: 2) {
                Text(program.name).font(.subheadline).fontWeight(.medium)
                Text(program.status.rawValue).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            if !program.criticalRisks.isEmpty {
                Label("\(program.criticalRisks.count)", systemImage: "exclamationmark.triangle")
                    .font(.caption2)
                    .foregroundStyle(.orange)
            }
        }
        .padding(10)
        .background(Color.orange.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 8))
    }
}
