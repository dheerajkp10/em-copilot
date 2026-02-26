import Foundation
import SwiftData

enum ProgramStatus: String, Codable, CaseIterable {
    case onTrack    = "On Track"
    case atRisk     = "At Risk"
    case offTrack   = "Off Track"
    case blocked    = "Blocked"
    case completed  = "Completed"
    case onHold     = "On Hold"

    var icon: String {
        switch self {
        case .onTrack:   return "checkmark.circle.fill"
        case .atRisk:    return "exclamationmark.circle.fill"
        case .offTrack:  return "xmark.circle.fill"
        case .blocked:   return "nosign"
        case .completed: return "checkmark.seal.fill"
        case .onHold:    return "pause.circle.fill"
        }
    }

    var colorName: String {
        switch self {
        case .onTrack:   return "green"
        case .atRisk:    return "yellow"
        case .offTrack:  return "red"
        case .blocked:   return "red"
        case .completed: return "blue"
        case .onHold:    return "gray"
        }
    }
}

enum RiskSeverity: String, Codable, CaseIterable {
    case critical = "Critical"
    case high     = "High"
    case medium   = "Medium"
    case low      = "Low"
}

@Model
final class ProgramRisk {
    var id: UUID
    var title: String
    var details: String
    var severity: RiskSeverity
    var mitigation: String
    var owner: String
    var createdAt: Date

    var program: Program?

    init(title: String, details: String = "", severity: RiskSeverity = .medium, mitigation: String = "", owner: String = "") {
        self.id = UUID()
        self.title = title
        self.details = details
        self.severity = severity
        self.mitigation = mitigation
        self.owner = owner
        self.createdAt = Date()
    }
}

@Model
final class ProgramUpdate {
    var id: UUID
    var summary: String
    var generatedReport: String
    var createdAt: Date

    var program: Program?

    init(summary: String, generatedReport: String = "") {
        self.id = UUID()
        self.summary = summary
        self.generatedReport = generatedReport
        self.createdAt = Date()
    }
}

@Model
final class Program {
    var id: UUID
    var name: String
    var objective: String
    var status: ProgramStatus
    var owner: String
    var targetDate: Date?
    var stakeholders: String       // comma-separated or free text
    var notes: String
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade)
    var risks: [ProgramRisk] = []

    @Relationship(deleteRule: .cascade)
    var updates: [ProgramUpdate] = []

    init(
        name: String,
        objective: String = "",
        status: ProgramStatus = .onTrack,
        owner: String = "",
        targetDate: Date? = nil,
        stakeholders: String = "",
        notes: String = ""
    ) {
        self.id = UUID()
        self.name = name
        self.objective = objective
        self.status = status
        self.owner = owner
        self.targetDate = targetDate
        self.stakeholders = stakeholders
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var criticalRisks: [ProgramRisk] {
        risks.filter { $0.severity == .critical || $0.severity == .high }
    }
}
