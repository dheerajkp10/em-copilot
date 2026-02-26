import SwiftUI

struct SettingsView: View {
    @ObservedObject private var claude = ClaudeService.shared
    @State private var apiKeyInput: String = ""
    @State private var isKeyVisible = false
    @State private var isTesting = false
    @State private var testResult: TestResult? = nil

    enum TestResult {
        case success
        case failure(String)
    }

    var body: some View {
        Form {
            Section {
                VStack(alignment: .leading, spacing: 12) {
                    Label("Anthropic API Key", systemImage: "key.fill")
                        .font(.headline)

                    Text("EM Copilot uses the Claude API to generate all documents. Your key is stored locally on your device and never sent anywhere except Anthropic's servers.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack {
                        if isKeyVisible {
                            TextField("sk-ant-...", text: $apiKeyInput)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(.body, design: .monospaced))
                        } else {
                            SecureField("sk-ant-...", text: $apiKeyInput)
                                .textFieldStyle(.roundedBorder)
                                .font(.system(.body, design: .monospaced))
                        }

                        Button {
                            isKeyVisible.toggle()
                        } label: {
                            Image(systemName: isKeyVisible ? "eye.slash" : "eye")
                        }
                        .buttonStyle(.plain)
                    }

                    HStack(spacing: 12) {
                        Button("Save Key") {
                            claude.apiKey = apiKeyInput.trimmingCharacters(in: .whitespaces)
                            testResult = nil
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(apiKeyInput.trimmingCharacters(in: .whitespaces).isEmpty)

                        Button("Test Connection") {
                            Task { await testConnection() }
                        }
                        .buttonStyle(.bordered)
                        .disabled(isTesting || claude.apiKey.isEmpty)

                        if isTesting {
                            ProgressView().controlSize(.small)
                        }
                    }

                    if let result = testResult {
                        switch result {
                        case .success:
                            Label("Connected successfully", systemImage: "checkmark.circle.fill")
                                .foregroundStyle(.green)
                                .font(.caption)
                        case .failure(let message):
                            Label(message, systemImage: "xmark.circle.fill")
                                .foregroundStyle(.red)
                                .font(.caption)
                        }
                    }

                    Link("Get an API key at console.anthropic.com →",
                         destination: URL(string: "https://console.anthropic.com/account/keys")!)
                        .font(.caption)
                }
                .padding(.vertical, 4)
            } header: {
                Text("API Configuration")
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Model", systemImage: "cpu")
                        .font(.headline)
                    Text("claude-opus-4-6")
                        .font(.system(.body, design: .monospaced))
                        .foregroundStyle(.secondary)
                    Text("Using the most capable Claude model for best-quality EM documents.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            } header: {
                Text("Model")
            }

            Section {
                VStack(alignment: .leading, spacing: 8) {
                    Label("Privacy", systemImage: "lock.shield")
                        .font(.headline)
                    Text("Your notes and generated documents are stored locally on your device using SwiftData. They are not synced to any cloud service. API calls are made directly to Anthropic — no third-party servers involved.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 4)
            } header: {
                Text("Privacy & Data")
            }
        }
        .formStyle(.grouped)
        .navigationTitle("Settings")
        .onAppear {
            apiKeyInput = claude.apiKey
        }
    }

    private func testConnection() async {
        isTesting = true
        testResult = nil
        do {
            let response = try await claude.generate(
                systemPrompt: "You are a helpful assistant. Reply with exactly: 'EM Copilot is connected.'",
                userMessage: "Ping."
            )
            testResult = response.contains("connected") ? .success : .failure("Unexpected response: \(response)")
        } catch {
            testResult = .failure(error.localizedDescription)
        }
        isTesting = false
    }
}
