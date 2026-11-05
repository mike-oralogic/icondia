import UIKit
import SwiftUI

/// Produces a PDF that follows the layout and numbering of the paper IR form,
/// followed by one page per attached image. The PDF can then be emailed to the
/// Intellectual Property Office or shared via the system share sheet.
struct ApplicationPDFRenderer {

    let application: ImageRegistrationApplication

    private let pageRect = CGRect(x: 0, y: 0, width: 595.2, height: 841.8) // A4 in points
    private let margin: CGFloat = 48
    private let labelWidth: CGFloat = 190

    private let brandColor = UIColor(red: 0.0, green: 0.29, blue: 0.40, alpha: 1)

    func render() throws -> URL {
        let renderer = UIGraphicsPDFRenderer(bounds: pageRect, format: Self.format())
        let data = renderer.pdfData { context in
            var cursor = PageCursor(context: context, pageRect: pageRect, margin: margin)
            cursor.newPage()
            drawForm(cursor: &cursor)
            drawImages(context: context)
        }

        let safeName = application.personalityName
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { !$0.isEmpty }
            .joined(separator: "-")
        let fileName = "Image-Registration\(safeName.isEmpty ? "" : "-\(safeName)").pdf"
        let url = URL.temporaryDirectory.appending(path: fileName)
        try data.write(to: url, options: .atomic)
        return url
    }

    private static func format() -> UIGraphicsPDFRendererFormat {
        let format = UIGraphicsPDFRendererFormat()
        format.documentInfo = [
            kCGPDFContextTitle as String: "Application to register an image",
            kCGPDFContextCreator as String: "Image Registration iOS app",
        ]
        return format
    }

    // MARK: - Form pages

    private func drawForm(cursor: inout PageCursor) {
        let app = application

        cursor.drawText("Application to register an image",
                        font: .boldSystemFont(ofSize: 20), color: brandColor)
        cursor.drawText("Intellectual Property Office, Bailiwick of Guernsey",
                        font: .systemFont(ofSize: 11), color: .darkGray)
        cursor.space(16)

        cursor.drawSectionHeading("Image details", color: brandColor)
        drawRow(&cursor, "1. Registration/application no. of personality", app.personalityNumber)
        drawRow(&cursor, "2. Name of personality", app.personalityName)
        drawRow(&cursor, "3. Complex image", app.isComplexImage ? "Yes" : "No")
        drawRow(&cursor, "    Series image", app.isSeriesImage ? "Yes" : "No")
        drawRow(&cursor, "4. Number of images to be registered", "\(app.numberOfImages)")
        drawRow(&cursor, "5. Number in series (if series image)",
                app.isSeriesImage ? "\(app.numberInSeries)" : "N/A")

        cursor.drawSectionHeading("Proprietor details", color: brandColor)
        drawRow(&cursor, "6. Full name of proprietor", app.proprietorName)
        drawRow(&cursor, "7. Address of proprietor (including postcode)", app.proprietorAddress)
        drawRow(&cursor, "8. If a company, where incorporated", app.companyIncorporation)

        cursor.drawSectionHeading("Image rights agent details", color: brandColor)
        drawRow(&cursor, "9. Name of agent / agent ref number", app.agentNameOrReference)

        cursor.drawSectionHeading("Declarations", color: brandColor)
        cursor.drawText(Declarations.intro, font: .systemFont(ofSize: 10))
        for item in Declarations.items {
            cursor.drawText("•  " + item, font: .systemFont(ofSize: 10), indent: 10)
        }
        cursor.space(8)

        cursor.ensureSpace(90)
        cursor.drawLabel("10. Signature of applicant", width: labelWidth)
        let signatureRect = CGRect(x: margin + labelWidth, y: cursor.y,
                                   width: pageRect.width - margin * 2 - labelWidth, height: 70)
        UIColor.lightGray.setStroke()
        UIBezierPath(rect: signatureRect).stroke()
        if app.hasSignature {
            let path = UIBezierPath(cgPath: SignatureShape(strokes: app.signature, fitToRect: true)
                .path(in: signatureRect.insetBy(dx: 8, dy: 8)).cgPath)
            path.lineWidth = 1.5
            path.lineCapStyle = .round
            path.lineJoinStyle = .round
            UIColor.black.setStroke()
            path.stroke()
        }
        cursor.y = signatureRect.maxY + 8

        drawRow(&cursor, "11. Date of signature",
                app.signatureDate.formatted(date: .long, time: .omitted))
        drawRow(&cursor, "12. Your reference (optional)", app.yourReference)
        drawRow(&cursor, "Images submitted with this form", "\(app.images.count)")
        drawRow(&cursor, "Number of sheets attached to this form", "\(app.numberOfSheetsAttached)")

        cursor.drawSectionHeading("Completion checklist", color: brandColor)
        drawRow(&cursor, "I have completed all of the above", app.checklistCompleted ? "Yes" : "No")
    }

    private func drawRow(_ cursor: inout PageCursor, _ label: String, _ value: String) {
        let display = value.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? "—" : value
        cursor.drawLabelValue(label: label, value: display, labelWidth: labelWidth)
    }

    // MARK: - Image pages

    private func drawImages(context: UIGraphicsPDFRendererContext) {
        for (index, data) in application.images.enumerated() {
            guard let image = UIImage(data: data) else { continue }
            context.beginPage()

            let title = "Image \(index + 1) of \(application.images.count) — \(application.personalityName)"
            (title as NSString).draw(
                at: CGPoint(x: margin, y: margin),
                withAttributes: [.font: UIFont.boldSystemFont(ofSize: 14), .foregroundColor: brandColor]
            )

            let available = CGRect(x: margin, y: margin + 30,
                                   width: pageRect.width - margin * 2,
                                   height: pageRect.height - margin * 2 - 30)
            let scale = min(available.width / image.size.width, available.height / image.size.height, 1)
            let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
            let origin = CGPoint(x: available.midX - size.width / 2, y: available.minY)
            image.draw(in: CGRect(origin: origin, size: size))
        }
    }
}

// MARK: - Shared declaration wording

enum Declarations {
    static let intro = "By signing section 10 below, you declare that you have correctly presented the information contained in this form to the Registrar and that you have read and complied with the following:"

    static let items = [
        "The registration of the image(s) is not prohibited by section 8 (existing rights) of the Image Rights (Bailiwick of Guernsey) Ordinance, 2012.",
        "This application has been made with the consent of either the personnage, the personal representative of the personnage, the proprietor (or prospective proprietor), or their representative, or any person authorised by any of the aforementioned persons, according to section 11 of the Image Rights (Bailiwick of Guernsey) Ordinance, 2012.",
    ]

    static let checklist = [
        "Make sure you have read and complied with the declarations above.",
        "Make sure you have completed all required questions.",
        "Enclose payment, or state a High Volume Client Account for the filing fee to be charged to — see the fee schedule at www.guernseyregistry.com/ipo.",
        "Ensure the form is signed and dated by an authorised signatory.",
        "Send it to the Intellectual Property Office.",
    ]
}

// MARK: - Simple flowing-text layout

private struct PageCursor {
    let context: UIGraphicsPDFRendererContext
    let pageRect: CGRect
    let margin: CGFloat
    var y: CGFloat = 0

    private var contentWidth: CGFloat { pageRect.width - margin * 2 }
    private var bottom: CGFloat { pageRect.height - margin }

    mutating func newPage() {
        context.beginPage()
        y = margin
    }

    mutating func ensureSpace(_ height: CGFloat) {
        if y + height > bottom { newPage() }
    }

    mutating func space(_ height: CGFloat) {
        y += height
    }

    mutating func drawText(_ text: String, font: UIFont, color: UIColor = .black, indent: CGFloat = 0) {
        let attributes = Self.attributes(font: font, color: color)
        let width = contentWidth - indent
        let height = Self.height(of: text, width: width, attributes: attributes)
        ensureSpace(height)
        (text as NSString).draw(
            with: CGRect(x: margin + indent, y: y, width: width, height: height),
            options: .usesLineFragmentOrigin, attributes: attributes, context: nil
        )
        y += height + 4
    }

    mutating func drawSectionHeading(_ text: String, color: UIColor) {
        space(10)
        ensureSpace(40)
        drawText(text, font: .boldSystemFont(ofSize: 14), color: color)
        color.withAlphaComponent(0.4).setStroke()
        let line = UIBezierPath()
        line.move(to: CGPoint(x: margin, y: y))
        line.addLine(to: CGPoint(x: pageRect.width - margin, y: y))
        line.lineWidth = 0.5
        line.stroke()
        y += 6
    }

    mutating func drawLabel(_ text: String, width: CGFloat) {
        let attributes = Self.attributes(font: .systemFont(ofSize: 10), color: .darkGray)
        let height = Self.height(of: text, width: width - 10, attributes: attributes)
        (text as NSString).draw(
            with: CGRect(x: margin, y: y, width: width - 10, height: height),
            options: .usesLineFragmentOrigin, attributes: attributes, context: nil
        )
    }

    mutating func drawLabelValue(label: String, value: String, labelWidth: CGFloat) {
        let labelAttributes = Self.attributes(font: .systemFont(ofSize: 10), color: .darkGray)
        let valueAttributes = Self.attributes(font: .systemFont(ofSize: 11), color: .black)
        let valueWidth = contentWidth - labelWidth
        let labelHeight = Self.height(of: label, width: labelWidth - 10, attributes: labelAttributes)
        let valueHeight = Self.height(of: value, width: valueWidth, attributes: valueAttributes)
        let rowHeight = max(labelHeight, valueHeight)
        ensureSpace(rowHeight)
        (label as NSString).draw(
            with: CGRect(x: margin, y: y, width: labelWidth - 10, height: labelHeight),
            options: .usesLineFragmentOrigin, attributes: labelAttributes, context: nil
        )
        (value as NSString).draw(
            with: CGRect(x: margin + labelWidth, y: y, width: valueWidth, height: valueHeight),
            options: .usesLineFragmentOrigin, attributes: valueAttributes, context: nil
        )
        y += rowHeight + 8
    }

    private static func attributes(font: UIFont, color: UIColor) -> [NSAttributedString.Key: Any] {
        let paragraph = NSMutableParagraphStyle()
        paragraph.lineBreakMode = .byWordWrapping
        return [.font: font, .foregroundColor: color, .paragraphStyle: paragraph]
    }

    private static func height(of text: String, width: CGFloat,
                               attributes: [NSAttributedString.Key: Any]) -> CGFloat {
        ceil((text as NSString).boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin, attributes: attributes, context: nil
        ).height)
    }
}
