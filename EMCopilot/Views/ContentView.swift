import SwiftUI
import SwiftData

// MARK: - Cross-platform helpers

extension View {
    /// `.navigationBarTitleDisplayMode(.inline)` is iOS-only.
    /// Call `.navigationTitleInline()` everywhere instead — it's a no-op on macOS.
    func navigationTitleInline() -> some View {
        #if os(iOS)
        self.navigationBarTitleDisplayMode(.inline)
        #else
        self
        #endif
    }
}

enum AppDestination: Hashable, CaseIterable {
    case home
    case directReports
    case programs
    case allDocuments
    case settings

    var label: String {
        switch self {
        case .home:          return "Home"
        case .directReports: return "Direct Reports"
        case .programs:      return "Programs"
        case .allDocuments:  return "All Documents"
        case .settings:      return "Settings"
        }
    }

    var icon: String {
        switch self {
        case .home:          return "house.fill"
        case .directReports: return "person.2.fill"
        case .programs:      return "list.bullet.clipboard.fill"
        case .allDocuments:  return "doc.text.fill"
        case .settings:      return "gearshape.fill"
        }
    }
}

struct ContentView: View {
    @State private var selectedDestination: AppDestination = .home

    var body: some View {
        #if os(macOS)
        macOSLayout
        #else
        iOSLayout
        #endif
    }

    // MARK: - macOS: NavigationSplitView

    #if os(macOS)
    private var macOSLayout: some View {
        NavigationSplitView {
            List(AppDestination.allCases, id: \.self, selection: $selectedDestination) { dest in
                Label(dest.label, systemImage: dest.icon)
            }
            .navigationSplitViewColumnWidth(min: 180, ideal: 200)
            .listStyle(.sidebar)
        } detail: {
            detailView(for: selectedDestination)
        }
    }
    #endif

    // MARK: - iOS: TabView

    private var iOSLayout: some View {
        TabView {
            NavigationStack { HomeView() }
                .tabItem { Label("Home", systemImage: "house.fill") }

            NavigationStack { DirectReportsView() }
                .tabItem { Label("Reports", systemImage: "person.2.fill") }

            NavigationStack { ProgramManagerView() }
                .tabItem { Label("Programs", systemImage: "list.bullet.clipboard.fill") }

            NavigationStack { AllDocumentsView() }
                .tabItem { Label("Docs", systemImage: "doc.text.fill") }

            NavigationStack { SettingsView() }
                .tabItem { Label("Settings", systemImage: "gearshape.fill") }
        }
    }

    @ViewBuilder
    private func detailView(for destination: AppDestination) -> some View {
        switch destination {
        case .home:          NavigationStack { HomeView() }
        case .directReports: NavigationStack { DirectReportsView() }
        case .programs:      NavigationStack { ProgramManagerView() }
        case .allDocuments:  NavigationStack { AllDocumentsView() }
        case .settings:      NavigationStack { SettingsView() }
        }
    }
}

// MARK: - All Documents View

struct AllDocumentsView: View {
    @Query(sort: \GeneratedDocument.createdAt, order: .reverse) private var docs: [GeneratedDocument]
    @Environment(\.modelContext) private var ctx
    @State private var filterType: DocumentType? = nil
    @State private var searchText = ""

    private var filtered: [GeneratedDocument] {
        docs.filter { doc in
            let matchesType = filterType == nil || doc.type == filterType
            let matchesSearch = searchText.isEmpty
                || doc.title.localizedCaseInsensitiveContains(searchText)
                || doc.reportName.localizedCaseInsensitiveContains(searchText)
            return matchesType && matchesSearch
        }
    }

    var body: some View {
        Group {
            if docs.isEmpty {
                ContentUnavailableView {
                    Label("No Documents Yet", systemImage: "doc.text")
                } description: {
                    Text("Generate your first document from the Home tab or a direct report's profile.")
                }
            } else {
                List {
                    ForEach(filtered) { doc in
                        DocumentListRow(doc: doc)
                    }
                    .onDelete { offsets in
                        offsets.map { filtered[$0] }.forEach { ctx.delete($0) }
                    }
                }
                .searchable(text: $searchText)
            }
        }
        .navigationTitle("All Documents")
        .toolbar {
            ToolbarItem(placement: .automatic) {
                Menu {
                    Button("All Types") { filterType = nil }
                    Divider()
                    ForEach(DocumentType.allCases, id: \.self) { type in
                        Button(type.rawValue) { filterType = type }
                    }
                } label: {
                    Label(filterType?.rawValue ?? "Filter", systemImage: "line.3.horizontal.decrease.circle")
                }
            }
        }
    }
}

struct DocumentListRow: View {
    let doc: GeneratedDocument
    @State private var showingDetail = false

    var body: some View {
        Button { showingDetail = true } label: {
            HStack(spacing: 12) {
                Image(systemName: doc.type.icon)
                    .foregroundStyle(.indigo)
                    .frame(width: 24)
                VStack(alignment: .leading, spacing: 3) {
                    Text(doc.title).fontWeight(.medium).lineLimit(1)
                    HStack {
                        if !doc.reportName.isEmpty {
                            Text(doc.reportName).foregroundStyle(.secondary)
                        }
                        Text("·")
                        Text(doc.type.rawValue).foregroundStyle(.secondary)
                    }
                    .font(.caption)
                }
                Spacer()
                Text(doc.createdAt.formatted(.relative(presentation: .named)))
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .buttonStyle(.plain)
        .sheet(isPresented: $showingDetail) {
            GeneratedDocumentOutputView(
                content: doc.generatedContent,
                type: doc.type,
                reportName: doc.reportName,
                onSave: { _ in }
            )
        }
    }
}
