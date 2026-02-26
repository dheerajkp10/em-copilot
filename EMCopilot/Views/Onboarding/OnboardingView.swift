import SwiftUI

struct OnboardingView: View {
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding = false
    @State private var step = 0

    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                colors: [Color.indigo.opacity(0.08), Color.purple.opacity(0.04)],
                startPoint: .topLeading, endPoint: .bottomTrailing
            )
            .ignoresSafeArea()

            VStack(spacing: 0) {
                // Step indicator
                HStack(spacing: 8) {
                    ForEach(0..<3) { i in
                        Capsule()
                            .fill(i <= step ? Color.indigo : Color.secondary.opacity(0.3))
                            .frame(width: i == step ? 24 : 8, height: 6)
                            .animation(.spring(response: 0.3), value: step)
                    }
                }
                .padding(.top, 24)
                .padding(.bottom, 32)

                // Step content
                Group {
                    switch step {
                    case 0: WelcomeStep()
                    case 1: APIKeyStep()
                    default: ReadyStep()
                    }
                }
                .frame(maxHeight: .infinity)
                .transition(.asymmetric(
                    insertion: .move(edge: .trailing).combined(with: .opacity),
                    removal:   .move(edge: .leading).combined(with: .opacity)
                ))
                .id(step) // force view rebuild for transition

                Spacer()

                // Navigation buttons
                HStack {
                    if step > 0 {
                        Button("Back") { withAnimation { step -= 1 } }
                            .buttonStyle(.bordered)
                    }
                    Spacer()
                    Button(step == 2 ? "Get Started" : "Continue") {
                        withAnimation {
                            if step < 2 { step += 1 }
                            else { hasCompletedOnboarding = true }
                        }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.indigo)
                    .keyboardShortcut(.return)
                }
                .padding(.horizontal, 32)
                .padding(.bottom, 32)
            }
        }
        #if os(macOS)
        .frame(minWidth: 520, idealWidth: 580, minHeight: 480, idealHeight: 540)
        #endif
    }
}

// MARK: - Step 1: Welcome

private struct WelcomeStep: View {
    var body: some View {
        VStack(spacing: 28) {
            // Icon
            ZStack {
                RoundedRectangle(cornerRadius: 28)
                    .fill(LinearGradient(colors: [.indigo, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 96, height: 96)
                    .shadow(color: .indigo.opacity(0.4), radius: 16, y: 8)
                Image(systemName: "person.text.rectangle.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(.white)
            }

            VStack(spacing: 10) {
                Text("EM Copilot")
                    .font(.largeTitle.bold())
                Text("AI-powered tools for Engineering Managers.\nWrite better reviews, faster.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            // Value props
            VStack(alignment: .leading, spacing: 14) {
                ValuePropRow(icon: "chart.bar.doc.horizontal", color: .blue,
                             title: "Performance Reviews", subtitle: "Calibration-ready narratives in seconds")
                ValuePropRow(icon: "arrow.up.circle", color: .green,
                             title: "Promo Documents", subtitle: "Level-bar mapped, panel-ready")
                ValuePropRow(icon: "person.2", color: .purple,
                             title: "1:1 Summaries", subtitle: "Action items, history, contribution log")
                ValuePropRow(icon: "list.bullet.clipboard", color: .teal,
                             title: "Program Reports", subtitle: "Status, risks, stakeholder emails")
            }
            .padding(20)
            .background(.quaternary.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(.horizontal, 40)
    }
}

private struct ValuePropRow: View {
    let icon: String; let color: Color; let title: String; let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .frame(width: 30)
            VStack(alignment: .leading, spacing: 2) {
                Text(title).fontWeight(.semibold)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
        }
    }
}

// MARK: - Step 2: API Key

private struct APIKeyStep: View {
    @ObservedObject private var claude = ClaudeService.shared
    @State private var keyInput = ""
    @State private var isVisible = false
    @State private var isTesting = false
    @State private var testPassed: Bool? = nil
    @State private var testError = ""

    var body: some View {
        VStack(spacing: 24) {
            VStack(spacing: 8) {
                Image(systemName: "key.fill")
                    .font(.system(size: 48))
                    .foregroundStyle(.indigo)
                Text("Connect Claude")
                    .font(.title.bold())
                Text("EM Copilot uses the Claude API to generate documents.\nYour key is stored locally — never shared.")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 8) {
                Text("Anthropic API Key").font(.headline)

                HStack {
                    Group {
                        if isVisible {
                            TextField("sk-ant-api03-...", text: $keyInput)
                        } else {
                            SecureField("sk-ant-api03-...", text: $keyInput)
                        }
                    }
                    .textFieldStyle(.roundedBorder)
                    .font(.system(.body, design: .monospaced))

                    Button { isVisible.toggle() } label: {
                        Image(systemName: isVisible ? "eye.slash" : "eye")
                    }.buttonStyle(.plain)
                }

                HStack(spacing: 12) {
                    Button("Save & Test") {
                        claude.apiKey = keyInput.trimmingCharacters(in: .whitespaces)
                        Task { await testConnection() }
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.indigo)
                    .disabled(keyInput.trimmingCharacters(in: .whitespaces).isEmpty || isTesting)

                    if isTesting { ProgressView().controlSize(.small) }

                    if let passed = testPassed {
                        Label(passed ? "Connected!" : testError,
                              systemImage: passed ? "checkmark.circle.fill" : "xmark.circle.fill")
                            .foregroundStyle(passed ? .green : .red)
                            .font(.caption)
                    }
                }

                Link("Get a free API key at console.anthropic.com →",
                     destination: URL(string: "https://console.anthropic.com/account/keys")!)
                    .font(.caption)
            }
            .padding(20)
            .background(.quaternary.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 14))

            if claude.apiKey.isEmpty == false && testPassed == nil {
                Label("API key already saved — tap Save & Test to verify.", systemImage: "info.circle")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 40)
        .onAppear { keyInput = claude.apiKey }
    }

    private func testConnection() async {
        isTesting = true; testPassed = nil
        do {
            let r = try await ClaudeService.shared.generate(
                systemPrompt: "Reply with exactly: 'EM Copilot connected.'",
                userMessage: "Ping")
            testPassed = r.contains("connected")
        } catch {
            testPassed = false; testError = error.localizedDescription
        }
        isTesting = false
    }
}

// MARK: - Step 3: Ready

private struct ReadyStep: View {
    var body: some View {
        VStack(spacing: 28) {
            ZStack {
                Circle()
                    .fill(Color.green.opacity(0.12))
                    .frame(width: 100, height: 100)
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundStyle(.green)
            }

            VStack(spacing: 10) {
                Text("You're all set!")
                    .font(.largeTitle.bold())
                Text("Start by adding your direct reports,\nthen generate your first document.")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            VStack(alignment: .leading, spacing: 12) {
                TipRow(number: "1", text: "Add a direct report in the **Direct Reports** tab")
                TipRow(number: "2", text: "Paste your raw notes — the messier the better")
                TipRow(number: "3", text: "Hit **Generate** and get a polished document")
                TipRow(number: "4", text: "Use the **Menu Bar icon** for quick access")
            }
            .padding(20)
            .background(.quaternary.opacity(0.6))
            .clipShape(RoundedRectangle(cornerRadius: 14))
        }
        .padding(.horizontal, 40)
    }
}

private struct TipRow: View {
    let number: String; let text: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Text(number)
                .font(.caption.bold())
                .foregroundStyle(.white)
                .frame(width: 20, height: 20)
                .background(Circle().fill(Color.indigo))
            if let attributed = try? AttributedString(markdown: text) {
                Text(attributed).font(.callout)
            } else {
                Text(text).font(.callout)
            }
        }
    }
}
