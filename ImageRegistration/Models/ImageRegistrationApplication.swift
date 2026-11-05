import Foundation
import CoreGraphics

/// Mirrors the Guernsey IPO "Application to register an image" (form IR).
/// Field numbers in comments match the numbered boxes on the paper form.
struct ImageRegistrationApplication: Codable, Equatable {

    // MARK: Image details
    /// 1. Registration/application no. of personality to which the image(s) will be attached.
    var personalityNumber: String = ""
    /// 2. Name of personality to which image(s) will be attached.
    var personalityName: String = ""
    /// 3. If the image is a series or complex image, please select.
    var isComplexImage: Bool = false
    var isSeriesImage: Bool = false
    /// 4. Number of images to be registered.
    var numberOfImages: Int = 1
    /// 5. Number in series (if series image).
    var numberInSeries: Int = 1

    // MARK: Proprietor details
    /// 6. Full name of proprietor.
    var proprietorName: String = ""
    /// 7. Address of proprietor (including postcode).
    var proprietorAddress: String = ""
    /// 8. If applying in the name of a company, where is it incorporated?
    var companyIncorporation: String = ""

    // MARK: Image rights agent details
    /// 9. Name of agent / agent ref number.
    var agentNameOrReference: String = ""

    // MARK: Declarations
    /// 10. Signature of applicant (stored as pen strokes).
    var signature: [[CGPoint]] = []
    /// 11. Date of signature.
    var signatureDate: Date = .now
    /// 12. Your reference (optional).
    var yourReference: String = ""

    // MARK: Attachments
    /// The image(s) that must be submitted with the form (JPEG data).
    var images: [Data] = []
    /// Number of sheets attached to this form.
    var numberOfSheetsAttached: Int = 0

    // MARK: Completion checklist
    /// "I have completed all of the above".
    var checklistCompleted: Bool = false
}

// MARK: - Validation

extension ImageRegistrationApplication {

    var hasSignature: Bool {
        signature.contains { $0.count > 1 }
    }

    /// Human-readable list of problems that would stop the form being accepted.
    /// An empty array means the application is ready to submit.
    var validationIssues: [String] {
        var issues: [String] = []

        func isBlank(_ value: String) -> Bool {
            value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        }

        if isBlank(personalityNumber) {
            issues.append("1. Enter the registration/application number of the personality.")
        }
        if isBlank(personalityName) {
            issues.append("2. Enter the name of the personality.")
        }
        if numberOfImages < 1 {
            issues.append("4. At least one image must be registered.")
        }
        if isSeriesImage && numberInSeries < 1 {
            issues.append("5. Enter the number in the series.")
        }
        if isBlank(proprietorName) {
            issues.append("6. Enter the full name of the proprietor.")
        }
        if isBlank(proprietorAddress) {
            issues.append("7. Enter the proprietor's address, including postcode.")
        }
        if !hasSignature {
            issues.append("10. The applicant must sign the declaration.")
        }
        if Calendar.current.startOfDay(for: signatureDate) > Calendar.current.startOfDay(for: .now) {
            issues.append("11. The date of signature cannot be in the future.")
        }
        if images.isEmpty {
            issues.append("You must attach the image(s) to be registered.")
        } else if images.count != numberOfImages {
            issues.append("4. Number of images (\(numberOfImages)) does not match the \(images.count) attached.")
        }
        if !checklistCompleted {
            issues.append("Confirm you have completed the checklist.")
        }
        return issues
    }

    var isReadyToSubmit: Bool { validationIssues.isEmpty }
}
