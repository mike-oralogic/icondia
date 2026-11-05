import SwiftUI
import MessageUI

/// Wraps `MFMailComposeViewController` so the completed PDF can be emailed
/// straight to the Intellectual Property Office.
struct MailComposer: UIViewControllerRepresentable {
    static let ipoEmail = "ipo@guernseyregistry.com"

    let subject: String
    let body: String
    let attachmentURL: URL
    @Environment(\.dismiss) private var dismiss

    static var canSendMail: Bool { MFMailComposeViewController.canSendMail() }

    func makeUIViewController(context: Context) -> MFMailComposeViewController {
        let controller = MFMailComposeViewController()
        controller.mailComposeDelegate = context.coordinator
        controller.setToRecipients([Self.ipoEmail])
        controller.setSubject(subject)
        controller.setMessageBody(body, isHTML: false)
        if let data = try? Data(contentsOf: attachmentURL) {
            controller.addAttachmentData(data, mimeType: "application/pdf",
                                         fileName: attachmentURL.lastPathComponent)
        }
        return controller
    }

    func updateUIViewController(_ uiViewController: MFMailComposeViewController, context: Context) {}

    func makeCoordinator() -> Coordinator { Coordinator(dismiss: dismiss) }

    final class Coordinator: NSObject, MFMailComposeViewControllerDelegate {
        let dismiss: DismissAction
        init(dismiss: DismissAction) { self.dismiss = dismiss }

        func mailComposeController(_ controller: MFMailComposeViewController,
                                   didFinishWith result: MFMailComposeResult, error: Error?) {
            dismiss()
        }
    }
}
