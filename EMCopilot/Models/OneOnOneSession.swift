import Foundation
import SwiftData

// MARK: - Artifact type

enum ArtifactType: String, Codable, CaseIterable {
    case codeReview     = "Code Review"
    case designDoc      = "Design Document"
    case incidentReport = "Incident Report"
    case projectUpdate  = "Project Update"
    case oncall         = "On-Call / Incident"
    case other          = "Other"

    var icon: String {
        switch self {
        case .codeReview:     return "chevron.left.forwardslash.chevron.right"
        case .designDoc:      return "doc.richtext"
        case .incidentReport: return "exclamationmark.triangle"
        case .projectUpdate:  return "chart.line.uptrend.xyaxis"
        case .oncall:         return "bell.badge"
        case .other:          return "link"
        }
    }
}

// MARK: - ContributionArtifact
// A manually linked work artifact (PR, design doc, incident, etc.)
// Will eventually be auto-pulled from GitHub / Confluence / JIRA integrations.

@Model
final class ContributionArtifact {
    var id: UUID
    var title: String
    var artifactType: ArtifactType
    var url: String
    var notes: String
    var artifactDate: Date        // When the work happened
    var createdAt: Date

    var session: OneOnOneSession?
    var report: DirectReport?    // denormalized for quick queries

    init(
        title: String,
        artifactType: ArtifactType = .codeReview,
        url: String = "",
        notes: String = "",
        artifactDate: Date = Date()
    ) {
        self.id = UUID()
        self.title = title
        self.artifactType = artifactType
        self.url = url
        self.notes = notes
        self.artifactDate = artifactDate
        self.createdAt = Date()
    }
}

// MARK: - ActionItem
// A tracked to-do that came out of a 1:1 session.

@Model
final class ActionItem {
    var id: UUID
    var title: String
    var owner: String           // "Manager" | engineer's name
    var dueDate: Date?
    var isCompleted: Bool
    var createdAt: Date
    var completedAt: Date?

    var session: OneOnOneSession?
    var report: DirectReport?   // denormalized

    init(title: String, owner: String = "", dueDate: Date? = nil) {
        self.id = UUID()
        self.title = title
        self.owner = owner
        self.dueDate = dueDate
        self.isCompleted = false
        self.createdAt = Date()
    }

    var isOverdue: Bool {
        guard let due = dueDate, !isCompleted else { return false }
        return due < Date()
    }
}

// MARK: - OneOnOneSession
// One meeting occurrence — notes, generated summary, action items, artifacts.

@Model
final class OneOnOneSession {
    var id: UUID
    var date: Date
    var rawNotes: String            // What the manager typed/pasted
    var generatedSummary: String    // AI output
    var createdAt: Date

    var report: DirectReport?

    @Relationship(deleteRule: .cascade)
    var actionItems: [ActionItem] = []

    @Relationship(deleteRule: .cascade)
    var artifacts: [ContributionArtifact] = []

    init(date: Date = Date(), rawNotes: String = "") {
        self.id = UUID()
        self.date = date
        self.rawNotes = rawNotes
        self.generatedSummary = ""
        self.createdAt = Date()
    }

    var openActionItems: [ActionItem] {
        actionItems.filter { !$0.isCompleted }
    }

    var completedActionItems: [ActionItem] {
        actionItems.filter { $0.isCompleted }
    }
}
