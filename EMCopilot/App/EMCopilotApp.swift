import SwiftUI
import SwiftData

@main
struct EMCopilotApp: App {
    let container: ModelContainer

    init() {
        do {
            let schema = Schema([
                DirectReport.self,
                GeneratedDocument.self,
                Program.self,
                ProgramRisk.self,
                ProgramUpdate.self
            ])
            let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
            container = try ModelContainer(for: schema, configurations: config)
        } catch {
            fatalError("Failed to create SwiftData container: \(error)")
        }
    }

    // body only adds whole Scene elements — no modifier chains inside #if.
    // macOS-specific modifiers live in mainWindowScene below.
    var body: some Scene {
        mainWindowScene
        #if os(macOS)
        MenuBarExtra {
            MenuBarContentView()
                .modelContainer(container)
        } label: {
            Label("EM Copilot", systemImage: "person.text.rectangle.fill")
        }
        .menuBarExtraStyle(.window)
        #endif
    }

    // Separate computed property so each platform resolves `some Scene` unambiguously.
    #if os(macOS)
    private var mainWindowScene: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
        }
        .defaultSize(width: 1100, height: 750)
        .commands {
            CommandGroup(replacing: .newItem) {
                Button("New Document…") {}
                    .keyboardShortcut("n", modifiers: .command)
            }
        }
    }
    #else
    private var mainWindowScene: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
        }
    }
    #endif
}

// MARK: - macOS Menu Bar Quick Access

#if os(macOS)
struct MenuBarContentView: View {
    @State private var showingGenerator = false
    @State private var quickType: DocumentType = .perfReview

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Header
            HStack {
                Image(systemName: "person.text.rectangle.fill")
                    .foregroundStyle(.indigo)
                Text("EM Copilot")
                    .fontWeight(.semibold)
                Spacer()
            }
            .padding(12)
            .background(.quaternary)

            Divider()

            // Quick generate buttons
            VStack(alignment: .leading, spacing: 2) {
                Text("Quick Generate")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.top, 8)

                ForEach([DocumentType.perfReview, .promoDoc, .oneOnOne, .pip], id: \.self) { type in
                    Button {
                        quickType = type
                        showingGenerator = true
                    } label: {
                        Label(type.rawValue, systemImage: type.icon)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .buttonStyle(.plain)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .contentShape(Rectangle())
                    .hoverEffect()
                }
            }
            .padding(.bottom, 6)

            Divider()

            VStack(alignment: .leading, spacing: 2) {
                Text("Programs")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.top, 8)

                Button {
                    quickType = .programStatus
                    showingGenerator = true
                } label: {
                    Label("Program Status Report", systemImage: DocumentType.programStatus.icon)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .contentShape(Rectangle())
                .hoverEffect()

                Button {
                    quickType = .stakeholderEmail
                    showingGenerator = true
                } label: {
                    Label("Stakeholder Email", systemImage: DocumentType.stakeholderEmail.icon)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .contentShape(Rectangle())
                .hoverEffect()
            }
            .padding(.bottom, 6)

            Divider()

            // Open main app
            Button {
                NSApp.activate(ignoringOtherApps: true)
                for window in NSApp.windows where window.title == "EM Copilot" {
                    window.makeKeyAndOrderFront(nil)
                }
            } label: {
                Label("Open EM Copilot", systemImage: "arrow.up.forward.app")
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            .buttonStyle(.plain)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
        }
        .frame(width: 280)
        .sheet(isPresented: $showingGenerator) {
            DocumentGeneratorView(preselectedType: quickType)
                .frame(minWidth: 500, minHeight: 600)
        }
    }
}

// Simple hover effect for menu bar items
extension View {
    func hoverEffect() -> some View {
        self.modifier(HoverHighlightModifier())
    }
}

struct HoverHighlightModifier: ViewModifier {
    @State private var isHovered = false

    func body(content: Content) -> some View {
        content
            .background(isHovered ? Color.accentColor.opacity(0.1) : Color.clear)
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .onHover { isHovered = $0 }
    }
}
#endif
