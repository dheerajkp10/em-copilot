import SwiftUI

/// Renders Claude-generated markdown with proper block-level formatting.
/// Handles: ## headers, **bold**, *italic*, - bullets, [ ] checkboxes, --- dividers, ```code```
struct MarkdownContentView: View {
    let markdown: String

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ForEach(Array(parsed.enumerated()), id: \.offset) { _, block in
                blockView(block)
                    .padding(.bottom, spacing(for: block))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Block model

    private enum Block {
        case h1(String)
        case h2(String)
        case h3(String)
        case paragraph(String)
        case bullet(String, indent: Int)
        case checkbox(String, checked: Bool)
        case divider
        case codeBlock(String)
        case blank
    }

    private func spacing(for block: Block) -> CGFloat {
        switch block {
        case .h1:        return 14
        case .h2:        return 12
        case .h3:        return 8
        case .divider:   return 16
        case .blank:     return 2
        default:         return 7
        }
    }

    // MARK: - Parsing

    private var parsed: [Block] {
        var result: [Block] = []
        var inCode = false
        var codeLines: [String] = []

        for line in markdown.components(separatedBy: "\n") {
            // Code fence toggle
            if line.hasPrefix("```") {
                if inCode {
                    result.append(.codeBlock(codeLines.joined(separator: "\n")))
                    codeLines = []
                    inCode = false
                } else {
                    inCode = true
                }
                continue
            }
            if inCode { codeLines.append(line); continue }

            let trimmed = line.trimmingCharacters(in: .whitespaces)

            if trimmed.isEmpty {
                // Deduplicate consecutive blanks
                if case .blank = result.last { } else { result.append(.blank) }
            } else if trimmed.hasPrefix("# ")   { result.append(.h1(String(trimmed.dropFirst(2)))) }
            else if trimmed.hasPrefix("## ")    { result.append(.h2(String(trimmed.dropFirst(3)))) }
            else if trimmed.hasPrefix("### ")   { result.append(.h3(String(trimmed.dropFirst(4)))) }
            else if trimmed == "---" || trimmed == "***" || trimmed == "___" {
                result.append(.divider)
            } else if trimmed.hasPrefix("- [ ] ") || trimmed.hasPrefix("* [ ] ") {
                result.append(.checkbox(String(trimmed.dropFirst(6)), checked: false))
            } else if trimmed.lowercased().hasPrefix("- [x] ") || trimmed.lowercased().hasPrefix("* [x] ") {
                result.append(.checkbox(String(trimmed.dropFirst(6)), checked: true))
            } else if trimmed.hasPrefix("- ") || trimmed.hasPrefix("* ") {
                let indent = line.prefix(while: { $0 == " " }).count / 2
                result.append(.bullet(String(trimmed.dropFirst(2)), indent: indent))
            } else {
                result.append(.paragraph(trimmed))
            }
        }
        return result
    }

    // MARK: - Rendering

    @ViewBuilder
    private func blockView(_ block: Block) -> some View {
        switch block {

        case .h1(let text):
            inline(text)
                .font(.title2.bold())
                .foregroundStyle(.primary)

        case .h2(let text):
            VStack(alignment: .leading, spacing: 4) {
                inline(text)
                    .font(.headline)
                    .foregroundStyle(.primary)
                Rectangle()
                    .fill(Color.accentColor.opacity(0.3))
                    .frame(height: 1.5)
            }
            .padding(.top, 10)

        case .h3(let text):
            inline(text)
                .font(.subheadline.bold())
                .foregroundStyle(.secondary)

        case .paragraph(let text):
            inline(text)
                .font(.body)
                .foregroundStyle(.primary)

        case .bullet(let text, let indent):
            HStack(alignment: .top, spacing: 8) {
                Text(indent > 0 ? "◦" : "•")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .frame(width: 10)
                inline(text)
                    .font(.body)
                    .foregroundStyle(.primary)
            }
            .padding(.leading, CGFloat(indent) * 18)

        case .checkbox(let text, let checked):
            HStack(alignment: .top, spacing: 8) {
                Image(systemName: checked ? "checkmark.square.fill" : "square")
                    .foregroundStyle(checked ? Color.green : Color.secondary)
                    .font(.body)
                inline(text)
                    .font(.body)
                    .foregroundStyle(checked ? .secondary : .primary)
                    .strikethrough(checked, color: .secondary)
            }

        case .divider:
            Divider()

        case .codeBlock(let code):
            Text(code)
                .font(.system(.footnote, design: .monospaced))
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.secondary.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 6))
                .overlay(RoundedRectangle(cornerRadius: 6).stroke(Color.secondary.opacity(0.2), lineWidth: 1))

        case .blank:
            EmptyView()
        }
    }

    /// Renders inline markdown (bold, italic, code, links) via AttributedString
    private func inline(_ text: String) -> Text {
        if let attributed = try? AttributedString(
            markdown: text,
            options: .init(interpretedSyntax: .inlinesOnly)
        ) {
            return Text(attributed)
        }
        return Text(text)
    }
}

// MARK: - Preview helper

extension MarkdownContentView {
    static let sampleReview = """
    ## Performance Summary

    Alex delivered strong results this half, consistently operating **above bar** at the Senior Engineer level.

    ## Key Strengths

    - **Technical Leadership**: Drove the migration of the payments service to async processing, reducing p99 latency by 40%.
    - **Delivery**: Shipped all committed features on time with zero production incidents.
    - **Mentorship**: Onboarded 2 new engineers and reviewed 80+ PRs this half.

    ## Areas for Growth

    - Stakeholder communication could be more proactive — tends to surface blockers late.

    ---

    ## Calibration Justification

    Alex is operating *above bar* for Senior Engineer in technical scope and delivery. Recommend **Exceeds Expectations**.
    """
}
