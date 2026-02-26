import Foundation
import SwiftData

enum DocumentType: String, Codable, CaseIterable {
    case perfReview      = "Performance Review"
    case promoDoc        = "Promotion Document"
    case oneOnOne        = "1:1 Summary"
    case pip             = "PIP / Development Plan"
    case programStatus   = "Program Status Report"
    case stakeholderEmail = "Stakeholder Email"
    case riskReport      = "Risk Report"

    var icon: String {
        switch self {
        case .perfReview:       return "chart.bar.doc.horizontal"
        case .promoDoc:         return "arrow.up.circle"
        case .oneOnOne:         return "person.2"
        case .pip:              return "exclamationmark.triangle"
        case .programStatus:    return "list.bullet.clipboard"
        case .stakeholderEmail: return "envelope"
        case .riskReport:       return "shield.lefthalf.filled"
        }
    }

    var color: String {
        switch self {
        case .perfReview:       return "blue"
        case .promoDoc:         return "green"
        case .oneOnOne:         return "purple"
        case .pip:              return "orange"
        case .programStatus:    return "teal"
        case .stakeholderEmail: return "indigo"
        case .riskReport:       return "red"
        }
    }
}

enum ReviewPeriod: String, Codable, CaseIterable {
    case annual     = "Annual"
    case midYear    = "Mid-Year"
    case quarterly  = "Q1"; case q2 = "Q2"; case q3 = "Q3"; case q4 = "Q4"
    case custom     = "Custom"
}

enum PerformanceRating: String, Codable, CaseIterable {
    case exceptional    = "Exceptional / Outstanding"
    case exceedsAll     = "Exceeds All Expectations"
    case exceeds        = "Exceeds Expectations"
    case meetsAll       = "Meets All Expectations"
    case meets          = "Meets Most Expectations"
    case belowMeets     = "Below Expectations"
    case doesNotMeet    = "Does Not Meet Expectations"
}

@Model
final class GeneratedDocument {
    var id: UUID
    var type: DocumentType
    var title: String
    var inputNotes: String          // Raw notes the EM pasted in
    var generatedContent: String    // Output from Claude
    var rating: PerformanceRating?  // For perf reviews
    var period: ReviewPeriod?       // For perf reviews
    var createdAt: Date
    var isFavorited: Bool
    var reportName: String          // Denormalized for quick display

    var report: DirectReport?

    init(
        type: DocumentType,
        title: String = "",
        inputNotes: String,
        generatedContent: String = "",
        rating: PerformanceRating? = nil,
        period: ReviewPeriod? = nil,
        report: DirectReport? = nil,
        reportName: String = ""
    ) {
        self.id = UUID()
        self.type = type
        self.title = title.isEmpty ? "\(type.rawValue) – \(Date().formatted(date: .abbreviated, time: .omitted))" : title
        self.inputNotes = inputNotes
        self.generatedContent = generatedContent
        self.rating = rating
        self.period = period
        self.report = report
        self.reportName = reportName.isEmpty ? (report?.name ?? "") : reportName
        self.createdAt = Date()
        self.isFavorited = false
    }
}
