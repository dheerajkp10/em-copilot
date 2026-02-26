import Foundation
import SwiftData

@Model
final class DirectReport {
    var id: UUID
    var name: String
    var role: String
    var level: String          // e.g. "SDE2", "L5", "Senior Engineer"
    var team: String
    var startDate: Date
    var notes: String          // Ongoing manager notes/observations
    var createdAt: Date
    var updatedAt: Date

    @Relationship(deleteRule: .cascade)
    var documents: [GeneratedDocument] = []

    init(
        name: String,
        role: String = "",
        level: String = "",
        team: String = "",
        startDate: Date = Date(),
        notes: String = ""
    ) {
        self.id = UUID()
        self.name = name
        self.role = role
        self.level = level
        self.team = team
        self.startDate = startDate
        self.notes = notes
        self.createdAt = Date()
        self.updatedAt = Date()
    }

    var initials: String {
        name.split(separator: " ")
            .prefix(2)
            .compactMap { $0.first.map(String.init) }
            .joined()
            .uppercased()
    }

    var displayLevel: String {
        level.isEmpty ? role : "\(role) · \(level)"
    }
}
